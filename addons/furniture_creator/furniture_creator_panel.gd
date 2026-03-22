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

# --- Atlas picker ---
var _atlas_picker: Control  # AtlasRegionPicker instance


func _ready() -> void:
	var form_container: VBoxContainer = %FormContainer if has_node("%FormContainer") else $HSplit/LeftPanel/FormScroll/FormContainer
	_build_form(form_container)


func _build_form(container: VBoxContainer) -> void:
	# --- Sprite Source: From Atlas ---
	_add_section_header(container, "From Atlas")

	_atlas_picker = VBoxContainer.new()
	_atlas_picker.set_script(load("res://addons/furniture_creator/atlas_region_picker.gd"))
	container.add_child(_atlas_picker)

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

	_add_field_row(container, "Display Scale", scale_hbox)


# --- Signal handlers ---

func _on_display_name_changed(new_text: String) -> void:
	if not _id_manually_edited:
		_id_edit.text = _to_snake_case(new_text)


func _on_id_manually_changed(_new_text: String) -> void:
	_id_manually_edited = true


func _on_walkable_toggled(pressed: bool) -> void:
	_walk_surface_y_offset_row.visible = pressed


func _on_interaction_type_changed(index: int) -> void:
	var is_interactive := index != 0
	_interaction_coin_bonus_row.visible = is_interactive
	_interaction_cooldown_row.visible = is_interactive


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
