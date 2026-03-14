extends PanelContainer

## Furniture shop UI — browse and buy furniture with coins.
## Loads all FurnitureData resources from res://furniture/data/ at startup.
## Purchased items go to inventory (no single-purchase limit).
## Panel slides in/out adjacent to the slide menu with tween animations.
## Items displayed as a responsive icon grid with prices and hover tooltips.

signal shop_closed

const ANIM_DURATION: float = 0.3
const SHOP_WIDTH: float = 280.0
const SHOP_HEIGHT: float = 300.0
const GAP: float = 5.0
const ICON_CELL_SIZE: float = 64.0
const ICON_SIZE: float = 48.0

var _coin_system: Node
var _inventory_system: Node
var _catalog: Array[FurnitureData] = []
var _quantities: Dictionary = {}  # furniture_id -> selected quantity (int)
var _is_open: bool = false
var _open_x: float = 0.0
var _closed_x: float = 0.0
var _shop_tween: Tween
var _buy_popup: PanelContainer
var _selected_item: FurnitureData

@onready var _vbox: VBoxContainer = $VBox
@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _items_container: GridContainer = $VBox/ScrollContainer/Items


func _ready() -> void:
	_coin_system = get_parent().get_node("CoinSystem")
	_inventory_system = get_parent().get_node("InventorySystem")
	_close_button.pressed.connect(close_shop)
	if _coin_system:
		_coin_system.coins_changed.connect(_on_coins_changed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_catalog()
	_create_buy_popup()


func setup(menu_open_x: float, menu_panel_y: float) -> void:
	## Position the shop panel to slide in adjacent to the menu.
	var screen_w := float(DisplayServer.screen_get_size().x)
	custom_minimum_size = Vector2(SHOP_WIDTH, SHOP_HEIGHT)
	size = Vector2(SHOP_WIDTH, SHOP_HEIGHT)
	_open_x = menu_open_x - SHOP_WIDTH - GAP
	_closed_x = screen_w
	position = Vector2(_closed_x, menu_panel_y)


func open_shop() -> void:
	if _is_open:
		return
	_is_open = true
	# Reset quantities to 1 on each open
	_quantities.clear()
	for item in _catalog:
		_quantities[item.id] = 1
	_update_columns()
	_rebuild_items()
	_hide_buy_popup()
	visible = true
	_animate_x(_open_x)


func close_shop() -> void:
	if not _is_open:
		return
	_is_open = false
	_hide_buy_popup()
	_animate_x(_closed_x, true)
	shop_closed.emit()


func is_shop_open() -> bool:
	return _is_open


func get_close_duration() -> float:
	return ANIM_DURATION


func _animate_x(target_x: float, hide_after: bool = false) -> void:
	if _shop_tween and _shop_tween.is_running():
		_shop_tween.kill()
	_shop_tween = create_tween()
	_shop_tween.tween_property(self, "position:x", target_x, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	if hide_after:
		_shop_tween.tween_callback(func(): visible = false)


func _load_catalog() -> void:
	var dir := DirAccess.open("res://furniture/data/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://furniture/data/" + file_name)
			if res is FurnitureData:
				_catalog.append(res as FurnitureData)
		file_name = dir.get_next()
	dir.list_dir_end()
	# Sort by cost ascending
	_catalog.sort_custom(func(a: FurnitureData, b: FurnitureData): return a.coin_cost < b.coin_cost)


func get_furniture_data(furniture_id: String) -> FurnitureData:
	for item in _catalog:
		if item.id == furniture_id:
			return item
	return null


func _update_columns() -> void:
	## Set grid columns based on available width.
	var available_w := SHOP_WIDTH - 20.0  # account for panel margins
	var cols := maxi(1, int(available_w / (ICON_CELL_SIZE + 4.0)))
	_items_container.columns = cols


func _rebuild_items() -> void:
	# Clear existing items
	for child in _items_container.get_children():
		child.queue_free()

	for item in _catalog:
		var cell := _create_grid_cell(item)
		_items_container.add_child(cell)


func _create_grid_cell(item: FurnitureData) -> Control:
	## Create a single grid cell with icon and price.
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(ICON_CELL_SIZE, ICON_CELL_SIZE + 16.0)
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.tooltip_text = item.display_name
	cell.mouse_filter = Control.MOUSE_FILTER_STOP

	# Icon button — clickable TextureRect inside a CenterContainer
	var icon_btn := Button.new()
	icon_btn.custom_minimum_size = Vector2(ICON_CELL_SIZE, ICON_CELL_SIZE)
	icon_btn.tooltip_text = item.display_name
	icon_btn.pressed.connect(_on_item_clicked.bind(item))

	var icon := TextureRect.new()
	icon.texture = item.texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon_btn.add_child(icon)

	cell.add_child(icon_btn)

	# Price label below icon
	var price_label := Label.new()
	price_label.text = str(item.coin_cost) + " c"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 11)
	cell.add_child(price_label)

	return cell


func _create_buy_popup() -> void:
	## Create a reusable buy popup panel (hidden by default).
	_buy_popup = PanelContainer.new()
	_buy_popup.visible = false
	_buy_popup.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Item name
	var name_label := Label.new()
	name_label.name = "ItemName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Quantity row
	var qty_row := HBoxContainer.new()
	qty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	qty_row.add_theme_constant_override("separation", 4)

	var minus_btn := Button.new()
	minus_btn.name = "MinusBtn"
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(28, 28)
	minus_btn.pressed.connect(_on_popup_quantity_change.bind(-1))
	qty_row.add_child(minus_btn)

	var qty_label := Label.new()
	qty_label.name = "QtyLabel"
	qty_label.text = "1"
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_label.custom_minimum_size = Vector2(28, 0)
	qty_row.add_child(qty_label)

	var plus_btn := Button.new()
	plus_btn.name = "PlusBtn"
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(28, 28)
	plus_btn.pressed.connect(_on_popup_quantity_change.bind(1))
	qty_row.add_child(plus_btn)

	vbox.add_child(qty_row)

	# Total cost
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_label)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.name = "BuyBtn"
	buy_btn.text = "Buy"
	buy_btn.pressed.connect(_on_popup_buy)
	vbox.add_child(buy_btn)

	# Cancel button
	var cancel_btn := Button.new()
	cancel_btn.name = "CancelBtn"
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_hide_buy_popup)
	vbox.add_child(cancel_btn)

	_buy_popup.add_child(vbox)
	add_child(_buy_popup)


func _on_item_clicked(item: FurnitureData) -> void:
	_selected_item = item
	_quantities[item.id] = 1
	_update_buy_popup()
	_buy_popup.visible = true
	# Position popup centered in shop panel
	_buy_popup.position = Vector2(
		(size.x - _buy_popup.size.x) / 2.0,
		(size.y - _buy_popup.size.y) / 2.0
	)


func _update_buy_popup() -> void:
	if not _selected_item:
		return
	var qty: int = _quantities.get(_selected_item.id, 1)
	var total_cost: int = _selected_item.coin_cost * qty
	var coins := 0
	if _coin_system:
		coins = _coin_system.get_coins()

	var vbox := _buy_popup.get_child(0)
	var name_label: Label = vbox.get_node("ItemName")
	var qty_label: Label = vbox.get_node("QtyLabel")
	var cost_label: Label = vbox.get_node("CostLabel")
	var buy_btn: Button = vbox.get_node("BuyBtn")
	var minus_btn: Button = vbox.get_node("MinusBtn")

	name_label.text = _selected_item.display_name
	qty_label.text = str(qty)
	cost_label.text = str(total_cost) + " coins"
	buy_btn.disabled = coins < total_cost
	minus_btn.disabled = qty <= 1


func _hide_buy_popup() -> void:
	_buy_popup.visible = false
	_selected_item = null


func _on_popup_quantity_change(delta: int) -> void:
	if not _selected_item:
		return
	var current: int = _quantities.get(_selected_item.id, 1)
	var new_qty: int = maxi(1, current + delta)
	_quantities[_selected_item.id] = new_qty
	_update_buy_popup()


func _on_popup_buy() -> void:
	if not _selected_item or not _coin_system or not _inventory_system:
		return
	var qty: int = _quantities.get(_selected_item.id, 1)
	var total_cost: int = _selected_item.coin_cost * qty
	if _coin_system.spend_coins(total_cost):
		_inventory_system.add_to_inventory(_selected_item.id, qty)
		_quantities[_selected_item.id] = 1
		_hide_buy_popup()


func _on_coins_changed(_new_total: int) -> void:
	if visible:
		if _buy_popup.visible:
			_update_buy_popup()
