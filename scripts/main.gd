extends Control

## Main scene controller for the desktop pet.
## Manages transparent window with click-through on empty areas
## and captures clicks on the pet sprite and interaction menu.
## Handles save/load of pet state and coins to user://save_data.json.

const SAVE_PATH := "user://save_data.json"

@onready var pet_sprite: Sprite2D = $PetSprite
@onready var coin_system: Node = $CoinSystem
@onready var coin_label: Label = $CoinLabel
@onready var interaction_menu: PanelContainer = $InteractionMenu
@onready var shop_button: Button = $ShopButton
@onready var shop_panel: PanelContainer = $ShopPanel

func _ready() -> void:
	# Make the viewport background transparent
	get_viewport().transparent_bg = true

	# Set window to cover entire primary monitor
	var screen_size := DisplayServer.screen_get_size()
	var win := get_window()
	win.position = Vector2i.ZERO
	win.size = screen_size

	# Start global input hooks for keyboard/mouse tracking
	GlobalInput.start_hooks()

	# Update the mouse passthrough so transparent areas pass clicks through
	_update_passthrough()

	# Connect coin system to update the label
	coin_system.coins_changed.connect(_on_coins_changed)

	# Connect shop button
	shop_button.pressed.connect(_on_shop_button_pressed)

	# Load saved state
	_load_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobalInput.stop_hooks()
		_save_state()
		get_tree().quit()


func _save_state() -> void:
	var data := {
		"coins": coin_system.get_coins(),
		"pet_mood": pet_sprite._current_mood,
		"owned_furniture": shop_panel.get_owned(),
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
	if data.has("owned_furniture") and data["owned_furniture"] is Array:
		var owned: Array[String] = []
		for item in data["owned_furniture"]:
			if item is String:
				owned.append(item)
		shop_panel.set_owned(owned)


func _on_coins_changed(new_total: int) -> void:
	coin_label.text = "Coins: " + str(new_total)


func _on_shop_button_pressed() -> void:
	shop_panel.open_shop()


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

	# Include shop button
	if shop_button and shop_button.visible:
		rects.append(shop_button.get_global_rect())

	# Include shop panel when visible
	if shop_panel and shop_panel.visible:
		rects.append(shop_panel.get_global_rect())

	if rects.is_empty():
		return

	# Merge all rects into one bounding box
	var merged := rects[0]
	for i in range(1, rects.size()):
		merged = merged.merge(rects[i])

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
