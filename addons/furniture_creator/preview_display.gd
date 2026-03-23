@tool
extends Control

## Custom preview control that renders the sprite at display scale
## and overlays collision/standing rectangles with drag-to-move and resize support.

signal collision_offset_changed(new_offset: Vector2)
signal standing_offset_changed(new_offset: Vector2)
signal collision_resized(new_size: Vector2, new_offset: Vector2)
signal standing_resized(new_size: Vector2, new_offset: Vector2)

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
enum DragMode { NONE, MOVE, RESIZE }
# Handle indices: 0=top-left, 1=top, 2=top-right, 3=right, 4=bottom-right, 5=bottom, 6=bottom-left, 7=left
enum Handle { TL, T, TR, R, BR, B, BL, L }

const HANDLE_SIZE := 6.0
const MIN_RECT_SIZE := 4.0

var _drag_target: int = DragTarget.NONE
var _drag_mode: int = DragMode.NONE
var _drag_handle: int = -1
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_offset: Vector2 = Vector2.ZERO
var _drag_start_size: Vector2 = Vector2.ZERO
var _hovered_target: int = DragTarget.NONE


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
	var center := scaled_size / 2.0
	var col_size := collision_size if collision_size != Vector2.ZERO else scaled_size
	var col_origin := center - col_size / 2.0 + collision_offset
	var col_rect := Rect2(col_origin, col_size)

	draw_rect(col_rect, collision_color, true)
	draw_rect(col_rect, collision_outline_color, false, 2.0)

	# Draw collision handles when hovered or being edited
	if _hovered_target == DragTarget.COLLISION or (_drag_target == DragTarget.COLLISION):
		_draw_handles(col_rect, collision_outline_color)

	# Draw standing area overlay (green)
	if standing_size != Vector2.ZERO:
		var stand_origin := center - standing_size / 2.0 + standing_offset
		var stand_rect := Rect2(stand_origin, standing_size)
		draw_rect(stand_rect, standing_color, true)
		draw_rect(stand_rect, standing_outline_color, false, 2.0)

		# Draw standing handles when hovered or being edited
		if _hovered_target == DragTarget.STANDING or (_drag_target == DragTarget.STANDING):
			_draw_handles(stand_rect, standing_outline_color)


func _draw_handles(rect: Rect2, color: Color) -> void:
	var positions := _get_handle_positions(rect)
	var half := HANDLE_SIZE / 2.0
	for pos in positions:
		var handle_rect := Rect2(pos - Vector2(half, half), Vector2(HANDLE_SIZE, HANDLE_SIZE))
		draw_rect(handle_rect, color, true)
		draw_rect(handle_rect, Color.WHITE, false, 1.0)


func _get_handle_positions(rect: Rect2) -> Array:
	var tl := rect.position
	var br := rect.position + rect.size
	var mid_x := rect.position.x + rect.size.x / 2.0
	var mid_y := rect.position.y + rect.size.y / 2.0
	return [
		tl,                              # TL
		Vector2(mid_x, tl.y),            # T
		Vector2(br.x, tl.y),             # TR
		Vector2(br.x, mid_y),            # R
		br,                              # BR
		Vector2(mid_x, br.y),            # B
		Vector2(tl.x, br.y),             # BL
		Vector2(tl.x, mid_y),            # L
	]


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
		if _drag_mode == DragMode.MOVE:
			var delta = event.position - _drag_start_mouse
			var new_offset = _drag_start_offset + delta
			if _drag_target == DragTarget.COLLISION:
				collision_offset = new_offset
			elif _drag_target == DragTarget.STANDING:
				standing_offset = new_offset
			queue_redraw()
		elif _drag_mode == DragMode.RESIZE:
			_handle_resize_drag(event.position)
			queue_redraw()
		else:
			_update_cursor(event.position)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check handles first (higher priority than body drag)
			var handle_result := _handle_hit_test(event.position)
			if handle_result[0] != DragTarget.NONE:
				_drag_target = handle_result[0]
				_drag_mode = DragMode.RESIZE
				_drag_handle = handle_result[1]
				_drag_start_mouse = event.position
				if _drag_target == DragTarget.COLLISION:
					_drag_start_size = collision_size if collision_size != Vector2.ZERO else texture.get_size() * display_scale
					_drag_start_offset = collision_offset
				else:
					_drag_start_size = standing_size
					_drag_start_offset = standing_offset
			else:
				# Body drag
				var target := _hit_test(event.position)
				if target != DragTarget.NONE:
					_drag_target = target
					_drag_mode = DragMode.MOVE
					_drag_start_mouse = event.position
					if target == DragTarget.COLLISION:
						_drag_start_offset = collision_offset
					else:
						_drag_start_offset = standing_offset
					mouse_default_cursor_shape = Control.CURSOR_MOVE
		else:
			# End drag
			if _drag_mode == DragMode.MOVE:
				if _drag_target == DragTarget.COLLISION:
					collision_offset_changed.emit(collision_offset)
				elif _drag_target == DragTarget.STANDING:
					standing_offset_changed.emit(standing_offset)
			elif _drag_mode == DragMode.RESIZE:
				if _drag_target == DragTarget.COLLISION:
					collision_resized.emit(collision_size, collision_offset)
				elif _drag_target == DragTarget.STANDING:
					standing_resized.emit(standing_size, standing_offset)
			_drag_target = DragTarget.NONE
			_drag_mode = DragMode.NONE
			_drag_handle = -1
			_update_cursor(event.position)


func _handle_resize_drag(mouse_pos: Vector2) -> void:
	var delta := mouse_pos - _drag_start_mouse
	var new_size := _drag_start_size
	var new_offset := _drag_start_offset

	# Determine which axes are affected and direction
	var handle := _drag_handle
	var dx := delta.x
	var dy := delta.y

	# For each handle, compute new size and offset
	# The opposite corner/edge stays fixed — offset shifts by half the size change
	match handle:
		Handle.TL:
			new_size = Vector2(maxf(_drag_start_size.x - dx, MIN_RECT_SIZE), maxf(_drag_start_size.y - dy, MIN_RECT_SIZE))
			new_offset = _drag_start_offset + Vector2(_drag_start_size.x - new_size.x, _drag_start_size.y - new_size.y) / 2.0
		Handle.T:
			new_size = Vector2(_drag_start_size.x, maxf(_drag_start_size.y - dy, MIN_RECT_SIZE))
			new_offset = _drag_start_offset + Vector2(0, _drag_start_size.y - new_size.y) / 2.0
		Handle.TR:
			new_size = Vector2(maxf(_drag_start_size.x + dx, MIN_RECT_SIZE), maxf(_drag_start_size.y - dy, MIN_RECT_SIZE))
			new_offset = _drag_start_offset + Vector2(new_size.x - _drag_start_size.x, _drag_start_size.y - new_size.y) / 2.0
		Handle.R:
			new_size = Vector2(maxf(_drag_start_size.x + dx, MIN_RECT_SIZE), _drag_start_size.y)
			new_offset = _drag_start_offset + Vector2(new_size.x - _drag_start_size.x, 0) / 2.0
		Handle.BR:
			new_size = Vector2(maxf(_drag_start_size.x + dx, MIN_RECT_SIZE), maxf(_drag_start_size.y + dy, MIN_RECT_SIZE))
			new_offset = _drag_start_offset + Vector2(new_size.x - _drag_start_size.x, new_size.y - _drag_start_size.y) / 2.0
		Handle.B:
			new_size = Vector2(_drag_start_size.x, maxf(_drag_start_size.y + dy, MIN_RECT_SIZE))
			new_offset = _drag_start_offset + Vector2(0, new_size.y - _drag_start_size.y) / 2.0
		Handle.BL:
			new_size = Vector2(maxf(_drag_start_size.x - dx, MIN_RECT_SIZE), maxf(_drag_start_size.y + dy, MIN_RECT_SIZE))
			new_offset = _drag_start_offset + Vector2(_drag_start_size.x - new_size.x, new_size.y - _drag_start_size.y) / 2.0
		Handle.L:
			new_size = Vector2(maxf(_drag_start_size.x - dx, MIN_RECT_SIZE), _drag_start_size.y)
			new_offset = _drag_start_offset + Vector2(_drag_start_size.x - new_size.x, 0) / 2.0

	if _drag_target == DragTarget.COLLISION:
		collision_size = new_size
		collision_offset = new_offset
	elif _drag_target == DragTarget.STANDING:
		standing_size = new_size
		standing_offset = new_offset


func _handle_hit_test(pos: Vector2) -> Array:
	# Returns [DragTarget, handle_index] — checks both rects, smaller gets priority
	var col_rect := _get_collision_rect()
	var stand_rect := _get_standing_rect()

	var col_handle := _check_handles(col_rect, pos)
	var stand_handle := _check_handles(stand_rect, pos) if stand_rect.size != Vector2.ZERO else -1

	if col_handle >= 0 and stand_handle >= 0:
		# Both have handles hit — smaller rect gets priority
		var col_area := col_rect.size.x * col_rect.size.y
		var stand_area := stand_rect.size.x * stand_rect.size.y
		if stand_area <= col_area:
			return [DragTarget.STANDING, stand_handle]
		else:
			return [DragTarget.COLLISION, col_handle]
	elif stand_handle >= 0:
		return [DragTarget.STANDING, stand_handle]
	elif col_handle >= 0:
		return [DragTarget.COLLISION, col_handle]

	return [DragTarget.NONE, -1]


func _check_handles(rect: Rect2, pos: Vector2) -> int:
	if rect.size == Vector2.ZERO:
		return -1
	var positions := _get_handle_positions(rect)
	var half := HANDLE_SIZE / 2.0 + 2.0  # Slightly larger hit area than visual
	for i in range(positions.size()):
		var handle_rect := Rect2(positions[i] - Vector2(half, half), Vector2(half * 2, half * 2))
		if handle_rect.has_point(pos):
			return i
	return -1


func _hit_test(pos: Vector2) -> int:
	var col_rect := _get_collision_rect()
	var stand_rect := _get_standing_rect()

	var in_collision := col_rect.has_point(pos)
	var in_standing := stand_rect.size != Vector2.ZERO and stand_rect.has_point(pos)

	if in_collision and in_standing:
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


func _get_handle_cursor(handle: int) -> int:
	match handle:
		Handle.TL: return Control.CURSOR_FDIAGSIZE
		Handle.TR: return Control.CURSOR_BDIAGSIZE
		Handle.BL: return Control.CURSOR_BDIAGSIZE
		Handle.BR: return Control.CURSOR_FDIAGSIZE
		Handle.T: return Control.CURSOR_VSIZE
		Handle.B: return Control.CURSOR_VSIZE
		Handle.L: return Control.CURSOR_HSIZE
		Handle.R: return Control.CURSOR_HSIZE
	return Control.CURSOR_ARROW


func _update_cursor(pos: Vector2) -> void:
	# Check handles first
	var handle_result := _handle_hit_test(pos)
	if handle_result[0] != DragTarget.NONE:
		_hovered_target = handle_result[0]
		mouse_default_cursor_shape = _get_handle_cursor(handle_result[1])
		queue_redraw()
		return

	var target := _hit_test(pos)
	var old_hovered := _hovered_target
	_hovered_target = target
	if target != DragTarget.NONE:
		mouse_default_cursor_shape = Control.CURSOR_MOVE
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	if old_hovered != _hovered_target:
		queue_redraw()
