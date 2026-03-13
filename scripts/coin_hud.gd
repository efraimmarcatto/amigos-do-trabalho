extends PanelContainer

## Styled coin HUD displaying a coin icon and animated counter.
## Positioned to the left of the menu toggle button at the bottom-right.

var _label: Label
var _count_tween: Tween
var _pos_tween: Tween
var _displayed_value: int = 0
var _base_position: Vector2 = Vector2.ZERO
var _menu_panel_height: float = 160.0

const ANIM_DURATION: float = 0.3
const ICON_SIZE: int = 16
const HUD_MARGIN: float = 8.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func _build_ui() -> void:
	# Style: white/light background with rounded corners
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	# Coin icon (yellow circle placeholder)
	var icon := TextureRect.new()
	var img := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(float(ICON_SIZE) / 2.0, float(ICON_SIZE) / 2.0)
	var radius := float(ICON_SIZE) / 2.0
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			var dist := Vector2(float(x), float(y)).distance_to(center)
			if dist <= radius:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.0, 1.0))
			else:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	icon.texture = ImageTexture.create_from_image(img)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	hbox.add_child(icon)

	# Coin count label
	_label = Label.new()
	_label.text = "0"
	_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15, 1.0))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hbox.add_child(_label)


func setup(floor_y: float, toggle_x: float, toggle_w: float, menu_panel_h: float) -> void:
	## Position the HUD to the left of the toggle button.
	_menu_panel_height = menu_panel_h
	# Force a layout pass so size is computed
	await get_tree().process_frame
	var hud_w := size.x
	var hud_h := size.y
	_base_position = Vector2(
		toggle_x - hud_w - HUD_MARGIN,
		floor_y - hud_h - 10.0
	)
	position = _base_position


func update_coins(new_total: int) -> void:
	## Animate the counter from current displayed value to new_total.
	var old_value := _displayed_value
	_displayed_value = new_total
	if _count_tween and _count_tween.is_running():
		_count_tween.kill()
	if old_value == new_total:
		_label.text = str(new_total)
		return
	_count_tween = create_tween()
	_count_tween.tween_method(_set_label_value, float(old_value), float(new_total), ANIM_DURATION)


func _set_label_value(value: float) -> void:
	_label.text = str(int(value))


func animate_up() -> void:
	## Move coin HUD upward when menu opens.
	var target := Vector2(_base_position.x, _base_position.y - _menu_panel_height - 10.0)
	if _pos_tween and _pos_tween.is_running():
		_pos_tween.kill()
	_pos_tween = create_tween()
	_pos_tween.tween_property(self, "position", target, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)


func animate_down() -> void:
	## Move coin HUD back to original position when menu closes.
	if _pos_tween and _pos_tween.is_running():
		_pos_tween.kill()
	_pos_tween = create_tween()
	_pos_tween.tween_property(self, "position", _base_position, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)


func get_rect() -> Rect2:
	## Returns the global rect of the coin HUD for passthrough polygon.
	return Rect2(global_position, size)
