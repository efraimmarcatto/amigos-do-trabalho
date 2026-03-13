extends Node

## Mock GlobalInput singleton for development/testing.
## Simulates keyboard and mouse input counts without the compiled C++ extension.
## Remove this autoload and use the real GDExtension GlobalInput when ready.

## Enable to print input counts to console each poll cycle
@export var debug_mode: bool = false

var _key_count: int = 0
var _click_count: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if debug_mode:
		print("[MockGlobalInput] Initialized in debug mode")


func _process(_delta: float) -> void:
	# Simulate random input activity each frame
	# Accumulate small random amounts to mimic real typing/clicking
	if randf() < 0.3:
		_key_count += _rng.randi_range(0, 3)
	if randf() < 0.1:
		_click_count += _rng.randi_range(0, 1)


func get_key_count() -> int:
	var count := _key_count
	if debug_mode and count > 0:
		print("[MockGlobalInput] key_count: ", count)
	return count


func get_click_count() -> int:
	var count := _click_count
	if debug_mode and count > 0:
		print("[MockGlobalInput] click_count: ", count)
	return count


func reset_counts() -> void:
	_key_count = 0
	_click_count = 0
	if debug_mode:
		print("[MockGlobalInput] Counts reset")
