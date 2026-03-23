@tool
extends Control

## Custom drawing control that renders a sprite sheet with a selection overlay.
## Reads its state from metadata set by AtlasRegionPicker.


func _draw() -> void:
	var tex: Texture2D = get_meta("sheet_texture") if has_meta("sheet_texture") else null
	if tex == null:
		return

	var zoom: float = get_meta("zoom") if has_meta("zoom") else 1.0
	var region: Rect2 = get_meta("selected_region") if has_meta("selected_region") else Rect2()

	# Draw the sprite sheet scaled by zoom
	var tex_size := tex.get_size()
	var dest_rect := Rect2(Vector2.ZERO, tex_size * zoom)
	draw_texture_rect(tex, dest_rect, false)

	# Draw selection rectangle overlay
	var abs_region := region.abs()
	if abs_region.size != Vector2.ZERO:
		var overlay_rect := Rect2(abs_region.position * zoom, abs_region.size * zoom)
		# Semi-transparent fill
		draw_rect(overlay_rect, Color(0.2, 0.6, 1.0, 0.3), true)
		# Border
		draw_rect(overlay_rect, Color(0.2, 0.6, 1.0, 0.9), false, 2.0)
