@tool
extends VBoxContainer

## A control for selecting a region from a sprite sheet atlas.
## Displays the sprite sheet with click-drag selection and SpinBox fine-tuning.

signal region_changed(region: Rect2)
signal atlas_texture_changed(texture: AtlasTexture)

var _file_path_edit: LineEdit
var _browse_button: Button
var _sheet_scroll: ScrollContainer
var _sheet_display: Control
var _zoom_slider: HSlider
var _zoom_label: Label
var _region_x_spin: SpinBox
var _region_y_spin: SpinBox
var _region_w_spin: SpinBox
var _region_h_spin: SpinBox

var _sheet_texture: Texture2D = null
var _selected_region: Rect2 = Rect2()
var _is_dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _zoom: float = 1.0
var _updating_spinboxes: bool = false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# File picker row
	var file_row := HBoxContainer.new()
	var file_label := Label.new()
	file_label.text = "Atlas File"
	file_label.custom_minimum_size.x = 80
	file_row.add_child(file_label)

	_file_path_edit = LineEdit.new()
	_file_path_edit.placeholder_text = "res://assets/Top-Down_Retro_Interior/"
	_file_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_file_path_edit.editable = false
	file_row.add_child(_file_path_edit)

	_browse_button = Button.new()
	_browse_button.text = "Browse..."
	_browse_button.pressed.connect(_on_browse_pressed)
	file_row.add_child(_browse_button)
	add_child(file_row)

	# Zoom row
	var zoom_row := HBoxContainer.new()
	var zoom_text := Label.new()
	zoom_text.text = "Zoom"
	zoom_text.custom_minimum_size.x = 80
	zoom_row.add_child(zoom_text)

	_zoom_slider = HSlider.new()
	_zoom_slider.min_value = 0.5
	_zoom_slider.max_value = 8.0
	_zoom_slider.step = 0.5
	_zoom_slider.value = 1.0
	_zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zoom_slider.value_changed.connect(_on_zoom_changed)
	zoom_row.add_child(_zoom_slider)

	_zoom_label = Label.new()
	_zoom_label.text = "1.0x"
	_zoom_label.custom_minimum_size.x = 40
	zoom_row.add_child(_zoom_label)
	add_child(zoom_row)

	# Sprite sheet scrollable display area
	_sheet_scroll = ScrollContainer.new()
	_sheet_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sheet_scroll.custom_minimum_size.y = 200

	_sheet_display = Control.new()
	_sheet_display.set_script(load("res://addons/furniture_creator/atlas_sheet_display.gd"))
	_sheet_display.gui_input.connect(_on_sheet_gui_input)
	_sheet_scroll.add_child(_sheet_display)

	add_child(_sheet_scroll)

	# Region SpinBox fields
	var region_label := Label.new()
	region_label.text = "Selected Region"
	region_label.add_theme_font_size_override("font_size", 14)
	add_child(region_label)

	var region_grid := GridContainer.new()
	region_grid.columns = 4

	_region_x_spin = _create_region_spin("X:", region_grid)
	_region_y_spin = _create_region_spin("Y:", region_grid)
	_region_w_spin = _create_region_spin("W:", region_grid)
	_region_h_spin = _create_region_spin("H:", region_grid)

	add_child(region_grid)


func _create_region_spin(label_text: String, parent: Control) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)

	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 9999
	spin.step = 1
	spin.value = 0
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(_on_region_spin_changed)
	parent.add_child(spin)
	return spin


func _on_browse_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.filters = PackedStringArray(["*.png ; PNG Images"])
	dialog.current_dir = "res://assets/Top-Down_Retro_Interior/"
	dialog.file_selected.connect(_on_file_selected)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))


func _on_file_selected(path: String) -> void:
	# Clean up dialog
	for child in get_children():
		if child is EditorFileDialog:
			child.queue_free()

	_file_path_edit.text = path
	_sheet_texture = load(path)
	_selected_region = Rect2()
	_update_spinboxes_from_region()
	_update_sheet_display()
	_emit_changes()


func _on_zoom_changed(value: float) -> void:
	_zoom = value
	_zoom_label.text = "%.1fx" % value
	_update_sheet_display()


func _update_sheet_display() -> void:
	if _sheet_texture == null:
		_sheet_display.custom_minimum_size = Vector2.ZERO
		return

	var tex_size := _sheet_texture.get_size()
	_sheet_display.custom_minimum_size = tex_size * _zoom
	_sheet_display.set_meta("sheet_texture", _sheet_texture)
	_sheet_display.set_meta("zoom", _zoom)
	_sheet_display.set_meta("selected_region", _selected_region)
	_sheet_display.queue_redraw()


func _on_sheet_gui_input(event: InputEvent) -> void:
	if _sheet_texture == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_start = mb.position / _zoom
				_selected_region = Rect2(_drag_start, Vector2.ZERO)
				_update_spinboxes_from_region()
				_update_sheet_display()
			else:
				_is_dragging = false
				_normalize_region()
				_update_spinboxes_from_region()
				_update_sheet_display()
				_emit_changes()
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		var current := mm.position / _zoom
		# Clamp to texture bounds
		var tex_size := _sheet_texture.get_size()
		current = current.clamp(Vector2.ZERO, tex_size)
		var start_clamped := _drag_start.clamp(Vector2.ZERO, tex_size)
		_selected_region = Rect2(start_clamped, current - start_clamped)
		_update_spinboxes_from_region()
		_update_sheet_display()


func _normalize_region() -> void:
	# Ensure positive size
	var r := _selected_region.abs()
	# Round to integers for pixel-perfect selection
	r.position = Vector2(roundf(r.position.x), roundf(r.position.y))
	r.size = Vector2(roundf(r.size.x), roundf(r.size.y))
	_selected_region = r


func _update_spinboxes_from_region() -> void:
	_updating_spinboxes = true
	var r := _selected_region.abs()
	_region_x_spin.value = roundf(r.position.x)
	_region_y_spin.value = roundf(r.position.y)
	_region_w_spin.value = roundf(r.size.x)
	_region_h_spin.value = roundf(r.size.y)
	_updating_spinboxes = false


func _on_region_spin_changed(_value: float) -> void:
	if _updating_spinboxes:
		return
	_selected_region = Rect2(
		_region_x_spin.value,
		_region_y_spin.value,
		_region_w_spin.value,
		_region_h_spin.value
	)
	_update_sheet_display()
	_emit_changes()


func _emit_changes() -> void:
	region_changed.emit(_selected_region.abs())
	if _sheet_texture and _selected_region.abs().size != Vector2.ZERO:
		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = _sheet_texture
		atlas_tex.region = _selected_region.abs()
		atlas_texture_changed.emit(atlas_tex)


## Returns the current atlas texture or null if no valid selection.
func get_atlas_texture() -> AtlasTexture:
	if _sheet_texture == null or _selected_region.abs().size == Vector2.ZERO:
		return null
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = _sheet_texture
	atlas_tex.region = _selected_region.abs()
	return atlas_tex


## Returns the selected region.
func get_region() -> Rect2:
	return _selected_region.abs()


## Returns the atlas source file path.
func get_atlas_path() -> String:
	return _file_path_edit.text


## Sets the atlas from an existing path and region (used when loading a .tres).
func set_atlas(path: String, region: Rect2) -> void:
	_file_path_edit.text = path
	_sheet_texture = load(path) if not path.is_empty() else null
	_selected_region = region
	_update_spinboxes_from_region()
	_update_sheet_display()
	_emit_changes()


## Clears the atlas selection.
func clear() -> void:
	_file_path_edit.text = ""
	_sheet_texture = null
	_selected_region = Rect2()
	_update_spinboxes_from_region()
	_update_sheet_display()
