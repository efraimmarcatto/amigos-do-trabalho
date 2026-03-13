extends Sprite2D

## Manages pet visual states based on coin balance.
## Connects to CoinSystem.coins_changed to update appearance in real time.
## Handles click detection to open the interaction menu.

enum PetState { SAD, NEUTRAL, HAPPY }

## Coin threshold to enter Neutral state (below this = Sad)
@export var neutral_threshold: int = 10
## Coin threshold to enter Happy state (below this but >= neutral = Neutral)
@export var happy_threshold: int = 50

var _current_state: PetState = PetState.NEUTRAL
var _base_scale: Vector2

# Color tints for each state
const COLOR_HAPPY := Color(0.5, 1.0, 0.5, 1.0)   # Green tint
const COLOR_NEUTRAL := Color(1.0, 1.0, 1.0, 1.0)  # Normal
const COLOR_SAD := Color(0.6, 0.6, 0.8, 1.0)      # Blue/gray tint


func _ready() -> void:
	_base_scale = scale
	# Connect to CoinSystem signal — CoinSystem is a sibling node
	var coin_system := get_parent().get_node("CoinSystem")
	if coin_system:
		coin_system.coins_changed.connect(_on_coins_changed)
	# Connect to InteractionMenu signal for visual reactions
	var menu := get_parent().get_node("InteractionMenu")
	if menu:
		menu.interaction_performed.connect(_on_interaction_performed)
	_update_visual(PetState.NEUTRAL)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_point_on_pet(event.position):
			_toggle_menu()
			get_viewport().set_input_as_handled()


func _is_point_on_pet(point: Vector2) -> bool:
	if not texture:
		return false
	var tex_size: Vector2 = texture.get_size() * scale
	var half: Vector2 = tex_size / 2.0
	var rect := Rect2(global_position - half, tex_size)
	return rect.has_point(point)


func _toggle_menu() -> void:
	var menu := get_parent().get_node("InteractionMenu")
	if not menu:
		return
	if menu.visible:
		menu.visible = false
	else:
		var tex_size: Vector2 = texture.get_size() * scale
		var menu_pos := Vector2(global_position.x + tex_size.x / 2.0 + 10, global_position.y - tex_size.y / 2.0)
		menu.show_menu(menu_pos)


func _on_interaction_performed(_interaction_name: String) -> void:
	_play_bounce()


func _play_bounce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale * 1.3, 0.1)
	tween.tween_property(self, "scale", _base_scale * 0.9, 0.1)
	tween.tween_property(self, "scale", _base_scale, 0.1)


func _on_coins_changed(new_total: int) -> void:
	var new_state := _get_state_for_coins(new_total)
	if new_state != _current_state:
		_current_state = new_state
		_update_visual(_current_state)


func _get_state_for_coins(coins: int) -> PetState:
	if coins >= happy_threshold:
		return PetState.HAPPY
	elif coins >= neutral_threshold:
		return PetState.NEUTRAL
	else:
		return PetState.SAD


func _update_visual(state: PetState) -> void:
	match state:
		PetState.HAPPY:
			modulate = COLOR_HAPPY
		PetState.NEUTRAL:
			modulate = COLOR_NEUTRAL
		PetState.SAD:
			modulate = COLOR_SAD
