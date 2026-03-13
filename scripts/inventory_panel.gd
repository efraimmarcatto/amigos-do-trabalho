extends PanelContainer

## Inventory panel UI — view stored furniture, place items, and discard for partial refund.
## Panel slides in/out adjacent to the slide menu with tween animations.

signal inventory_closed
signal place_requested(furniture_id: String)

const ANIM_DURATION: float = 0.3
const PANEL_WIDTH: float = 280.0
const PANEL_HEIGHT: float = 300.0
const GAP: float = 5.0

var _coin_system: Node
var _inventory_system: Node
var _is_open: bool = false
var _open_x: float = 0.0
var _closed_x: float = 0.0
var _panel_tween: Tween
var _confirm_furniture_id: String = ""

@onready var _vbox: VBoxContainer = $VBox
@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _items_container: VBoxContainer = $VBox/ScrollContainer/Items
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
	_rebuild_items()
	visible = true
	_animate_x(_open_x)


func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
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

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		# Icon
		var icon := TextureRect.new()
		icon.texture = fdata.texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		row.add_child(icon)

		# Name + quantity
		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = fdata.display_name + " x" + str(count)
		row.add_child(name_label)

		# Place button
		var place_btn := Button.new()
		place_btn.text = "Place"
		place_btn.pressed.connect(_on_place.bind(furniture_id))
		row.add_child(place_btn)

		# Discard button
		var discard_btn := Button.new()
		discard_btn.text = "Discard"
		discard_btn.pressed.connect(_on_discard_request.bind(furniture_id))
		row.add_child(discard_btn)

		_items_container.add_child(row)

		# Separator
		var sep := HSeparator.new()
		_items_container.add_child(sep)


func _on_place(furniture_id: String) -> void:
	if not _inventory_system:
		return
	if _inventory_system.remove_from_inventory(furniture_id):
		close_panel()
		place_requested.emit(furniture_id)


func _on_discard_request(furniture_id: String) -> void:
	var fdata := get_furniture_data(furniture_id)
	if not fdata:
		return
	_confirm_furniture_id = furniture_id
	var refund := int(fdata.coin_cost * fdata.discard_refund_ratio)
	_confirm_dialog.dialog_text = "Discard " + fdata.display_name + " for " + str(refund) + " coins?"
	_confirm_dialog.popup_centered()


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
