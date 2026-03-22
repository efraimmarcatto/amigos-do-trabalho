@tool
extends Control

## Main panel for the Furniture Creator plugin.
## Provides a form-based UI for creating and editing FurnitureData resources.

# --- Form field references ---
var _display_name_edit: LineEdit
var _id_edit: LineEdit
var _id_manually_edited: bool = false

var _coin_cost_spin: SpinBox
var _discard_refund_spin: SpinBox
var _refund_label: Label

var _walkable_check: CheckBox
var _walk_surface_y_offset_spin: SpinBox
var _walk_surface_y_offset_row: Control
var _can_fall_off_edge_check: CheckBox
var _jumpable_check: CheckBox
var _stackable_check: CheckBox
var _interaction_type_option: OptionButton
var _interaction_coin_bonus_spin: SpinBox
var _interaction_coin_bonus_row: Control
var _interaction_cooldown_spin: SpinBox
var _interaction_cooldown_row: Control

var _display_scale_x_spin: SpinBox
var _display_scale_y_spin: SpinBox

# --- Sprite source pickers ---
var _atlas_picker: Control  # AtlasRegionPicker instance
var _file_picker: Control   # ImageFilePicker instance
var _sprite_tabs: TabContainer

# --- Collision controls ---
var _custom_collision_check: CheckBox
var _collision_auto_label: Label
var _collision_width_spin: SpinBox
var _collision_height_spin: SpinBox
var _collision_offset_x_spin: SpinBox
var _collision_offset_y_spin: SpinBox
var _collision_size_row: Control
var _collision_offset_row: Control

# --- Standing area controls ---
var _custom_standing_check: CheckBox
var _standing_auto_label: Label
var _standing_width_spin: SpinBox
var _standing_height_spin: SpinBox
var _standing_offset_x_spin: SpinBox
var _standing_offset_y_spin: SpinBox
var _standing_size_row: Control
var _standing_offset_row: Control

# --- Load/Save ---
var _load_button: Button
var _new_button: Button
var _save_button: Button
var _error_label: Label
var _loaded_path: String = ""  # Tracks the file path of the loaded resource

# --- Preview ---
var _preview_display: Control  # PreviewDisplay instance
var _preview_placeholder: Label
var _preview_scroll: ScrollContainer


func _ready() -> void:
	var form_container: VBoxContainer = %FormContainer if has_node("%FormContainer") else $HSplit/LeftPanel/FormScroll/FormContainer
	_build_form(form_container)
	_build_preview()


func _build_form(container: VBoxContainer) -> void:
	# --- Load / New buttons at the top ---
	var action_row := HBoxContainer.new()
	_load_button = Button.new()
	_load_button.text = "Load"
	_load_button.pressed.connect(_on_load_pressed)
	_load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_load_button)
	_new_button = Button.new()
	_new_button.text = "New"
	_new_button.pressed.connect(_on_new_pressed)
	_new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_new_button)
	container.add_child(action_row)

	_add_separator(container)

	# --- Sprite Source: Tabbed Atlas / File pickers ---
	_add_section_header(container, "Sprite Source")

	_sprite_tabs = TabContainer.new()
	_sprite_tabs.custom_minimum_size.y = 300
	_sprite_tabs.tab_changed.connect(_on_sprite_tab_changed)

	_atlas_picker = VBoxContainer.new()
	_atlas_picker.name = "From Atlas"
	_atlas_picker.set_script(load("res://addons/furniture_creator/atlas_region_picker.gd"))
	_sprite_tabs.add_child(_atlas_picker)

	_file_picker = VBoxContainer.new()
	_file_picker.name = "From File"
	_file_picker.set_script(load("res://addons/furniture_creator/image_file_picker.gd"))
	_sprite_tabs.add_child(_file_picker)

	container.add_child(_sprite_tabs)

	_add_separator(container)

	# --- Identity Section ---
	_add_section_header(container, "Identity")

	_display_name_edit = LineEdit.new()
	_display_name_edit.placeholder_text = "e.g. Cozy Sofa"
	_display_name_edit.text_changed.connect(_on_display_name_changed)
	_add_field_row(container, "Display Name", _display_name_edit)

	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "auto-generated from name"
	_id_edit.text_changed.connect(_on_id_manually_changed)
	_add_field_row(container, "ID", _id_edit)

	_add_separator(container)

	# --- Economics Section ---
	_add_section_header(container, "Economics")

	_coin_cost_spin = SpinBox.new()
	_coin_cost_spin.min_value = 0
	_coin_cost_spin.max_value = 99999
	_coin_cost_spin.step = 1
	_coin_cost_spin.value = 0
	_coin_cost_spin.value_changed.connect(_on_coin_cost_changed)
	_add_field_row(container, "Coin Cost", _coin_cost_spin)

	var refund_hbox := HBoxContainer.new()
	_discard_refund_spin = SpinBox.new()
	_discard_refund_spin.min_value = 0.0
	_discard_refund_spin.max_value = 1.0
	_discard_refund_spin.step = 0.05
	_discard_refund_spin.value = 0.5
	_discard_refund_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_discard_refund_spin.value_changed.connect(_on_refund_ratio_changed)
	refund_hbox.add_child(_discard_refund_spin)

	_refund_label = Label.new()
	_refund_label.text = "Refund: 0 coins"
	refund_hbox.add_child(_refund_label)

	_add_field_row(container, "Discard Refund Ratio", refund_hbox)

	_add_separator(container)

	# --- Behavior Section ---
	_add_section_header(container, "Behavior")

	_walkable_check = CheckBox.new()
	_walkable_check.toggled.connect(_on_walkable_toggled)
	_add_field_row(container, "Walkable", _walkable_check)

	_walk_surface_y_offset_spin = SpinBox.new()
	_walk_surface_y_offset_spin.min_value = -9999
	_walk_surface_y_offset_spin.max_value = 9999
	_walk_surface_y_offset_spin.step = 1
	_walk_surface_y_offset_spin.value = 0
	_walk_surface_y_offset_row = _add_field_row(container, "Walk Surface Y Offset", _walk_surface_y_offset_spin)
	_walk_surface_y_offset_row.visible = false

	# --- Custom Standing Area (visible only when Walkable is checked) ---
	_custom_standing_check = CheckBox.new()
	_custom_standing_check.toggled.connect(_on_custom_standing_toggled)
	var _custom_standing_row := _add_field_row(container, "Custom Standing Area", _custom_standing_check)
	_custom_standing_row.name = "CustomStandingRow"

	_standing_auto_label = Label.new()
	_standing_auto_label.text = "Auto-calculated from texture × scale"
	_standing_auto_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_standing_auto_label.name = "StandingAutoLabel"
	container.add_child(_standing_auto_label)

	var stand_size_hbox := HBoxContainer.new()
	var sw_label := Label.new()
	sw_label.text = "W:"
	stand_size_hbox.add_child(sw_label)
	_standing_width_spin = SpinBox.new()
	_standing_width_spin.min_value = 1
	_standing_width_spin.max_value = 9999
	_standing_width_spin.step = 1
	_standing_width_spin.value = 64
	_standing_width_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_width_spin.value_changed.connect(_on_standing_param_changed)
	stand_size_hbox.add_child(_standing_width_spin)
	var sh_label := Label.new()
	sh_label.text = "H:"
	stand_size_hbox.add_child(sh_label)
	_standing_height_spin = SpinBox.new()
	_standing_height_spin.min_value = 1
	_standing_height_spin.max_value = 9999
	_standing_height_spin.step = 1
	_standing_height_spin.value = 64
	_standing_height_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_height_spin.value_changed.connect(_on_standing_param_changed)
	stand_size_hbox.add_child(_standing_height_spin)
	_standing_size_row = _add_field_row(container, "Standing Size", stand_size_hbox)
	_standing_size_row.visible = false

	var stand_offset_hbox := HBoxContainer.new()
	var sox_label := Label.new()
	sox_label.text = "X:"
	stand_offset_hbox.add_child(sox_label)
	_standing_offset_x_spin = SpinBox.new()
	_standing_offset_x_spin.min_value = -9999
	_standing_offset_x_spin.max_value = 9999
	_standing_offset_x_spin.step = 1
	_standing_offset_x_spin.value = 0
	_standing_offset_x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_offset_x_spin.value_changed.connect(_on_standing_param_changed)
	stand_offset_hbox.add_child(_standing_offset_x_spin)
	var soy_label := Label.new()
	soy_label.text = "Y:"
	stand_offset_hbox.add_child(soy_label)
	_standing_offset_y_spin = SpinBox.new()
	_standing_offset_y_spin.min_value = -9999
	_standing_offset_y_spin.max_value = 9999
	_standing_offset_y_spin.step = 1
	_standing_offset_y_spin.value = 0
	_standing_offset_y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_offset_y_spin.value_changed.connect(_on_standing_param_changed)
	stand_offset_hbox.add_child(_standing_offset_y_spin)
	_standing_offset_row = _add_field_row(container, "Standing Offset", stand_offset_hbox)
	_standing_offset_row.visible = false

	# Hide standing area controls initially (shown when Walkable is checked)
	_custom_standing_row.visible = false
	_standing_auto_label.visible = false

	_can_fall_off_edge_check = CheckBox.new()
	_can_fall_off_edge_check.button_pressed = true
	_add_field_row(container, "Can Fall Off Edge", _can_fall_off_edge_check)

	_jumpable_check = CheckBox.new()
	_add_field_row(container, "Jumpable", _jumpable_check)

	_stackable_check = CheckBox.new()
	_add_field_row(container, "Stackable", _stackable_check)

	_interaction_type_option = OptionButton.new()
	_interaction_type_option.add_item("(none)", 0)
	_interaction_type_option.add_item("play", 1)
	_interaction_type_option.add_item("eat", 2)
	_interaction_type_option.add_item("sleep", 3)
	_interaction_type_option.item_selected.connect(_on_interaction_type_changed)
	_add_field_row(container, "Interaction Type", _interaction_type_option)

	_interaction_coin_bonus_spin = SpinBox.new()
	_interaction_coin_bonus_spin.min_value = 0
	_interaction_coin_bonus_spin.max_value = 99999
	_interaction_coin_bonus_spin.step = 1
	_interaction_coin_bonus_spin.value = 0
	_interaction_coin_bonus_row = _add_field_row(container, "Interaction Coin Bonus", _interaction_coin_bonus_spin)
	_interaction_coin_bonus_row.visible = false

	_interaction_cooldown_spin = SpinBox.new()
	_interaction_cooldown_spin.min_value = 0.0
	_interaction_cooldown_spin.max_value = 3600.0
	_interaction_cooldown_spin.step = 0.5
	_interaction_cooldown_spin.value = 0.0
	_interaction_cooldown_spin.suffix = "s"
	_interaction_cooldown_row = _add_field_row(container, "Interaction Cooldown", _interaction_cooldown_spin)
	_interaction_cooldown_row.visible = false

	_add_separator(container)

	# --- Visual Section ---
	_add_section_header(container, "Visual")

	var scale_hbox := HBoxContainer.new()
	var x_label := Label.new()
	x_label.text = "X:"
	scale_hbox.add_child(x_label)
	_display_scale_x_spin = SpinBox.new()
	_display_scale_x_spin.min_value = 0.1
	_display_scale_x_spin.max_value = 100.0
	_display_scale_x_spin.step = 0.5
	_display_scale_x_spin.value = 4.0
	_display_scale_x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_hbox.add_child(_display_scale_x_spin)

	var y_label := Label.new()
	y_label.text = "Y:"
	scale_hbox.add_child(y_label)
	_display_scale_y_spin = SpinBox.new()
	_display_scale_y_spin.min_value = 0.1
	_display_scale_y_spin.max_value = 100.0
	_display_scale_y_spin.step = 0.5
	_display_scale_y_spin.value = 4.0
	_display_scale_y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_hbox.add_child(_display_scale_y_spin)

	_display_scale_x_spin.value_changed.connect(_on_display_scale_changed)
	_display_scale_y_spin.value_changed.connect(_on_display_scale_changed)

	_add_field_row(container, "Display Scale", scale_hbox)

	# --- Custom Collision ---
	_custom_collision_check = CheckBox.new()
	_custom_collision_check.toggled.connect(_on_custom_collision_toggled)
	_add_field_row(container, "Custom Collision", _custom_collision_check)

	_collision_auto_label = Label.new()
	_collision_auto_label.text = "Auto-calculated from texture × scale"
	_collision_auto_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	container.add_child(_collision_auto_label)

	var col_size_hbox := HBoxContainer.new()
	var cw_label := Label.new()
	cw_label.text = "W:"
	col_size_hbox.add_child(cw_label)
	_collision_width_spin = SpinBox.new()
	_collision_width_spin.min_value = 1
	_collision_width_spin.max_value = 9999
	_collision_width_spin.step = 1
	_collision_width_spin.value = 64
	_collision_width_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collision_width_spin.value_changed.connect(_on_collision_param_changed)
	col_size_hbox.add_child(_collision_width_spin)
	var ch_label := Label.new()
	ch_label.text = "H:"
	col_size_hbox.add_child(ch_label)
	_collision_height_spin = SpinBox.new()
	_collision_height_spin.min_value = 1
	_collision_height_spin.max_value = 9999
	_collision_height_spin.step = 1
	_collision_height_spin.value = 64
	_collision_height_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collision_height_spin.value_changed.connect(_on_collision_param_changed)
	col_size_hbox.add_child(_collision_height_spin)
	_collision_size_row = _add_field_row(container, "Collision Size", col_size_hbox)
	_collision_size_row.visible = false

	var col_offset_hbox := HBoxContainer.new()
	var cox_label := Label.new()
	cox_label.text = "X:"
	col_offset_hbox.add_child(cox_label)
	_collision_offset_x_spin = SpinBox.new()
	_collision_offset_x_spin.min_value = -9999
	_collision_offset_x_spin.max_value = 9999
	_collision_offset_x_spin.step = 1
	_collision_offset_x_spin.value = 0
	_collision_offset_x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collision_offset_x_spin.value_changed.connect(_on_collision_param_changed)
	col_offset_hbox.add_child(_collision_offset_x_spin)
	var coy_label := Label.new()
	coy_label.text = "Y:"
	col_offset_hbox.add_child(coy_label)
	_collision_offset_y_spin = SpinBox.new()
	_collision_offset_y_spin.min_value = -9999
	_collision_offset_y_spin.max_value = 9999
	_collision_offset_y_spin.step = 1
	_collision_offset_y_spin.value = 0
	_collision_offset_y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_collision_offset_y_spin.value_changed.connect(_on_collision_param_changed)
	col_offset_hbox.add_child(_collision_offset_y_spin)
	_collision_offset_row = _add_field_row(container, "Collision Offset", col_offset_hbox)
	_collision_offset_row.visible = false

	_add_separator(container)

	# --- Save Section ---
	_error_label = Label.new()
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.visible = false
	container.add_child(_error_label)

	_save_button = Button.new()
	_save_button.text = "Save"
	_save_button.pressed.connect(_on_save_pressed)
	container.add_child(_save_button)


func _build_preview() -> void:
	var preview_area: Panel = $HSplit/RightPanel/PreviewArea

	# Placeholder label shown when no sprite is selected
	_preview_placeholder = Label.new()
	_preview_placeholder.text = "No sprite selected.\nSelect a sprite from the form to preview."
	_preview_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview_placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_area.add_child(_preview_placeholder)

	# Scrollable preview for the scaled sprite with collision overlay
	_preview_scroll = ScrollContainer.new()
	_preview_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_scroll.visible = false
	preview_area.add_child(_preview_scroll)

	_preview_display = Control.new()
	_preview_display.set_script(load("res://addons/furniture_creator/preview_display.gd"))
	_preview_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_scroll.add_child(_preview_display)

	# Connect picker signals for live preview updates
	if _atlas_picker:
		_atlas_picker.atlas_texture_changed.connect(_on_sprite_changed)
		_atlas_picker.region_changed.connect(func(_r: Rect2) -> void: _update_preview())
	if _file_picker:
		_file_picker.texture_changed.connect(_on_sprite_changed)


# --- Signal handlers ---

func _on_display_name_changed(new_text: String) -> void:
	if not _id_manually_edited:
		_id_edit.text = _to_snake_case(new_text)


func _on_id_manually_changed(_new_text: String) -> void:
	_id_manually_edited = true


func _on_walkable_toggled(pressed: bool) -> void:
	_walk_surface_y_offset_row.visible = pressed
	# Show/hide standing area controls based on walkable state
	var standing_row := _custom_standing_check.get_parent()
	standing_row.visible = pressed
	if pressed:
		_standing_auto_label.visible = not _custom_standing_check.button_pressed
	else:
		_standing_auto_label.visible = false
		_standing_size_row.visible = false
		_standing_offset_row.visible = false


func _on_interaction_type_changed(index: int) -> void:
	var is_interactive := index != 0
	_interaction_coin_bonus_row.visible = is_interactive
	_interaction_cooldown_row.visible = is_interactive


func _on_sprite_tab_changed(tab: int) -> void:
	# Clear the other tab's selection when switching
	if tab == 0:
		# Switched to "From Atlas" — clear file picker
		if _file_picker and _file_picker.has_method("clear"):
			_file_picker.clear()
	elif tab == 1:
		# Switched to "From File" — clear atlas picker
		if _atlas_picker and _atlas_picker.has_method("clear"):
			_atlas_picker.clear()
	_update_preview()


func _on_sprite_changed(_texture: Variant) -> void:
	_update_preview()


func _on_display_scale_changed(_value: float) -> void:
	_update_preview()


func _update_preview() -> void:
	var tex := get_selected_texture()
	if tex == null:
		_preview_placeholder.visible = true
		_preview_scroll.visible = false
		return

	_preview_placeholder.visible = false
	_preview_scroll.visible = true

	var scale := get_display_scale()
	var col_size := get_collision_size()
	var col_offset := get_collision_offset()
	var stand_size := get_standing_size()
	var stand_offset := get_standing_offset()

	_preview_display.update_preview(tex, scale, col_size, col_offset, stand_size, stand_offset)

	# Update auto-calculated labels
	if tex:
		var auto_size := tex.get_size() * scale
		if _collision_auto_label:
			_collision_auto_label.text = "Auto: %d × %d px" % [int(auto_size.x), int(auto_size.y)]
		if _standing_auto_label:
			_standing_auto_label.text = "Auto: %d × %d px" % [int(auto_size.x), int(auto_size.y)]


func _on_custom_collision_toggled(pressed: bool) -> void:
	_collision_auto_label.visible = not pressed
	_collision_size_row.visible = pressed
	_collision_offset_row.visible = pressed
	if pressed:
		# Pre-fill with auto-calculated values
		var tex := get_selected_texture()
		if tex:
			var auto_size := tex.get_size() * get_display_scale()
			_collision_width_spin.value = auto_size.x
			_collision_height_spin.value = auto_size.y
	_update_preview()


func _on_collision_param_changed(_value: float) -> void:
	_update_preview()


func _on_custom_standing_toggled(pressed: bool) -> void:
	_standing_auto_label.visible = not pressed
	_standing_size_row.visible = pressed
	_standing_offset_row.visible = pressed
	if pressed:
		# Pre-fill with auto-calculated values
		var tex := get_selected_texture()
		if tex:
			var auto_size := tex.get_size() * get_display_scale()
			_standing_width_spin.value = auto_size.x
			_standing_height_spin.value = auto_size.y
	_update_preview()


func _on_standing_param_changed(_value: float) -> void:
	_update_preview()


func _on_coin_cost_changed(_value: float) -> void:
	_update_refund_label()


func _on_refund_ratio_changed(_value: float) -> void:
	_update_refund_label()


func _update_refund_label() -> void:
	var refund := int(_coin_cost_spin.value * _discard_refund_spin.value)
	_refund_label.text = "Refund: %d coins" % refund


# --- Helpers ---

func _to_snake_case(text: String) -> String:
	var result := text.strip_edges().to_lower()
	result = result.replace(" ", "_")
	# Remove non-alphanumeric characters except underscores
	var cleaned := ""
	for c in result:
		if c == "_" or (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			cleaned += c
	# Collapse multiple underscores
	while cleaned.contains("__"):
		cleaned = cleaned.replace("__", "_")
	return cleaned.strip_edges()


func _add_section_header(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
	return label


func _add_separator(parent: Control) -> HSeparator:
	var sep := HSeparator.new()
	parent.add_child(sep)
	return sep


func _add_field_row(parent: Control, label_text: String, field: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 180
	row.add_child(label)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	parent.add_child(row)
	return row


## Returns the current display_scale as a Vector2.
func get_display_scale() -> Vector2:
	return Vector2(_display_scale_x_spin.value, _display_scale_y_spin.value)


## Returns the atlas texture from the atlas picker, or null.
func get_atlas_texture() -> AtlasTexture:
	if _atlas_picker and _atlas_picker.has_method("get_atlas_texture"):
		return _atlas_picker.get_atlas_texture()
	return null


## Returns the standalone file texture from the file picker, or null.
func get_file_texture() -> Texture2D:
	if _file_picker and _file_picker.has_method("get_texture"):
		return _file_picker.get_texture()
	return null


## Returns whichever texture is currently selected (atlas or file), or null.
func get_selected_texture() -> Texture2D:
	if _sprite_tabs.current_tab == 0:
		return get_atlas_texture()
	else:
		return get_file_texture()


## Returns the current sprite source mode: "atlas" or "file".
func get_sprite_source_mode() -> String:
	return "atlas" if _sprite_tabs.current_tab == 0 else "file"


## Returns the collision size override (Vector2.ZERO if auto).
func get_collision_size() -> Vector2:
	if _custom_collision_check and _custom_collision_check.button_pressed:
		return Vector2(_collision_width_spin.value, _collision_height_spin.value)
	return Vector2.ZERO


## Returns the collision offset.
func get_collision_offset() -> Vector2:
	if _custom_collision_check and _custom_collision_check.button_pressed:
		return Vector2(_collision_offset_x_spin.value, _collision_offset_y_spin.value)
	return Vector2.ZERO


## Returns the standing size override (Vector2.ZERO if auto/unchecked).
func get_standing_size() -> Vector2:
	if _custom_standing_check and _custom_standing_check.button_pressed:
		return Vector2(_standing_width_spin.value, _standing_height_spin.value)
	return Vector2.ZERO


## Returns the standing offset.
func get_standing_offset() -> Vector2:
	if _custom_standing_check and _custom_standing_check.button_pressed:
		return Vector2(_standing_offset_x_spin.value, _standing_offset_y_spin.value)
	return Vector2.ZERO


# --- Save ---

func _on_save_pressed() -> void:
	_error_label.visible = false

	# Validate required fields
	var item_id := _id_edit.text.strip_edges()
	var item_name := _display_name_edit.text.strip_edges()
	var tex := get_selected_texture()

	var errors: PackedStringArray = []
	if item_id.is_empty():
		errors.append("ID is required")
	if item_name.is_empty():
		errors.append("Display Name is required")
	if tex == null:
		errors.append("A texture must be selected")

	if errors.size() > 0:
		_error_label.text = "Error: " + ", ".join(errors)
		_error_label.visible = true
		return

	var save_path := "res://furniture/data/" + item_id + ".tres"

	# Check if file exists (including re-saving loaded file) — show confirmation dialog
	if FileAccess.file_exists(save_path):
		var dialog := ConfirmationDialog.new()
		dialog.dialog_text = "File '%s' already exists. Overwrite?" % save_path
		dialog.confirmed.connect(func():
			_do_save(save_path)
			dialog.queue_free()
		)
		dialog.canceled.connect(func(): dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered()
		return

	_do_save(save_path)


func _do_save(save_path: String) -> void:
	var data := FurnitureData.new()
	data.id = _id_edit.text.strip_edges()
	data.display_name = _display_name_edit.text.strip_edges()
	data.coin_cost = int(_coin_cost_spin.value)
	data.discard_refund_ratio = _discard_refund_spin.value
	data.walkable = _walkable_check.button_pressed
	data.walk_surface_y_offset = int(_walk_surface_y_offset_spin.value)
	data.can_fall_off_edge = _can_fall_off_edge_check.button_pressed
	data.jumpable = _jumpable_check.button_pressed
	data.stackable = _stackable_check.button_pressed
	data.display_scale = get_display_scale()

	# Interaction
	var interaction_idx := _interaction_type_option.selected
	match interaction_idx:
		1: data.interaction_type = "play"
		2: data.interaction_type = "eat"
		3: data.interaction_type = "sleep"
		_: data.interaction_type = ""
	data.interaction_coin_bonus = int(_interaction_coin_bonus_spin.value)
	data.interaction_cooldown = _interaction_cooldown_spin.value

	# Texture
	if get_sprite_source_mode() == "atlas":
		data.texture = get_atlas_texture()
	else:
		data.texture = get_file_texture()

	# Collision overrides
	data.collision_size_override = get_collision_size()
	data.collision_offset = get_collision_offset()

	# Standing area overrides
	data.standing_size_override = get_standing_size()
	data.standing_offset = get_standing_offset()

	var err := ResourceSaver.save(data, save_path)
	if err != OK:
		_error_label.text = "Error saving: error code %d" % err
		_error_label.visible = true
		return

	# Refresh the editor filesystem so the file appears
	var efs := EditorInterface.get_resource_filesystem()
	if efs:
		efs.scan()

	_loaded_path = save_path
	_error_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	_error_label.text = "Saved to %s" % save_path
	_error_label.visible = true
	# Reset color after showing success
	await get_tree().create_timer(3.0).timeout
	_error_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_error_label.visible = false


# --- Load / New ---

func _on_load_pressed() -> void:
	var dialog := EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.filters = PackedStringArray(["*.tres ; Resource Files"])
	dialog.current_dir = "res://furniture/data/"
	dialog.file_selected.connect(_on_load_file_selected)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))


func _on_load_file_selected(path: String) -> void:
	# Clean up dialog
	for child in get_children():
		if child is EditorFileDialog:
			child.queue_free()

	var res := load(path)
	if not res is FurnitureData:
		_error_label.text = "Error: Selected file is not a FurnitureData resource"
		_error_label.visible = true
		return

	_load_furniture_data(res as FurnitureData, path)


func _load_furniture_data(data: FurnitureData, path: String) -> void:
	_loaded_path = path

	# Identity
	_id_manually_edited = true  # Prevent auto-generation from overwriting loaded id
	_display_name_edit.text = data.display_name
	_id_edit.text = data.id

	# Economics
	_coin_cost_spin.value = data.coin_cost
	_discard_refund_spin.value = data.discard_refund_ratio
	_update_refund_label()

	# Behavior
	_walkable_check.button_pressed = data.walkable
	_walk_surface_y_offset_row.visible = data.walkable
	_walk_surface_y_offset_spin.value = data.walk_surface_y_offset
	_can_fall_off_edge_check.button_pressed = data.can_fall_off_edge
	_jumpable_check.button_pressed = data.jumpable
	_stackable_check.button_pressed = data.stackable

	# Interaction
	match data.interaction_type:
		"play": _interaction_type_option.select(1)
		"eat": _interaction_type_option.select(2)
		"sleep": _interaction_type_option.select(3)
		_: _interaction_type_option.select(0)
	var is_interactive := _interaction_type_option.selected != 0
	_interaction_coin_bonus_row.visible = is_interactive
	_interaction_cooldown_row.visible = is_interactive
	_interaction_coin_bonus_spin.value = data.interaction_coin_bonus
	_interaction_cooldown_spin.value = data.interaction_cooldown

	# Visual
	_display_scale_x_spin.value = data.display_scale.x
	_display_scale_y_spin.value = data.display_scale.y

	# Texture — detect atlas vs standalone
	if data.texture is AtlasTexture:
		var atlas_tex := data.texture as AtlasTexture
		_sprite_tabs.current_tab = 0
		if _atlas_picker.has_method("set_atlas") and atlas_tex.atlas:
			_atlas_picker.set_atlas(atlas_tex.atlas.resource_path, atlas_tex.region)
		if _file_picker.has_method("clear"):
			_file_picker.clear()
	elif data.texture != null:
		_sprite_tabs.current_tab = 1
		if _file_picker.has_method("set_texture_from_path"):
			_file_picker.set_texture_from_path(data.texture.resource_path)
		if _atlas_picker.has_method("clear"):
			_atlas_picker.clear()

	# Collision overrides
	if data.collision_size_override != Vector2.ZERO:
		_custom_collision_check.button_pressed = true
		_collision_auto_label.visible = false
		_collision_size_row.visible = true
		_collision_offset_row.visible = true
		_collision_width_spin.value = data.collision_size_override.x
		_collision_height_spin.value = data.collision_size_override.y
		_collision_offset_x_spin.value = data.collision_offset.x
		_collision_offset_y_spin.value = data.collision_offset.y
	else:
		_custom_collision_check.button_pressed = false
		_collision_auto_label.visible = true
		_collision_size_row.visible = false
		_collision_offset_row.visible = false

	# Standing area overrides (only relevant when walkable)
	var standing_row := _custom_standing_check.get_parent()
	if data.walkable:
		standing_row.visible = true
		if data.standing_size_override != Vector2.ZERO:
			_custom_standing_check.button_pressed = true
			_standing_auto_label.visible = false
			_standing_size_row.visible = true
			_standing_offset_row.visible = true
			_standing_width_spin.value = data.standing_size_override.x
			_standing_height_spin.value = data.standing_size_override.y
			_standing_offset_x_spin.value = data.standing_offset.x
			_standing_offset_y_spin.value = data.standing_offset.y
		else:
			_custom_standing_check.button_pressed = false
			_standing_auto_label.visible = true
			_standing_size_row.visible = false
			_standing_offset_row.visible = false
	else:
		standing_row.visible = false
		_standing_auto_label.visible = false
		_custom_standing_check.button_pressed = false
		_standing_size_row.visible = false
		_standing_offset_row.visible = false

	_update_preview()

	_error_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	_error_label.text = "Loaded: %s" % path
	_error_label.visible = true


func _on_new_pressed() -> void:
	_reset_form()


func _reset_form() -> void:
	_loaded_path = ""
	_id_manually_edited = false

	# Identity
	_display_name_edit.text = ""
	_id_edit.text = ""

	# Economics
	_coin_cost_spin.value = 0
	_discard_refund_spin.value = 0.5
	_update_refund_label()

	# Behavior
	_walkable_check.button_pressed = false
	_walk_surface_y_offset_row.visible = false
	_walk_surface_y_offset_spin.value = 0
	_can_fall_off_edge_check.button_pressed = true
	_jumpable_check.button_pressed = false
	_stackable_check.button_pressed = false

	# Interaction
	_interaction_type_option.select(0)
	_interaction_coin_bonus_row.visible = false
	_interaction_cooldown_row.visible = false
	_interaction_coin_bonus_spin.value = 0
	_interaction_cooldown_spin.value = 0.0

	# Visual
	_display_scale_x_spin.value = 4.0
	_display_scale_y_spin.value = 4.0

	# Collision
	_custom_collision_check.button_pressed = false
	_collision_auto_label.visible = true
	_collision_size_row.visible = false
	_collision_offset_row.visible = false

	# Standing area
	_custom_standing_check.button_pressed = false
	var standing_row := _custom_standing_check.get_parent()
	standing_row.visible = false
	_standing_auto_label.visible = false
	_standing_size_row.visible = false
	_standing_offset_row.visible = false
	_standing_width_spin.value = 64
	_standing_height_spin.value = 64
	_standing_offset_x_spin.value = 0
	_standing_offset_y_spin.value = 0

	# Sprite source
	_sprite_tabs.current_tab = 0
	if _atlas_picker.has_method("clear"):
		_atlas_picker.clear()
	if _file_picker.has_method("clear"):
		_file_picker.clear()

	_update_preview()

	_error_label.visible = false
