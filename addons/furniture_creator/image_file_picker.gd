@tool
extends VBoxContainer

## A control for selecting a standalone image file as a texture.

signal texture_changed(texture: Texture2D)

var _file_path_edit: LineEdit
var _browse_button: Button
var _preview_rect: TextureRect
var _selected_texture: Texture2D = null


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# File picker row
	var file_row := HBoxContainer.new()
	var file_label := Label.new()
	file_label.text = "Image File"
	file_label.custom_minimum_size.x = 80
	file_row.add_child(file_label)

	_file_path_edit = LineEdit.new()
	_file_path_edit.placeholder_text = "Select an image file..."
	_file_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_file_path_edit.editable = false
	file_row.add_child(_file_path_edit)

	_browse_button = Button.new()
	_browse_button.text = "Browse..."
	_browse_button.pressed.connect(_on_browse_pressed)
	file_row.add_child(_browse_button)
	add_child(file_row)

	# Image preview
	var preview_scroll := ScrollContainer.new()
	preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_scroll.custom_minimum_size.y = 150

	_preview_rect = TextureRect.new()
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP
	_preview_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_scroll.add_child(_preview_rect)

	add_child(preview_scroll)


func _on_browse_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.filters = PackedStringArray([
		"*.png ; PNG Images",
		"*.jpg ; JPEG Images",
		"*.svg ; SVG Images",
		"*.tres ; Resource Files",
	])
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
	_selected_texture = load(path)
	_preview_rect.texture = _selected_texture
	texture_changed.emit(_selected_texture)


## Returns the selected texture, or null if none.
func get_texture() -> Texture2D:
	return _selected_texture


## Returns the file path.
func get_file_path() -> String:
	return _file_path_edit.text


## Sets the texture from an existing path (used when loading a .tres).
func set_texture_from_path(path: String) -> void:
	_file_path_edit.text = path
	_selected_texture = load(path) if not path.is_empty() else null
	_preview_rect.texture = _selected_texture
	texture_changed.emit(_selected_texture)


## Clears the selection.
func clear() -> void:
	_file_path_edit.text = ""
	_selected_texture = null
	_preview_rect.texture = null
