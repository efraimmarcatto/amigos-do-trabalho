extends Control

## Main scene controller for the desktop pet.
## Manages transparent window with click-through on empty areas
## and captures clicks on the pet sprite and interaction menu.
## Handles save/load of pet state and coins to user://save_data.json.

const SAVE_PATH := "user://save_data.json"
const FURNITURE_SCENE := preload("res://scenes/furniture.tscn")

@onready var pet_sprite: Sprite2D = $PetSprite
@onready var coin_system: Node = $CoinSystem
@onready var coin_label: Label = $CoinLabel
@onready var interaction_menu: PanelContainer = $InteractionMenu
@onready var slide_menu: Control = $SlideMenu
@onready var shop_panel: PanelContainer = $ShopPanel

# Spawned furniture instances keyed by furniture_id
var _furniture_nodes: Dictionary = {}
# Saved positions keyed by furniture_id (as {x, y} dicts)
var _furniture_positions: Dictionary = {}
# Floor Y coordinate — top of taskbar (bottom of usable screen rect)
var floor_y: float = 0.0

func _ready() -> void:
	# Make the viewport background transparent
	get_viewport().transparent_bg = true

	# Set window to cover entire primary monitor
	var screen_size := DisplayServer.screen_get_size()
	var win := get_window()
	win.position = Vector2i.ZERO
	win.size = screen_size

	# Compute floor Y from usable screen rect (excludes taskbar)
	floor_y = _compute_floor_y()

	# Start global input hooks for keyboard/mouse tracking
	GlobalInput.start_hooks()

	# Update the mouse passthrough so transparent areas pass clicks through
	_update_passthrough()

	# Connect coin system to update the label
	coin_system.coins_changed.connect(_on_coins_changed)

	# Set up slide menu and connect signals
	slide_menu.setup(floor_y)
	slide_menu.shop_requested.connect(_on_shop_button_pressed)
	shop_panel.furniture_purchased.connect(_on_furniture_purchased)

	# Share furniture nodes dict and floor_y with pet
	pet_sprite._furniture_nodes = _furniture_nodes
	pet_sprite.floor_y = floor_y

	# Position pet at floor level
	var pet_half_h := (pet_sprite.texture.get_size().y * pet_sprite.scale.abs().y) / 2.0
	pet_sprite.position.y = floor_y - pet_half_h

	# Position coin label just above the floor
	coin_label.offset_top = floor_y + 2.0
	coin_label.offset_bottom = floor_y + 22.0

	# Load saved state (also spawns furniture)
	_load_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobalInput.stop_hooks()
		_save_state()
		get_tree().quit()


func _save_state() -> void:
	# Update positions from live nodes before saving
	for fid in _furniture_nodes:
		var node: Furniture = _furniture_nodes[fid]
		_furniture_positions[fid] = {"x": node.global_position.x, "y": node.global_position.y}

	var data := {
		"coins": coin_system.get_coins(),
		"pet_mood": pet_sprite._current_mood,
		"owned_furniture": shop_panel.get_owned(),
		"furniture_positions": _furniture_positions,
	}
	var json_string := JSON.stringify(data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)


func _load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return
	var data = json.data
	if not data is Dictionary:
		return
	if data.has("coins") and data["coins"] is float:
		coin_system.set_coins(int(data["coins"]))
	elif data.has("coins") and data["coins"] is int:
		coin_system.set_coins(data["coins"])
	if data.has("furniture_positions") and data["furniture_positions"] is Dictionary:
		for fid in data["furniture_positions"]:
			var pos = data["furniture_positions"][fid]
			if pos is Dictionary and pos.has("x") and pos.has("y"):
				_furniture_positions[fid] = {"x": float(pos["x"]), "y": float(pos["y"])}
	if data.has("owned_furniture") and data["owned_furniture"] is Array:
		var owned: Array[String] = []
		for item in data["owned_furniture"]:
			if item is String:
				owned.append(item)
		shop_panel.set_owned(owned)
		# Spawn all owned furniture
		for fid in owned:
			_spawn_furniture(fid)


func _on_coins_changed(new_total: int) -> void:
	coin_label.text = "Coins: " + str(new_total)


func _on_shop_button_pressed() -> void:
	shop_panel.open_shop()


func _on_furniture_purchased(furniture_id: String) -> void:
	_spawn_furniture(furniture_id)


func _spawn_furniture(furniture_id: String) -> void:
	if _furniture_nodes.has(furniture_id):
		return
	var fdata = shop_panel.get_furniture_data(furniture_id)
	if not fdata:
		return

	var node: Furniture = FURNITURE_SCENE.instantiate()
	node.data = fdata
	add_child(node)
	_furniture_nodes[furniture_id] = node

	# Position: use saved position or assign a default
	if _furniture_positions.has(furniture_id):
		var pos = _furniture_positions[furniture_id]
		node.global_position = Vector2(float(pos["x"]), float(pos["y"]))
	else:
		node.global_position = _default_furniture_position(furniture_id)
		_furniture_positions[furniture_id] = {"x": node.global_position.x, "y": node.global_position.y}


func _compute_floor_y() -> float:
	# Use usable screen rect to find taskbar boundary.
	# The usable rect excludes OS-reserved areas like taskbars.
	var usable := DisplayServer.screen_get_usable_rect()
	var uy := float(usable.position.y + usable.size.y)
	# Fallback: if usable rect returns zero/invalid, use full screen height
	if uy <= 0.0:
		uy = float(DisplayServer.screen_get_size().y)
	return uy


func _default_furniture_position(furniture_id: String) -> Vector2:
	# Stagger furniture along the screen bottom, avoiding the pet's starting position
	var screen_w := float(DisplayServer.screen_get_size().x)

	# Pet starts at x=960, so place furniture away from center
	# Count existing furniture to stagger positions
	var index := _furniture_nodes.size() - 1  # current one is already added
	# Start from the left side, spacing 200px apart, offset from pet center
	var start_x := 150.0
	var spacing := 200.0
	var x := start_x + index * spacing
	# If position would overlap pet area (860-1060), shift right
	if x > 810.0 and x < 1110.0:
		x = 1110.0 + (index * spacing - (1110.0 - start_x))

	# Clamp to screen bounds
	x = clampf(x, 100.0, screen_w - 100.0)

	# Place at floor level, accounting for furniture texture height
	var fdata = shop_panel.get_furniture_data(furniture_id)
	var tex_h := 128.0  # fallback
	if fdata and fdata.texture:
		tex_h = fdata.texture.get_size().y
	var y := floor_y - tex_h / 2.0

	return Vector2(x, y)


func _update_passthrough() -> void:
	# Godot's mouse_passthrough_polygon: if set, only the area INSIDE the polygon
	# receives mouse events; everything outside is passed through.
	# We build a bounding box covering all visible interactive elements.

	var rects: Array[Rect2] = []

	# Include pet sprite rect
	if pet_sprite and pet_sprite.texture:
		var pet_pos: Vector2 = pet_sprite.global_position
		var tex_size: Vector2 = pet_sprite.texture.get_size() * pet_sprite.scale
		var half_size: Vector2 = tex_size / 2.0
		rects.append(Rect2(pet_pos - half_size, tex_size))

	# Include coin label rect
	if coin_label and coin_label.visible:
		rects.append(coin_label.get_global_rect())

	# Include interaction menu when visible
	if interaction_menu and interaction_menu.visible:
		rects.append(interaction_menu.get_global_rect())

	# Include slide menu toggle button (always visible)
	if slide_menu:
		var toggle_rect := slide_menu.get_toggle_rect()
		if toggle_rect.size.x > 0:
			rects.append(toggle_rect)
		var panel_rect := slide_menu.get_panel_rect()
		if panel_rect.size.x > 0:
			rects.append(panel_rect)

	# Include shop panel when visible
	if shop_panel and shop_panel.visible:
		rects.append(shop_panel.get_global_rect())

	# Include all spawned furniture
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		if fnode and fnode.data and fnode.data.texture:
			var fpos: Vector2 = fnode.global_position
			var ftex_size: Vector2 = fnode.data.texture.get_size()
			var fhalf: Vector2 = ftex_size / 2.0
			rects.append(Rect2(fpos - fhalf, ftex_size))

	if rects.is_empty():
		return

	# Merge all rects into one bounding box
	# Use .abs() on every Rect2 to guarantee positive dimensions before merging.
	# Rect2 with negative width/height can occur when UI elements are at screen edges.
	var merged := rects[0].abs()
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i].abs())

	var polygon: PackedVector2Array = PackedVector2Array([
		merged.position,
		Vector2(merged.end.x, merged.position.y),
		merged.end,
		Vector2(merged.position.x, merged.end.y),
	])

	get_window().mouse_passthrough_polygon = polygon


func _process(_delta: float) -> void:
	# Update passthrough in case pet moves or menu visibility changes
	_update_passthrough()
