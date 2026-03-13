extends Sprite2D

## Manages pet movement states and visual mood based on coin balance.
## Connects to CoinSystem.coins_changed to update appearance in real time.
## Handles click detection to open the interaction menu.

# Movement state machine
enum PetState { IDLE, WALKING, FALLING, DRAGGED, INTERACTING }

# Visual mood (independent of movement state)
enum PetMood { SAD, NEUTRAL, HAPPY }

## Coin threshold to enter Neutral state (below this = Sad)
@export var neutral_threshold: int = 10
## Coin threshold to enter Happy state (below this but >= neutral = Neutral)
@export var happy_threshold: int = 50

var current_state: PetState = PetState.IDLE
var _current_mood: PetMood = PetMood.NEUTRAL
var _base_scale: Vector2

# Color tints for each mood
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
	_update_visual(_current_mood)


func _process(delta: float) -> void:
	match current_state:
		PetState.IDLE:
			_process_idle(delta)
		PetState.WALKING:
			_process_walking(delta)
		PetState.FALLING:
			_process_falling(delta)
		PetState.DRAGGED:
			_process_dragged(delta)
		PetState.INTERACTING:
			_process_interacting(delta)


func _process_idle(_delta: float) -> void:
	# Placeholder — idle behavior (random walk timer) added in US-005
	pass


func _process_walking(_delta: float) -> void:
	# Placeholder — walking behavior added in US-005
	pass


func _process_falling(_delta: float) -> void:
	# Placeholder — gravity/falling added in US-004
	pass


func _process_dragged(_delta: float) -> void:
	# Placeholder — drag behavior added in US-004
	pass


func _process_interacting(_delta: float) -> void:
	# Placeholder — furniture interaction added in US-011
	pass


func _change_state(new_state: PetState) -> void:
	current_state = new_state


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
	var new_mood := _get_mood_for_coins(new_total)
	if new_mood != _current_mood:
		_current_mood = new_mood
		_update_visual(_current_mood)


func _get_mood_for_coins(coins: int) -> PetMood:
	if coins >= happy_threshold:
		return PetMood.HAPPY
	elif coins >= neutral_threshold:
		return PetMood.NEUTRAL
	else:
		return PetMood.SAD


func _update_visual(mood: PetMood) -> void:
	match mood:
		PetMood.HAPPY:
			modulate = COLOR_HAPPY
		PetMood.NEUTRAL:
			modulate = COLOR_NEUTRAL
		PetMood.SAD:
			modulate = COLOR_SAD
