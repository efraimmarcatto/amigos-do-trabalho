extends PanelContainer

## Furniture shop UI — browse and buy furniture with coins.
## Loads all FurnitureData resources from res://furniture/data/ at startup.
## Tracks owned furniture IDs and persists them via main.gd save system.

signal furniture_purchased(furniture_id: String)

var _coin_system: Node
var _catalog: Array[FurnitureData] = []
var _owned: Array[String] = []

@onready var _vbox: VBoxContainer = $VBox
@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _items_container: VBoxContainer = $VBox/ScrollContainer/Items


func _ready() -> void:
	_coin_system = get_parent().get_node("CoinSystem")
	_close_button.pressed.connect(func(): visible = false)
	if _coin_system:
		_coin_system.coins_changed.connect(_on_coins_changed)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_catalog()


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


func open_shop() -> void:
	_rebuild_items()
	visible = true


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


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		# Close shop when clicking outside it
		if not get_global_rect().has_point(event.position):
			visible = false
