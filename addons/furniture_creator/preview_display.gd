@tool
extends Control

## Custom preview control that renders the sprite at display scale
## and overlays the collision rectangle.

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
