@tool
extends Control

## Custom preview control that renders the sprite at display scale
## and overlays collision/standing rectangles with drag-to-move support.

signal collision_offset_changed(new_offset: Vector2)
signal standing_offset_changed(new_offset: Vector2)

var texture: Texture2D = null
var display_scale: Vector2 = Vector2(4, 4)
var collision_size: Vector2 = Vector2.ZERO
var collision_offset: Vector2 = Vector2.ZERO
var collision_color: Color = Color(0.2, 0.6, 1.0, 0.3)
var collision_outline_color: Color = Color(0.2, 0.6, 1.0, 0.8)
var standing_size: Vector2 = Vector2.ZERO
var standing_offset: Vector2 = Vector2.ZERO
var standing_color: Color = Color(0.2, 0.8, 0.2, 0.3)
var standing_outline_color: Color = Color(0.2, 0.8, 0.2, 0.8)

# Drag state
enum DragTarget { NONE, COLLISION, STANDING }
var _drag_target: int = DragTarget.NONE
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_offset: Vector2 = Vector2.ZERO


func update_preview(p_texture: Texture2D, p_display_scale: Vector2, p_collision_size: Vector2, p_collision_offset: Vector2, p_standing_size: Vector2 = Vector2.ZERO, p_standing_offset: Vector2 = Vector2.ZERO) -> void:
	texture = p_texture
	display_scale = p_display_scale
	collision_size = p_collision_size
	collision_offset = p_collision_offset
	standing_size = p_standing_size
	standing_offset = p_standing_offset
	if texture:
		var scaled_size := texture.get_size() * display_scale
		custom_minimum_size = scaled_size
		size = scaled_size
	else:
		custom_minimum_size = Vector2.ZERO
		size = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if texture == null:
		return

	var tex_size := texture.get_size()
	var scaled_size := tex_size * display_scale

	# Draw the texture scaled
	draw_texture_rect(texture, Rect2(Vector2.ZERO, scaled_size), false)

	# Draw collision overlay
	# Collision rect is centered on the sprite center, then offset
	var center := scaled_size / 2.0
	var col_size := collision_size if collision_size != Vector2.ZERO else scaled_size
	var col_origin := center - col_size / 2.0 + collision_offset
	var col_rect := Rect2(col_origin, col_size)

	draw_rect(col_rect, collision_color, true)
	draw_rect(col_rect, collision_outline_color, false, 2.0)

	# Draw standing area overlay (green)
	if standing_size != Vector2.ZERO:
		var stand_origin := center - standing_size / 2.0 + standing_offset
		var stand_rect := Rect2(stand_origin, standing_size)
		draw_rect(stand_rect, standing_color, true)
		draw_rect(stand_rect, standing_outline_color, false, 2.0)


func _get_collision_rect() -> Rect2:
	if texture == null:
		return Rect2()
	var scaled_size := texture.get_size() * display_scale
	var center := scaled_size / 2.0
	var col_size := collision_size if collision_size != Vector2.ZERO else scaled_size
	var col_origin := center - col_size / 2.0 + collision_offset
	return Rect2(col_origin, col_size)


func _get_standing_rect() -> Rect2:
	if texture == null or standing_size == Vector2.ZERO:
		return Rect2()
	var scaled_size := texture.get_size() * display_scale
	var center := scaled_size / 2.0
	var stand_origin := center - standing_size / 2.0 + standing_offset
	return Rect2(stand_origin, standing_size)


func _gui_input(event: InputEvent) -> void:
	if texture == null:
		return

	if event is InputEventMouseMotion:
		if _drag_target != DragTarget.NONE:
			# Active drag — update offset in real-time
			var delta := event.position - _drag_start_mouse
			var new_offset := _drag_start_offset + delta
			if _drag_target == DragTarget.COLLISION:
				collision_offset = new_offset
			elif _drag_target == DragTarget.STANDING:
				standing_offset = new_offset
			queue_redraw()
		else:
			# Update cursor based on hover
			_update_cursor(event.position)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start drag — smaller rect gets priority when overlapping
			var target := _hit_test(event.position)
			if target != DragTarget.NONE:
				_drag_target = target
				_drag_start_mouse = event.position
				if target == DragTarget.COLLISION:
					_drag_start_offset = collision_offset
				else:
					_drag_start_offset = standing_offset
				mouse_default_cursor_shape = Control.CURSOR_MOVE
		else:
			# End drag — emit signal with new offset
			if _drag_target == DragTarget.COLLISION:
				collision_offset_changed.emit(collision_offset)
			elif _drag_target == DragTarget.STANDING:
				standing_offset_changed.emit(standing_offset)
			_drag_target = DragTarget.NONE
			_update_cursor(event.position)


func _hit_test(pos: Vector2) -> int:
	var col_rect := _get_collision_rect()
	var stand_rect := _get_standing_rect()

	var in_collision := col_rect.has_point(pos)
	var in_standing := stand_rect.size != Vector2.ZERO and stand_rect.has_point(pos)

	if in_collision and in_standing:
		# Smaller rect gets priority
		var col_area := col_rect.size.x * col_rect.size.y
		var stand_area := stand_rect.size.x * stand_rect.size.y
		if stand_area <= col_area:
			return DragTarget.STANDING
		else:
			return DragTarget.COLLISION
	elif in_standing:
		return DragTarget.STANDING
	elif in_collision:
		return DragTarget.COLLISION

	return DragTarget.NONE


func _update_cursor(pos: Vector2) -> void:
	var target := _hit_test(pos)
	if target != DragTarget.NONE:
		mouse_default_cursor_shape = Control.CURSOR_MOVE
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
