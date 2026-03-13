extends Node

## Coin system that converts keyboard/mouse activity into in-game coins.
## Polls GlobalInput every 1 second and awards coins based on input counts.

signal coins_changed(new_total: int)

## Coins earned per keystroke
@export var coins_per_key: int = 1
## Coins earned per mouse click
@export var coins_per_click: int = 1
## Seconds of zero input before coins start decaying
@export var decay_interval: float = 30.0
## Coins lost per decay tick
@export var decay_amount: int = 1

var _coins: int = 0
var _poll_timer: Timer
var _idle_time: float = 0.0


func _ready() -> void:
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 1.0
	_poll_timer.autostart = true
	_poll_timer.timeout.connect(_on_poll_timeout)
	add_child(_poll_timer)


func get_coins() -> int:
	return _coins


func set_coins(value: int) -> void:
	var old := _coins
	_coins = max(value, 0)
	if _coins != old:
		coins_changed.emit(_coins)


func add_coins(amount: int) -> void:
	set_coins(_coins + amount)


func spend_coins(amount: int) -> bool:
	if _coins >= amount:
		set_coins(_coins - amount)
		return true
	return false


func _on_poll_timeout() -> void:
	var keys := GlobalInput.get_key_count()
	var clicks := GlobalInput.get_click_count()
	GlobalInput.reset_counts()

	var earned := (keys * coins_per_key) + (clicks * coins_per_click)
	if earned > 0:
		add_coins(earned)
		_idle_time = 0.0
	else:
		_idle_time += _poll_timer.wait_time
		if _idle_time >= decay_interval:
			_idle_time = 0.0
			if _coins > 0:
				set_coins(_coins - decay_amount)
