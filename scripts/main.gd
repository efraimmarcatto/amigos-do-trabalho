extends Control

## Main scene controller for the desktop pet.
## Manages transparent window with click-through on empty areas
## and captures clicks on the pet sprite and interaction menu.
## Handles save/load of pet state, coins, and inventory to user://save_data.json.

const SAVE_PATH := "user://save_data.json"
const FURNITURE_SCENE := preload("res://scenes/furniture.tscn")

@onready var pet_sprite: AnimatedSprite2D = $PetSprite
@onready var coin_system: Node = $CoinSystem
@onready var coin_hud: PanelContainer = $CoinHud
@onready var interaction_menu: PanelContainer = $InteractionMenu
@onready var slide_menu: Control = $SlideMenu
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_system: Node = $InventorySystem
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var pet_selection_panel: PanelContainer = $PetSelectionPanel

# Spawned furniture instances keyed by furniture_id
var _furniture_nodes: Dictionary = {}
# Saved positions keyed by furniture_id (as {x, y} dicts)
var _furniture_positions: Dictionary = {}
# Floor Y coordinate — top of taskbar (bottom of usable screen rect)
var floor_y: float = 0.0

# Placement mode state
var _placement_mode: bool = false
var _placement_furniture_id: String = ""
var _placement_preview: Sprite2D = null

# Edit mode state
var _edit_mode: bool = false
var _edit_dragging_id: String = ""
var _edit_drag_offset_x: float = 0.0

# Chest button shown during placement mode
var _placement_chest_btn: Button = null

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
	slide_menu.inventory_requested.connect(_on_inventory_button_pressed)
	slide_menu.edit_layout_requested.connect(_on_edit_layout_requested)
	slide_menu.settings_requested.connect(_on_settings_button_pressed)
	slide_menu.pet_selection_requested.connect(_on_pet_selection_button_pressed)
	slide_menu.on_before_close = _handle_menu_close

	# Set up shop panel adjacent to menu
	shop_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())

	# Set up inventory panel adjacent to menu
	inventory_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	inventory_panel.place_requested.connect(_on_inventory_place_requested)

	# Set up settings panel adjacent to menu
	settings_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	settings_panel.monitor_changed.connect(_on_monitor_changed)

	# Set up pet selection panel adjacent to menu
	pet_selection_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	pet_selection_panel.pet_selected.connect(_on_pet_selected)

	# Connect pet mood bubble visibility to update passthrough
	pet_sprite.mood_bubble_visible_changed.connect(_on_mood_bubble_changed)

	# Share furniture nodes dict and floor_y with pet
	pet_sprite._furniture_nodes = _furniture_nodes
	pet_sprite.floor_y = floor_y

	# Position pet at floor level
	var pet_half_h = (pet_sprite.get_sprite_size().y * pet_sprite.scale.abs().y) / 2.0
	pet_sprite.position.y = floor_y - pet_half_h

	# Set up coin HUD to the left of the toggle button
	var toggle_rect = slide_menu.get_toggle_rect()
	coin_hud.setup(floor_y, toggle_rect.position.x, toggle_rect.size.x)

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
		"furniture_positions": _furniture_positions,
		"inventory": inventory_system.get_inventory_for_save(),
		"language": settings_panel.get_current_locale(),
		"monitor": settings_panel.get_current_monitor(),
		"selected_pet": pet_selection_panel.get_current_pet(),
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
	if data.has("inventory") and data["inventory"] is Dictionary:
		var inv_data: Dictionary = {}
		for key in data["inventory"]:
			if key is String and data["inventory"][key] is float:
				inv_data[key] = int(data["inventory"][key])
			elif key is String and data["inventory"][key] is int:
				inv_data[key] = data["inventory"][key]
		inventory_system.set_inventory(inv_data)
	if data.has("language") and data["language"] is String:
		settings_panel.apply_language(data["language"])
	if data.has("selected_pet") and data["selected_pet"] is String:
		pet_selection_panel.apply_pet(data["selected_pet"])
	if data.has("monitor"):
		var monitor_idx := 0
		if data["monitor"] is float:
			monitor_idx = int(data["monitor"])
		elif data["monitor"] is int:
			monitor_idx = data["monitor"]
		if monitor_idx > 0 and monitor_idx < DisplayServer.get_screen_count():
			settings_panel.apply_monitor(monitor_idx)
	# Spawn furniture from saved positions (backward compat: also check owned_furniture)
	var furniture_to_spawn: Array[String] = []
	for fid in _furniture_positions:
		if fid is String:
			furniture_to_spawn.append(fid)
	# Legacy: if there are owned_furniture entries not in furniture_positions, spawn those too
	if data.has("owned_furniture") and data["owned_furniture"] is Array:
		for item in data["owned_furniture"]:
			if item is String and not _furniture_positions.has(item):
				furniture_to_spawn.append(item)
	for fid in furniture_to_spawn:
		_spawn_furniture(fid)


func _on_coins_changed(new_total: int) -> void:
	coin_hud.update_coins(new_total)


func _on_mood_bubble_changed(_is_visible: bool) -> void:
	_update_passthrough()


func _handle_menu_close() -> void:
	## Intercepts menu close: if a panel is open, close it first, then close menu.
	if shop_panel.is_shop_open():
		shop_panel.close_shop()
		get_tree().create_timer(shop_panel.get_close_duration()).timeout.connect(
			slide_menu.close_menu
		)
	elif inventory_panel.is_panel_open():
		inventory_panel.close_panel()
		get_tree().create_timer(inventory_panel.get_close_duration()).timeout.connect(
			slide_menu.close_menu
		)
	elif settings_panel.is_panel_open():
		settings_panel.close_panel()
		get_tree().create_timer(settings_panel.get_close_duration()).timeout.connect(
			slide_menu.close_menu
		)
	elif pet_selection_panel.is_panel_open():
		pet_selection_panel.close_panel()
		get_tree().create_timer(pet_selection_panel.get_close_duration()).timeout.connect(
			slide_menu.close_menu
		)
	else:
		slide_menu.close_menu()


func _on_shop_button_pressed() -> void:
	# Close other panels if open (mutual exclusivity)
	if inventory_panel.is_panel_open():
		inventory_panel.close_panel()
	if settings_panel.is_panel_open():
		settings_panel.close_panel()
	if pet_selection_panel.is_panel_open():
		pet_selection_panel.close_panel()
	if shop_panel.is_shop_open():
		shop_panel.close_shop()
		return
	# Delay shop open slightly for a chained animation feel
	get_tree().create_timer(0.1).timeout.connect(shop_panel.open_shop)


func _on_inventory_button_pressed() -> void:
	# Close other panels if open (mutual exclusivity)
	if shop_panel.is_shop_open():
		shop_panel.close_shop()
	if settings_panel.is_panel_open():
		settings_panel.close_panel()
	if pet_selection_panel.is_panel_open():
		pet_selection_panel.close_panel()
	if inventory_panel.is_panel_open():
		inventory_panel.close_panel()
		return
	# Delay inventory open slightly for a chained animation feel
	get_tree().create_timer(0.1).timeout.connect(inventory_panel.open_panel)


func _on_settings_button_pressed() -> void:
	# Close other panels if open (mutual exclusivity)
	if shop_panel.is_shop_open():
		shop_panel.close_shop()
	if inventory_panel.is_panel_open():
		inventory_panel.close_panel()
	if pet_selection_panel.is_panel_open():
		pet_selection_panel.close_panel()
	if settings_panel.is_panel_open():
		settings_panel.close_panel()
		return
	# Delay settings open slightly for a chained animation feel
	get_tree().create_timer(0.1).timeout.connect(settings_panel.open_panel)


func _on_pet_selection_button_pressed() -> void:
	# Close other panels if open (mutual exclusivity)
	if shop_panel.is_shop_open():
		shop_panel.close_shop()
	if inventory_panel.is_panel_open():
		inventory_panel.close_panel()
	if settings_panel.is_panel_open():
		settings_panel.close_panel()
	if pet_selection_panel.is_panel_open():
		pet_selection_panel.close_panel()
		return
	# Delay open slightly for a chained animation feel
	get_tree().create_timer(0.1).timeout.connect(pet_selection_panel.open_panel)


func _on_pet_selected(_pet_name: String, new_sprite_frames: SpriteFrames) -> void:
	## Swap the pet's sprite_frames when a new pet is selected.
	pet_sprite.sprite_frames = new_sprite_frames
	pet_sprite.play("idle")
	_save_state()


func _on_monitor_changed(_monitor_index: int) -> void:
	## After the window has been moved to a new monitor, recompute layout.
	# Wait a frame for the window to settle on the new screen
	await get_tree().process_frame

	# Recompute floor_y for the new screen
	floor_y = _compute_floor_y()
	pet_sprite.floor_y = floor_y

	# Resize window to cover the new screen
	var screen_size := DisplayServer.screen_get_size()
	var win := get_window()
	win.position = DisplayServer.screen_get_position(DisplayServer.window_get_current_screen())
	win.size = screen_size

	# Reposition pet — clamp to new screen bounds
	var pet_half_h = (pet_sprite.get_sprite_size().y * pet_sprite.scale.abs().y) / 2.0
	var pet_half_w = (pet_sprite.get_sprite_size().x * pet_sprite.scale.abs().x) / 2.0
	pet_sprite.position.y = floor_y - pet_half_h
	pet_sprite.position.x = clampf(pet_sprite.position.x, pet_half_w, float(screen_size.x) - pet_half_w)

	# Reposition all placed furniture — clamp to new screen bounds, set Y to floor
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		if not fnode or not fnode.data or not fnode.data.texture:
			continue
		var tex_size := fnode.data.texture.get_size() * fnode.data.display_scale
		var half_w := tex_size.x / 2.0
		var new_x := clampf(fnode.global_position.x, half_w, float(screen_size.x) - half_w)
		var new_y := floor_y - tex_size.y / 2.0
		fnode.global_position = Vector2(new_x, new_y)
		_furniture_positions[fid] = {"x": new_x, "y": new_y}

	# Reposition UI elements for new screen
	slide_menu.setup(floor_y)
	shop_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	inventory_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	settings_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	pet_selection_panel.setup(slide_menu.get_panel_open_x(), slide_menu.get_panel_y())
	var toggle_rect = slide_menu.get_toggle_rect()
	coin_hud.setup(floor_y, toggle_rect.position.x, toggle_rect.size.x)

	# Re-open settings panel since user was just in it
	settings_panel.open_panel()

	_save_state()


func _on_inventory_place_requested(furniture_id: String) -> void:
	_enter_placement_mode(furniture_id)


func _enter_placement_mode(furniture_id: String) -> void:
	_placement_mode = true
	_placement_furniture_id = furniture_id

	# Close any open panels
	shop_panel.close_shop()
	inventory_panel.close_panel()
	settings_panel.close_panel()
	pet_selection_panel.close_panel()

	# Create a semi-transparent preview sprite
	var fdata = shop_panel.get_furniture_data(furniture_id)
	if fdata and fdata.texture:
		_placement_preview = Sprite2D.new()
		_placement_preview.texture = fdata.texture
		_placement_preview.scale = fdata.display_scale
		_placement_preview.modulate = Color(1.0, 1.0, 1.0, 0.5)
		add_child(_placement_preview)
		# Position at mouse, constrained to floor
		var tex_h = fdata.texture.get_size().y * fdata.display_scale.y
		_placement_preview.global_position = Vector2(
			get_global_mouse_position().x,
			floor_y - tex_h / 2.0
		)

	# Create chest/inventory button for storing item during placement
	_placement_chest_btn = Button.new()
	_placement_chest_btn.text = tr("TO_INVENTORY")
	_placement_chest_btn.size = Vector2(140, 36)
	var screen_w := float(DisplayServer.screen_get_size().x)
	_placement_chest_btn.position = Vector2(screen_w / 2.0 - 70.0, floor_y - 60.0)
	var chest_style := StyleBoxFlat.new()
	chest_style.bg_color = Color(0.2, 0.45, 0.7, 0.9)
	chest_style.corner_radius_top_left = 6
	chest_style.corner_radius_top_right = 6
	chest_style.corner_radius_bottom_left = 6
	chest_style.corner_radius_bottom_right = 6
	chest_style.content_margin_left = 8
	chest_style.content_margin_right = 8
	chest_style.content_margin_top = 4
	chest_style.content_margin_bottom = 4
	_placement_chest_btn.add_theme_stylebox_override("normal", chest_style)
	_placement_chest_btn.add_theme_color_override("font_color", Color.WHITE)
	_placement_chest_btn.pressed.connect(_on_placement_chest_pressed)
	add_child(_placement_chest_btn)

	# Disable passthrough so full window captures input
	get_window().mouse_passthrough_polygon = PackedVector2Array()


func _exit_placement_mode(confirmed: bool) -> void:
	if not _placement_mode:
		return
	_placement_mode = false

	if confirmed and _placement_preview:
		# Spawn furniture at the preview position
		_spawn_furniture_at(_placement_furniture_id, _placement_preview.global_position)
	else:
		# Cancelled — return item to inventory
		inventory_system.add_to_inventory(_placement_furniture_id)

	# Clean up preview
	if _placement_preview:
		_placement_preview.queue_free()
		_placement_preview = null
	# Clean up chest button
	if _placement_chest_btn:
		_placement_chest_btn.queue_free()
		_placement_chest_btn = null
	_placement_furniture_id = ""


func _on_placement_chest_pressed() -> void:
	## Chest button pressed during placement — store item to inventory.
	_exit_placement_mode(false)


func _spawn_furniture_at(furniture_id: String, pos: Vector2) -> void:
	if _furniture_nodes.has(furniture_id):
		return
	var fdata = shop_panel.get_furniture_data(furniture_id)
	if not fdata:
		return

	var node: Furniture = FURNITURE_SCENE.instantiate()
	node.data = fdata
	add_child(node)
	_furniture_nodes[furniture_id] = node
	node.global_position = pos
	_furniture_positions[furniture_id] = {"x": pos.x, "y": pos.y}
	_save_state()


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
		tex_h = fdata.texture.get_size().y * fdata.display_scale.y
	var y := floor_y - tex_h / 2.0

	return Vector2(x, y)


func _on_edit_layout_requested() -> void:
	# Close panels if open before entering/exiting edit mode
	if shop_panel.is_shop_open():
		shop_panel.close_shop()
	if inventory_panel.is_panel_open():
		inventory_panel.close_panel()
	if settings_panel.is_panel_open():
		settings_panel.close_panel()
	if pet_selection_panel.is_panel_open():
		pet_selection_panel.close_panel()
	if _edit_mode:
		_exit_edit_mode()
	else:
		_enter_edit_mode()


func _enter_edit_mode() -> void:
	_edit_mode = true
	# Pause pet
	pet_sprite.paused = true
	if pet_sprite.current_state == pet_sprite.PetState.WALKING:
		pet_sprite._change_state(pet_sprite.PetState.IDLE)
	# Highlight all furniture and add remove buttons
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		fnode.modulate = Color(1.2, 1.2, 0.8, 1.0)
		_add_remove_button(fid, fnode)
	# Update edit button label
	slide_menu.set_edit_button_text(tr("SAVE_EDIT_BUTTON"))
	# Disable passthrough to capture all input
	get_window().mouse_passthrough_polygon = PackedVector2Array()


func _exit_edit_mode() -> void:
	if not _edit_mode:
		return
	_edit_mode = false
	_edit_dragging_id = ""
	# Resume pet
	pet_sprite.paused = false
	# Remove furniture highlights and remove buttons
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		fnode.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_remove_remove_button(fnode)
	# Restore edit button label
	slide_menu.set_edit_button_text(tr("EDIT_LAYOUT_BUTTON"))
	# Save positions
	_save_state()


func _add_remove_button(furniture_id: String, fnode: Furniture) -> void:
	## Adds a small "X" button above the furniture piece for removal during edit mode.
	var btn := Button.new()
	btn.name = "RemoveButton"
	btn.text = "X"
	btn.size = Vector2(28, 28)
	# Position above the furniture sprite (centered horizontally)
	var tex_h := 0.0
	if fnode.data and fnode.data.texture:
		tex_h = fnode.data.texture.get_size().y * fnode.data.display_scale.y
	btn.position = Vector2(-14.0, -(tex_h / 2.0) - 32.0)
	btn.pressed.connect(_on_remove_furniture.bind(furniture_id))
	# Style the button with a red-ish background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color.WHITE)
	fnode.add_child(btn)


func _remove_remove_button(fnode: Furniture) -> void:
	## Removes the remove button from a furniture node if it exists.
	var btn := fnode.get_node_or_null("RemoveButton")
	if btn:
		btn.queue_free()


func _on_remove_furniture(furniture_id: String) -> void:
	## Removes furniture from the scene during edit mode and adds it to inventory.
	if not _edit_mode:
		return
	if not _furniture_nodes.has(furniture_id):
		return

	var fnode: Furniture = _furniture_nodes[furniture_id]

	# Check if pet is standing on this furniture — force FALLING state
	if pet_sprite._current_surface == fnode:
		pet_sprite._current_surface = null
		pet_sprite._change_state(pet_sprite.PetState.FALLING)

	# Remove from scene and tracking
	fnode.queue_free()
	_furniture_nodes.erase(furniture_id)
	_furniture_positions.erase(furniture_id)

	# Add back to inventory
	inventory_system.add_to_inventory(furniture_id)


func _get_furniture_at_point(point: Vector2) -> String:
	## Returns the furniture_id of the furniture piece at the given point, or "".
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		if not fnode or not fnode.data or not fnode.data.texture:
			continue
		var tex_size := fnode.data.texture.get_size() * fnode.data.display_scale
		var half := tex_size / 2.0
		var rect := Rect2(fnode.global_position - half, tex_size)
		if rect.has_point(point):
			return fid
	return ""


func _is_overlap_with_other(furniture_id: String, x_pos: float) -> bool:
	## Check if placing furniture at x_pos would overlap another furniture piece.
	var fnode: Furniture = _furniture_nodes[furniture_id]
	if not fnode or not fnode.data or not fnode.data.texture:
		return false
	var half_w := fnode.data.texture.get_size().x * fnode.data.display_scale.x / 2.0
	var new_left := x_pos - half_w
	var new_right := x_pos + half_w
	for other_id in _furniture_nodes:
		if other_id == furniture_id:
			continue
		var other: Furniture = _furniture_nodes[other_id]
		if not other or not other.data or not other.data.texture:
			continue
		var o_half_w := other.data.texture.get_size().x * other.data.display_scale.x / 2.0
		var o_left := other.global_position.x - o_half_w
		var o_right := other.global_position.x + o_half_w
		if new_right > o_left and new_left < o_right:
			return true
	return false


func _update_passthrough() -> void:
	# Godot's mouse_passthrough_polygon: if set, only the area INSIDE the polygon
	# receives mouse events; everything outside is passed through.
	# We build a bounding box covering all visible interactive elements.

	var rects: Array[Rect2] = []

	# Include pet sprite rect
	if pet_sprite and pet_sprite.sprite_frames:
		var pet_pos: Vector2 = pet_sprite.global_position
		var tex_size: Vector2 = pet_sprite.get_sprite_size() * pet_sprite.scale
		var half_size: Vector2 = tex_size / 2.0
		rects.append(Rect2(pet_pos - half_size, tex_size))

	# Include mood speech bubble when visible
	if pet_sprite:
		var bubble_rect = pet_sprite.get_bubble_rect()
		if bubble_rect.size.x > 0:
			rects.append(bubble_rect)

	# Include coin HUD rect
	if coin_hud and coin_hud.visible:
		rects.append(coin_hud.get_rect())

	# Include interaction menu when visible
	if interaction_menu and interaction_menu.visible:
		rects.append(interaction_menu.get_global_rect())

	# Include slide menu toggle button (always visible)
	if slide_menu:
		var toggle_rect = slide_menu.get_toggle_rect()
		if toggle_rect.size.x > 0:
			rects.append(toggle_rect)
		var panel_rect = slide_menu.get_panel_rect()
		if panel_rect.size.x > 0:
			rects.append(panel_rect)

	# Include shop panel when open
	if shop_panel and shop_panel.is_shop_open():
		rects.append(shop_panel.get_global_rect())

	# Include inventory panel when open
	if inventory_panel and inventory_panel.is_panel_open():
		rects.append(inventory_panel.get_global_rect())

	# Include settings panel when open
	if settings_panel and settings_panel.is_panel_open():
		rects.append(settings_panel.get_global_rect())

	# Include pet selection panel when open
	if pet_selection_panel and pet_selection_panel.is_panel_open():
		rects.append(pet_selection_panel.get_global_rect())

	# Include all spawned furniture
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		if fnode and fnode.data and fnode.data.texture:
			var fpos: Vector2 = fnode.global_position
			var ftex_size: Vector2 = fnode.data.texture.get_size() * fnode.data.display_scale
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


func _input(event: InputEvent) -> void:
	# Edit mode input handling
	if _edit_mode:
		_handle_edit_input(event)
		return

	if not _placement_mode:
		return

	if event is InputEventMouseMotion and _placement_preview:
		# Move preview to mouse X, constrained to floor Y and screen bounds
		var fdata = shop_panel.get_furniture_data(_placement_furniture_id)
		if fdata and fdata.texture:
			var tex_w = fdata.texture.get_size().x * fdata.display_scale.x
			var tex_h = fdata.texture.get_size().y * fdata.display_scale.y
			var screen_w := float(DisplayServer.screen_get_size().x)
			var x := clampf(event.position.x, tex_w / 2.0, screen_w - tex_w / 2.0)
			_placement_preview.global_position = Vector2(x, floor_y - tex_h / 2.0)
		get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Don't intercept clicks on the chest button — let Button handle them
			if _placement_chest_btn and _placement_chest_btn.get_global_rect().has_point(event.position):
				return
			# Confirm placement
			_exit_placement_mode(true)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel placement
			_exit_placement_mode(false)
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			# Cancel placement
			_exit_placement_mode(false)
			get_viewport().set_input_as_handled()


func _is_click_on_remove_button(point: Vector2) -> bool:
	## Returns true if the point is within any furniture's remove button.
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		var btn := fnode.get_node_or_null("RemoveButton")
		if btn and btn is Button:
			var btn_rect := Rect2(fnode.global_position + btn.position, btn.size)
			if btn_rect.has_point(point):
				return true
	return false


func _handle_edit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Don't intercept clicks on remove buttons — let Button handle them
			if _is_click_on_remove_button(event.position):
				return
			# Start dragging a furniture piece
			var fid := _get_furniture_at_point(event.position)
			if fid != "":
				_edit_dragging_id = fid
				var fnode: Furniture = _furniture_nodes[fid]
				_edit_drag_offset_x = fnode.global_position.x - event.position.x
				get_viewport().set_input_as_handled()
		else:
			# Release drag
			if _edit_dragging_id != "":
				_edit_dragging_id = ""
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _edit_dragging_id != "":
		var fnode: Furniture = _furniture_nodes[_edit_dragging_id]
		if fnode and fnode.data and fnode.data.texture:
			var half_w := fnode.data.texture.get_size().x * fnode.data.display_scale.x / 2.0
			var screen_w := float(DisplayServer.screen_get_size().x)
			var new_x := clampf(event.position.x + _edit_drag_offset_x, half_w, screen_w - half_w)
			# Check overlap with other furniture
			if not _is_overlap_with_other(_edit_dragging_id, new_x):
				fnode.global_position.x = new_x
		get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_exit_edit_mode()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _placement_mode or _edit_mode:
		# During placement or edit mode, passthrough is already disabled; skip normal update
		return
	# Update passthrough in case pet moves or menu visibility changes
	_update_passthrough()
