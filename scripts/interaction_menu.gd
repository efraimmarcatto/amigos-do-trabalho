extends PanelContainer

## Popup menu for pet interactions (Feed, Play).
## Spends coins and grants bonus coins on successful interaction.

signal interaction_performed(interaction_name: String)

## Cost in coins to feed the pet
@export var feed_cost: int = 10
## Bonus coins gained from feeding
@export var feed_bonus: int = 5
## Cost in coins to play with the pet
@export var play_cost: int = 15
## Bonus coins gained from playing
@export var play_bonus: int = 8

var _coin_system: Node

@onready var _feed_button: Button = $VBox/FeedButton
@onready var _play_button: Button = $VBox/PlayButton


func _ready() -> void:
	_coin_system = get_parent().get_node("CoinSystem")
	_feed_button.pressed.connect(_on_feed)
	_play_button.pressed.connect(_on_play)
	if _coin_system:
		_coin_system.coins_changed.connect(_update_buttons)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_menu(pos: Vector2) -> void:
	position = pos
	if _coin_system:
		_update_buttons(_coin_system.get_coins())
	visible = true


func _on_feed() -> void:
	if _coin_system and _coin_system.spend_coins(feed_cost):
		_coin_system.add_coins(feed_bonus)
		interaction_performed.emit("feed")
	visible = false


func _on_play() -> void:
	if _coin_system and _coin_system.spend_coins(play_cost):
		_coin_system.add_coins(play_bonus)
		interaction_performed.emit("play")
	visible = false


func _update_buttons(coins: int) -> void:
	_feed_button.disabled = coins < feed_cost
	_play_button.disabled = coins < play_cost


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		# Close menu when clicking outside it
		visible = false
