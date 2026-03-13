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
## Gravity acceleration in pixels/sec²
@export var gravity: float = 980.0
## Walking speed in pixels/sec
@export var walk_speed: float = 120.0

var current_state: PetState = PetState.IDLE
var _current_mood: PetMood = PetMood.NEUTRAL
var _base_scale: Vector2
var _velocity: Vector2 = Vector2.ZERO

# Drag tracking
var _mouse_pressed: bool = false
var _mouse_press_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
const DRAG_THRESHOLD := 4.0

# Idle walking
var _idle_timer: float = 0.0
var _walk_target_x: float = 0.0

# Furniture surface tracking
var _furniture_nodes: Dictionary = {}  # Set by main.gd — keyed by furniture_id
var _current_surface: Furniture = null  # null = screen floor

# Floor Y coordinate — set by main.gd (top of taskbar / bottom of usable rect)
var floor_y: float = 0.0

# Interaction tracking
var _interacting_furniture: Furniture = null
var _interaction_timer: float = 0.0
var _sleep_label: Label = null

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
	_idle_timer = randf_range(1.0, 5.0)


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


func _process_idle(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		var half_w := (texture.get_size().x * scale.abs().x) / 2.0
		var min_x: float
		var max_x: float
		if _current_surface:
			min_x = _current_surface.get_left_x() + half_w
			max_x = _current_surface.get_right_x() - half_w
		else:
			var screen_w := float(DisplayServer.screen_get_size().x)
			min_x = half_w
			max_x = screen_w - half_w
		var direction := 1.0 if randf() > 0.5 else -1.0
		var distance := randf_range(50.0, 300.0)
		_walk_target_x = clampf(position.x + direction * distance, min_x, max_x)
		# Don't walk if target is basically where we are
		if absf(_walk_target_x - position.x) > 2.0:
			_change_state(PetState.WALKING)
		else:
			_idle_timer = randf_range(1.0, 5.0)


func _process_walking(_delta: float) -> void:
	var dir := signf(_walk_target_x - position.x)
	# Flip sprite horizontally based on direction
	scale.x = absf(_base_scale.x) * dir if dir != 0.0 else scale.x

	position.x += dir * walk_speed * _delta

	var half_w := (texture.get_size().x * scale.abs().x) / 2.0

	# Check furniture surface edge constraints
	if _current_surface:
		var left_edge := _current_surface.get_left_x() + half_w
		var right_edge := _current_surface.get_right_x() - half_w
		if position.x <= left_edge or position.x >= right_edge:
			if _current_surface.data.can_fall_off_edge:
				# Walk off the edge and fall
				_current_surface = null
				_velocity = Vector2.ZERO
				_change_state(PetState.FALLING)
				return
			else:
				# Treat edge as wall — stop and go idle
				position.x = clampf(position.x, left_edge, right_edge)
				scale.x = absf(_base_scale.x)
				_change_state(PetState.IDLE)
				return
	else:
		# On screen floor — check screen bounds
		var screen_w := float(DisplayServer.screen_get_size().x)
		position.x = clampf(position.x, half_w, screen_w - half_w)

	# Check for non-walkable furniture as walls (on screen floor only)
	if not _current_surface:
		var pet_half_h := (texture.get_size().y * scale.abs().y) / 2.0
		var pet_bottom := position.y + pet_half_h
		for fid in _furniture_nodes:
			var fnode: Furniture = _furniture_nodes[fid]
			if not fnode or not fnode.data or not fnode.data.texture:
				continue
			if fnode.data.walkable:
				continue
			# Check if pet collides horizontally with this non-walkable furniture
			var f_left := fnode.get_left_x()
			var f_right := fnode.get_right_x()
			var f_top := fnode.global_position.y - fnode.data.texture.get_size().y / 2.0
			var f_bottom := fnode.global_position.y + fnode.data.texture.get_size().y / 2.0
			# Only block if pet overlaps vertically with the furniture
			if pet_bottom > f_top and position.y - pet_half_h < f_bottom:
				if dir > 0.0 and position.x + half_w > f_left and position.x < f_left:
					position.x = f_left - half_w
					scale.x = absf(_base_scale.x)
					_change_state(PetState.IDLE)
					return
				elif dir < 0.0 and position.x - half_w < f_right and position.x > f_right:
					position.x = f_right + half_w
					scale.x = absf(_base_scale.x)
					_change_state(PetState.IDLE)
					return

	# Check for interactive furniture overlap while walking
	_try_furniture_interaction()
	if current_state == PetState.INTERACTING:
		return

	# Check if reached target
	if (dir > 0.0 and position.x >= _walk_target_x) or (dir < 0.0 and position.x <= _walk_target_x):
		position.x = _walk_target_x
		scale.x = absf(_base_scale.x)
		_change_state(PetState.IDLE)


func _process_falling(delta: float) -> void:
	var prev_y := position.y
	_velocity.y += gravity * delta
	position += _velocity * delta

	var half_h := (texture.get_size().y * scale.abs().y) / 2.0
	var pet_bottom := position.y + half_h
	var half_w := (texture.get_size().x * scale.abs().x) / 2.0

	# Check walkable furniture surfaces — find the highest one below us
	var best_surface: Furniture = null
	var best_surface_y: float = INF
	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		if not fnode or not fnode.data or not fnode.data.texture:
			continue
		if not fnode.data.walkable:
			continue
		var surf_y := fnode.get_surface_y()
		var f_left := fnode.get_left_x()
		var f_right := fnode.get_right_x()
		# Pet center X must be within the furniture X range
		if position.x >= f_left + half_w and position.x <= f_right - half_w:
			# Only land if we're crossing this surface (were above, now at or below)
			var land_y := surf_y - half_h
			if prev_y <= land_y and position.y >= land_y:
				if land_y < best_surface_y:
					best_surface_y = land_y
					best_surface = fnode

	if best_surface:
		position.y = best_surface_y
		_velocity = Vector2.ZERO
		_current_surface = best_surface
		_change_state(PetState.IDLE)
		return

	# Land on floor (top of taskbar)
	var land_floor_y := floor_y - half_h
	if position.y >= land_floor_y:
		position.y = land_floor_y
		_velocity = Vector2.ZERO
		_current_surface = null
		_change_state(PetState.IDLE)


func _process_dragged(_delta: float) -> void:
	position = get_global_mouse_position()


func _process_interacting(delta: float) -> void:
	_interaction_timer -= delta
	if _interaction_timer <= 0.0:
		# Clean up sleep visual if active
		if _sleep_label:
			_sleep_label.queue_free()
			_sleep_label = null
		_interacting_furniture = null
		_change_state(PetState.IDLE)


func _try_furniture_interaction() -> void:
	# Check if pet overlaps any interactive furniture's Area2D
	var pet_half_w := (texture.get_size().x * scale.abs().x) / 2.0
	var pet_half_h := (texture.get_size().y * scale.abs().y) / 2.0
	var pet_rect := Rect2(position.x - pet_half_w, position.y - pet_half_h, pet_half_w * 2.0, pet_half_h * 2.0)

	for fid in _furniture_nodes:
		var fnode: Furniture = _furniture_nodes[fid]
		if not fnode or not fnode.data or not fnode.data.texture:
			continue
		if not fnode.can_interact():
			continue
		# Check overlap
		var f_half_w := fnode.data.texture.get_size().x / 2.0
		var f_half_h := fnode.data.texture.get_size().y / 2.0
		var f_rect := Rect2(fnode.global_position.x - f_half_w, fnode.global_position.y - f_half_h, f_half_w * 2.0, f_half_h * 2.0)
		if pet_rect.intersects(f_rect):
			_start_interaction(fnode)
			return


func _start_interaction(fnode: Furniture) -> void:
	_interacting_furniture = fnode
	fnode.mark_interacted()

	# Award coins
	var coin_system := get_parent().get_node("CoinSystem")
	if coin_system and fnode.data.interaction_coin_bonus > 0:
		coin_system.add_coins(fnode.data.interaction_coin_bonus)

	match fnode.data.interaction_type:
		"sleep":
			_interaction_timer = randf_range(2.0, 3.0)
			# Show Zzz label
			_sleep_label = Label.new()
			_sleep_label.text = "Zzz"
			_sleep_label.add_theme_font_size_override("font_size", 24)
			_sleep_label.position = Vector2(10, -40)
			add_child(_sleep_label)
			# Sleeping tint
			modulate = Color(0.7, 0.7, 1.0, 1.0)
		"eat":
			_interaction_timer = 0.3  # Short — bounce duration
			_play_bounce()
		"play":
			_interaction_timer = 0.3
			_play_bounce()
		_:
			_interaction_timer = 0.5

	_change_state(PetState.INTERACTING)


func _change_state(new_state: PetState) -> void:
	var old_state := current_state
	current_state = new_state

	# Exit visual cleanup
	if old_state == PetState.DRAGGED:
		rotation_degrees = 0.0
	if old_state == PetState.WALKING:
		scale.x = absf(_base_scale.x)
	if old_state == PetState.INTERACTING:
		# Restore mood-based color
		_update_visual(_current_mood)
		if _sleep_label:
			_sleep_label.queue_free()
			_sleep_label = null

	# Enter state setup
	if new_state == PetState.DRAGGED:
		rotation_degrees = 5.0
		_current_surface = null
	elif new_state == PetState.FALLING:
		# When entering FALLING from drag, clear surface (will detect new one)
		if old_state == PetState.DRAGGED:
			_current_surface = null
	elif new_state == PetState.IDLE:
		_idle_timer = randf_range(1.0, 5.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_point_on_pet(event.position):
				_mouse_pressed = true
				_mouse_press_pos = event.position
				_is_dragging = false
				get_viewport().set_input_as_handled()
		else:
			# Mouse released
			if _mouse_pressed:
				_mouse_pressed = false
				if _is_dragging:
					# End drag → start falling
					_is_dragging = false
					_velocity = Vector2.ZERO
					_change_state(PetState.FALLING)
				else:
					# Was a click (no drag) → toggle menu
					_toggle_menu()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _mouse_pressed:
		if not _is_dragging:
			if event.position.distance_to(_mouse_press_pos) > DRAG_THRESHOLD:
				_is_dragging = true
				_change_state(PetState.DRAGGED)
				# Hide menu if it was open
				var menu := get_parent().get_node("InteractionMenu")
				if menu and menu.visible:
					menu.visible = false


func _is_point_on_pet(point: Vector2) -> bool:
	if not texture:
		return false
	var tex_size: Vector2 = texture.get_size() * scale.abs()
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
		var tex_size: Vector2 = texture.get_size() * scale.abs()
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
