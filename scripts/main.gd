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

func _ready() -> void:
	# Make the viewport background transparent
	get_viewport().transparent_bg = true

	# Start global input hooks for keyboard/mouse tracking
	GlobalInput.start_hooks()

	# Update the mouse passthrough so transparent areas pass clicks through
	_update_passthrough()

	# Connect coin system to update the label
	coin_system.coins_changed.connect(_on_coins_changed)

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
		"pet_state": pet_sprite._current_state,
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


func _on_coins_changed(new_total: int) -> void:
	coin_label.text = "Coins: " + str(new_total)


func _update_passthrough() -> void:
	# Godot's mouse_passthrough_polygon: if set, only the area INSIDE the polygon
	# receives mouse events; everything outside is passed through.
	# We set it to cover the pet sprite and the interaction menu (when visible).

	if not pet_sprite or not pet_sprite.texture:
		return

	var pet_pos: Vector2 = pet_sprite.global_position
	var tex_size: Vector2 = pet_sprite.texture.get_size() * pet_sprite.scale
	var half_size: Vector2 = tex_size / 2.0

	var min_pt := pet_pos - half_size
	var max_pt := pet_pos + half_size

	# Expand bounding box to include the interaction menu when visible
	if interaction_menu and interaction_menu.visible:
		var menu_rect := interaction_menu.get_global_rect()
		min_pt.x = min(min_pt.x, menu_rect.position.x)
		min_pt.y = min(min_pt.y, menu_rect.position.y)
		max_pt.x = max(max_pt.x, menu_rect.end.x)
		max_pt.y = max(max_pt.y, menu_rect.end.y)

	var polygon: PackedVector2Array = PackedVector2Array([
		min_pt,
		Vector2(max_pt.x, min_pt.y),
		max_pt,
		Vector2(min_pt.x, max_pt.y),
	])

	get_window().mouse_passthrough_polygon = polygon


func _process(_delta: float) -> void:
	# Update passthrough in case pet moves or menu visibility changes
	_update_passthrough()
