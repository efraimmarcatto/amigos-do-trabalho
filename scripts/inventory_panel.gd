extends PanelContainer

## Inventory panel UI — view stored furniture, place items, and discard for partial refund.
## Panel slides in/out adjacent to the slide menu with tween animations.
## Items displayed as a responsive icon grid with quantity badges and hover tooltips.

signal inventory_closed
signal place_requested(furniture_id: String)

const ANIM_DURATION: float = 0.3
const PANEL_WIDTH: float = 280.0
const PANEL_HEIGHT: float = 300.0
const GAP: float = 5.0
const ICON_CELL_SIZE: float = 64.0
const ICON_SIZE: float = 48.0

var _coin_system: Node
var _inventory_system: Node
var _is_open: bool = false
var _open_x: float = 0.0
var _closed_x: float = 0.0
var _panel_tween: Tween
var _confirm_furniture_id: String = ""
var _action_popup: PanelContainer
var _selected_item_id: String = ""

@onready var _vbox: VBoxContainer = $VBox
@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _items_container: GridContainer = $VBox/ScrollContainer/Items
@onready var _confirm_dialog: ConfirmationDialog = $ConfirmDialog


func _ready() -> void:
	_coin_system = get_parent().get_node("CoinSystem")
	_inventory_system = get_parent().get_node("InventorySystem")
	_close_button.pressed.connect(close_panel)
	if _inventory_system:
		_inventory_system.inventory_changed.connect(_on_inventory_changed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Set up confirmation dialog
	_confirm_dialog.confirmed.connect(_on_discard_confirmed)
	_confirm_dialog.canceled.connect(func(): _confirm_furniture_id = "")

	_create_action_popup()


func setup(menu_open_x: float, menu_panel_y: float) -> void:
	## Position the inventory panel to slide in adjacent to the menu.
	var screen_w := float(DisplayServer.screen_get_size().x)
	custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	_open_x = menu_open_x - PANEL_WIDTH - GAP
	_closed_x = screen_w
	position = Vector2(_closed_x, menu_panel_y)


func open_panel() -> void:
	if _is_open:
		return
	_is_open = true
	_update_columns()
	_rebuild_items()
	_hide_action_popup()
	visible = true
	_animate_x(_open_x)


func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
	_hide_action_popup()
	_animate_x(_closed_x, true)
	inventory_closed.emit()


func is_panel_open() -> bool:
	return _is_open


func get_close_duration() -> float:
	return ANIM_DURATION


func get_furniture_data(furniture_id: String) -> FurnitureData:
	## Look up furniture data from catalog files.
	var path := "res://furniture/data/" + furniture_id + ".tres"
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is FurnitureData:
			return res as FurnitureData
	return null


func _animate_x(target_x: float, hide_after: bool = false) -> void:
	if _panel_tween and _panel_tween.is_running():
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(self, "position:x", target_x, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	if hide_after:
		_panel_tween.tween_callback(func(): visible = false)


func _update_columns() -> void:
	## Set grid columns based on available width.
	var available_w := PANEL_WIDTH - 20.0  # account for panel margins
	var cols := maxi(1, int(available_w / (ICON_CELL_SIZE + 4.0)))
	_items_container.columns = cols


func _rebuild_items() -> void:
	# Clear existing items
	for child in _items_container.get_children():
		child.queue_free()

	if not _inventory_system:
		return

	var inventory: Dictionary = _inventory_system.get_all_inventory()
	if inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No items in inventory"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_items_container.add_child(empty_label)
		return

	for furniture_id in inventory:
		var count: int = inventory[furniture_id]
		if count <= 0:
			continue

		var fdata := get_furniture_data(furniture_id)
		if not fdata:
			continue

		var cell := _create_grid_cell(fdata, count)
		_items_container.add_child(cell)


func _create_grid_cell(item: FurnitureData, count: int) -> Control:
	## Create a single grid cell with icon and quantity badge.
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(ICON_CELL_SIZE, ICON_CELL_SIZE + 16.0)
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.tooltip_text = item.display_name
	cell.mouse_filter = Control.MOUSE_FILTER_STOP

	# Icon button — clickable with quantity badge overlay
	var icon_btn := Button.new()
	icon_btn.custom_minimum_size = Vector2(ICON_CELL_SIZE, ICON_CELL_SIZE)
	icon_btn.tooltip_text = item.display_name
	icon_btn.pressed.connect(_on_item_clicked.bind(item.id))
	icon_btn.clip_contents = true

	var icon := TextureRect.new()
	icon.texture = item.texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_btn.add_child(icon)

	# Quantity badge in top-right corner
	var badge := Label.new()
	badge.text = "x" + str(count)
	badge.add_theme_font_size_override("font_size", 10)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -30.0
	badge.offset_top = 2.0
	icon_btn.add_child(badge)

	cell.add_child(icon_btn)

	return cell


func _create_action_popup() -> void:
	## Create a reusable action popup with Place and Discard buttons (hidden by default).
	_action_popup = PanelContainer.new()
	_action_popup.visible = false
	_action_popup.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Item name
	var name_label := Label.new()
	name_label.name = "ItemName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Place button
	var place_btn := Button.new()
	place_btn.name = "PlaceBtn"
	place_btn.text = "Place"
	place_btn.pressed.connect(_on_popup_place)
	vbox.add_child(place_btn)

	# Discard button
	var discard_btn := Button.new()
	discard_btn.name = "DiscardBtn"
	discard_btn.text = "Discard"
	discard_btn.pressed.connect(_on_popup_discard)
	vbox.add_child(discard_btn)

	# Cancel button
	var cancel_btn := Button.new()
	cancel_btn.name = "CancelBtn"
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_hide_action_popup)
	vbox.add_child(cancel_btn)

	_action_popup.add_child(vbox)
	add_child(_action_popup)


func _on_item_clicked(furniture_id: String) -> void:
	_selected_item_id = furniture_id
	var fdata := get_furniture_data(furniture_id)
	if not fdata:
		return
	_update_action_popup(fdata)
	_action_popup.visible = true
	# Position popup centered in panel
	_action_popup.position = Vector2(
		(size.x - _action_popup.size.x) / 2.0,
		(size.y - _action_popup.size.y) / 2.0
	)


func _update_action_popup(item: FurnitureData) -> void:
	var vbox := _action_popup.get_child(0)
	var name_label: Label = vbox.get_node("ItemName")
	name_label.text = item.display_name


func _hide_action_popup() -> void:
	_action_popup.visible = false
	_selected_item_id = ""


func _on_popup_place() -> void:
	if _selected_item_id == "":
		return
	var furniture_id := _selected_item_id
	_hide_action_popup()
	if not _inventory_system:
		return
	if _inventory_system.remove_from_inventory(furniture_id):
		close_panel()
		place_requested.emit(furniture_id)


func _on_popup_discard() -> void:
	if _selected_item_id == "":
		return
	_hide_action_popup()
	_on_discard_request(_selected_item_id)


func _on_discard_request(furniture_id: String) -> void:
	var fdata := get_furniture_data(furniture_id)
	if not fdata:
		return
	_confirm_furniture_id = furniture_id
	var refund := int(fdata.coin_cost * fdata.discard_refund_ratio)
	_confirm_dialog.dialog_text = "Discard " + fdata.display_name + " for " + str(refund) + " coins?"
	# Position dialog near inventory panel instead of screen center
	var dialog_size := _confirm_dialog.size if _confirm_dialog.size != Vector2i.ZERO else Vector2i(200, 100)
	var panel_global := global_position
	var screen_size := DisplayServer.screen_get_size()
	# Place to the left of the inventory panel, vertically centered with panel
	var target_x := int(panel_global.x) - dialog_size.x - 10
	var target_y := int(panel_global.y + size.y / 2.0 - float(dialog_size.y) / 2.0)
	# Clamp to screen edges
	target_x = clampi(target_x, 0, screen_size.x - dialog_size.x)
	target_y = clampi(target_y, 0, screen_size.y - dialog_size.y)
	_confirm_dialog.position = Vector2i(target_x, target_y)
	_confirm_dialog.popup()


func _on_discard_confirmed() -> void:
	if _confirm_furniture_id == "":
		return
	var furniture_id := _confirm_furniture_id
	_confirm_furniture_id = ""

	var fdata := get_furniture_data(furniture_id)
	if not fdata:
		return
	if not _inventory_system or not _coin_system:
		return
	if _inventory_system.remove_from_inventory(furniture_id):
		var refund := int(fdata.coin_cost * fdata.discard_refund_ratio)
		_coin_system.add_coins(refund)
		_rebuild_items()


func _on_inventory_changed(_furniture_id: String, _new_count: int) -> void:
	if _is_open:
		_rebuild_items()
