extends PanelContainer

## Furniture shop UI — browse and buy furniture with coins.
## Loads all FurnitureData resources from res://furniture/data/ at startup.
## Tracks owned furniture IDs and persists them via main.gd save system.
## Panel slides in/out adjacent to the slide menu with tween animations.

signal furniture_purchased(furniture_id: String)
signal shop_closed

const ANIM_DURATION: float = 0.3
const SHOP_WIDTH: float = 280.0
const SHOP_HEIGHT: float = 300.0
const GAP: float = 5.0

var _coin_system: Node
var _catalog: Array[FurnitureData] = []
var _owned: Array[String] = []
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


func get_owned() -> Array[String]:
	return _owned


func set_owned(owned: Array[String]) -> void:
	_owned = owned


func is_owned(furniture_id: String) -> bool:
	return _owned.has(furniture_id)


func remove_owned(furniture_id: String) -> void:
	_owned.erase(furniture_id)


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
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		# Icon
		var icon := TextureRect.new()
		icon.texture = item.texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		row.add_child(icon)

		# Name + cost label
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = item.display_name + " - " + str(item.coin_cost) + " coins"
		row.add_child(label)

		# Action button
		var btn := Button.new()
		if _owned.has(item.id):
			btn.text = "Owned"
			btn.disabled = true
		elif coins >= item.coin_cost:
			btn.text = "Buy"
			btn.pressed.connect(_on_buy.bind(item))
		else:
			btn.text = "Buy"
			btn.disabled = true
		row.add_child(btn)

		_items_container.add_child(row)


func _on_buy(item: FurnitureData) -> void:
	if not _coin_system:
		return
	if _coin_system.spend_coins(item.coin_cost):
		_owned.append(item.id)
		furniture_purchased.emit(item.id)
		_rebuild_items()


func _on_coins_changed(_new_total: int) -> void:
	if visible:
		_rebuild_items()
