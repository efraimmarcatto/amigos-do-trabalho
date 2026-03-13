extends PanelContainer

## Furniture shop UI — browse and buy furniture with coins.
## Loads all FurnitureData resources from res://furniture/data/ at startup.
## Purchased items go to inventory (no single-purchase limit).
## Panel slides in/out adjacent to the slide menu with tween animations.

signal shop_closed

const ANIM_DURATION: float = 0.3
const SHOP_WIDTH: float = 280.0
const SHOP_HEIGHT: float = 300.0
const GAP: float = 5.0

var _coin_system: Node
var _inventory_system: Node
var _catalog: Array[FurnitureData] = []
var _quantities: Dictionary = {}  # furniture_id -> selected quantity (int)
var _is_open: bool = false
var _open_x: float = 0.0
var _closed_x: float = 0.0
var _shop_tween: Tween

@onready var _vbox: VBoxContainer = $VBox
@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _items_container: VBoxContainer = $VBox/ScrollContainer/Items


func _ready() -> void:
	_coin_system = get_parent().get_node("CoinSystem")
	_inventory_system = get_parent().get_node("InventorySystem")
	_close_button.pressed.connect(close_shop)
	if _coin_system:
		_coin_system.coins_changed.connect(_on_coins_changed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_catalog()


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
	_rebuild_items()
	visible = true
	_animate_x(_open_x)


func close_shop() -> void:
	if not _is_open:
		return
	_is_open = false
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


func _rebuild_items() -> void:
	# Clear existing items
	for child in _items_container.get_children():
		child.queue_free()

	var coins := 0
	if _coin_system:
		coins = _coin_system.get_coins()

	for item in _catalog:
		var qty: int = _quantities.get(item.id, 1)
		var total_cost: int = item.coin_cost * qty

		# Main row: icon, name, quantity selector, total cost, buy button
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		# Top line: icon + name + unit price
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.texture = item.texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		top.add_child(icon)

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = item.display_name + " (" + str(item.coin_cost) + "/ea)"
		top.add_child(name_label)

		row.add_child(top)

		# Bottom line: quantity selector + total cost + buy button
		var bottom := HBoxContainer.new()
		bottom.add_theme_constant_override("separation", 4)

		# Minus button
		var minus_btn := Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(24, 24)
		minus_btn.disabled = qty <= 1
		minus_btn.pressed.connect(_on_quantity_change.bind(item.id, -1))
		bottom.add_child(minus_btn)

		# Quantity label
		var qty_label := Label.new()
		qty_label.text = str(qty)
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_label.custom_minimum_size = Vector2(24, 0)
		bottom.add_child(qty_label)

		# Plus button
		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(24, 24)
		plus_btn.pressed.connect(_on_quantity_change.bind(item.id, 1))
		bottom.add_child(plus_btn)

		# Total cost label
		var cost_label := Label.new()
		cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cost_label.text = str(total_cost) + " coins"
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bottom.add_child(cost_label)

		# Buy button
		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		if coins >= total_cost:
			buy_btn.pressed.connect(_on_buy.bind(item, qty))
		else:
			buy_btn.disabled = true
		bottom.add_child(buy_btn)

		row.add_child(bottom)

		# Separator
		var sep := HSeparator.new()
		row.add_child(sep)

		_items_container.add_child(row)


func _on_quantity_change(furniture_id: String, delta: int) -> void:
	var current: int = _quantities.get(furniture_id, 1)
	var new_qty: int = maxi(1, current + delta)
	_quantities[furniture_id] = new_qty
	_rebuild_items()


func _on_buy(item: FurnitureData, quantity: int) -> void:
	if not _coin_system or not _inventory_system:
		return
	var total_cost: int = item.coin_cost * quantity
	if _coin_system.spend_coins(total_cost):
		_inventory_system.add_to_inventory(item.id, quantity)
		# Reset quantity for this item after purchase
		_quantities[item.id] = 1
		_rebuild_items()


func _on_coins_changed(_new_total: int) -> void:
	if visible:
		_rebuild_items()
