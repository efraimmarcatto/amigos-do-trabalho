extends Control

## Collapsible slide-out menu anchored to the bottom-right of the screen.
## A small toggle button is always visible. Clicking it slides a panel
## left to reveal menu options (Shop, Edit Layout, etc.).

signal shop_requested
signal edit_layout_requested
signal menu_opened
signal menu_closed

## Duration of the slide animation in seconds.
@export var slide_duration: float = 0.3

## Width of the menu panel in pixels.
@export var panel_width: float = 180.0

## Height of the menu panel in pixels.
@export var panel_height: float = 160.0

## Size of the toggle button.
@export var button_size: Vector2 = Vector2(40, 40)

var _is_open: bool = false
var _tween: Tween
## Optional callable invoked instead of close_menu() when set.
var on_before_close: Callable

@onready var _toggle_button: Button = $ToggleButton
@onready var _panel: PanelContainer = $MenuPanel
@onready var _shop_button: Button = $MenuPanel/VBox/ShopButton
@onready var _edit_button: Button = $MenuPanel/VBox/EditLayoutButton


func _ready() -> void:
	_toggle_button.pressed.connect(_on_toggle)
	_shop_button.pressed.connect(_on_shop)
	_edit_button.pressed.connect(_on_edit_layout)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(floor_y_val: float) -> void:
	## Position the menu relative to the screen and floor_y.
	var screen_w := float(DisplayServer.screen_get_size().x)

	# Toggle button: bottom-right, above taskbar
	_toggle_button.position = Vector2(
		screen_w - button_size.x - 10.0,
		floor_y_val - button_size.y - 10.0
	)
	_toggle_button.size = button_size

	# Panel: slides from right edge, sits just above the toggle button
	_panel.size = Vector2(panel_width, panel_height)
	# Closed position: off-screen to the right
	_panel.position = Vector2(
		screen_w,
		floor_y_val - panel_height - button_size.y - 20.0
	)
	_panel.visible = true  # Always visible but positioned off-screen when closed


func get_panel_open_x() -> float:
	var screen_w := float(DisplayServer.screen_get_size().x)
	return screen_w - panel_width - 10.0


func get_panel_y() -> float:
	return _panel.position.y


func _get_panel_closed_x() -> float:
	var screen_w := float(DisplayServer.screen_get_size().x)
	return screen_w


func _on_toggle() -> void:
	if _is_open:
		_request_close()
	else:
		open_menu()


func _request_close() -> void:
	if on_before_close.is_valid():
		on_before_close.call()
	else:
		close_menu()


func open_menu() -> void:
	if _is_open:
		return
	_is_open = true
	_animate_panel(get_panel_open_x())
	menu_opened.emit()


func close_menu() -> void:
	if not _is_open:
		return
	_is_open = false
	_animate_panel(_get_panel_closed_x())
	menu_closed.emit()


func _animate_panel(target_x: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "position:x", target_x, slide_duration) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)


func is_open() -> bool:
	return _is_open


func get_toggle_rect() -> Rect2:
	## Returns the global rect of the toggle button for passthrough.
	return Rect2(_toggle_button.global_position, _toggle_button.size)


func get_panel_rect() -> Rect2:
	## Returns the global rect of the panel for passthrough (only when open).
	if _is_open:
		return Rect2(_panel.global_position, _panel.size)
	return Rect2()


func _on_shop() -> void:
	shop_requested.emit()


func _on_edit_layout() -> void:
	edit_layout_requested.emit()
	close_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventMouseButton and event.pressed:
		# Close menu when clicking outside both the panel and the toggle button
		var in_panel := _panel.get_global_rect().has_point(event.position)
		var in_button := Rect2(_toggle_button.global_position, _toggle_button.size).has_point(event.position)
		if not in_panel and not in_button:
			_request_close()
