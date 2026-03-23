extends PanelContainer

## Pet selection panel — browse and select from available pet SpriteFrames.
## Panel slides in/out adjacent to the slide menu with tween animations.

signal selection_closed
signal pet_selected(pet_name: String, sprite_frames: SpriteFrames)

const ANIM_DURATION: float = 0.3
const PANEL_WIDTH: float = 280.0
const PANEL_HEIGHT: float = 340.0
const GAP: float = 5.0
const PET_DIR: String = "res://pet/data/"
const THUMB_SIZE: float = 64.0

var _is_open: bool = false
var _open_x: float = 0.0
var _closed_x: float = 0.0
var _panel_tween: Tween
var _current_pet: String = "ozzy"
## Cache of discovered pets: Array of {name: String, path: String, sprite_frames: SpriteFrames}
var _pet_catalog: Array[Dictionary] = []

@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _grid: GridContainer = $VBox/ScrollContainer/Grid


func _ready() -> void:
	_close_button.pressed.connect(close_panel)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_discover_pets()


func setup(menu_open_x: float, menu_panel_y: float) -> void:
	## Position the panel to slide in adjacent to the menu.
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
	_rebuild_grid()
	visible = true
	_animate_x(_open_x)


func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
	_animate_x(_closed_x, true)
	selection_closed.emit()


func is_panel_open() -> bool:
	return _is_open


func get_close_duration() -> float:
	return ANIM_DURATION


func get_current_pet() -> String:
	return _current_pet


func apply_pet(pet_name: String) -> void:
	## Apply a pet selection by name (without .tres extension).
	for entry in _pet_catalog:
		if entry["name"] == pet_name:
			_current_pet = pet_name
			pet_selected.emit(pet_name, entry["sprite_frames"] as SpriteFrames)
			return
	# Fallback to ozzy if not found
	if pet_name != "ozzy":
		apply_pet("ozzy")


func _animate_x(target_x: float, hide_after: bool = false) -> void:
	if _panel_tween and _panel_tween.is_running():
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(self, "position:x", target_x, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	if hide_after:
		_panel_tween.tween_callback(func(): visible = false)


func _discover_pets() -> void:
	## Scan the pet data directory for .tres SpriteFrames files.
	_pet_catalog.clear()
	var dir := DirAccess.open(PET_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := PET_DIR + file_name
			var res := load(path)
			if res is SpriteFrames:
				var pet_name := file_name.get_basename()
				_pet_catalog.append({
					"name": pet_name,
					"path": path,
					"sprite_frames": res,
				})
		file_name = dir.get_next()
	dir.list_dir_end()
	_pet_catalog.sort_custom(func(a, b): return a["name"] < b["name"])


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	if _pet_catalog.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("NO_PETS_FOUND")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grid.add_child(empty_label)
		return

	for entry in _pet_catalog:
		var pet_name: String = entry["name"]
		var sf: SpriteFrames = entry["sprite_frames"]

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(THUMB_SIZE + 20, THUMB_SIZE + 40)
		btn.pressed.connect(_on_pet_selected.bind(pet_name))

		# Highlight the currently selected pet
		if pet_name == _current_pet:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.3, 0.6, 0.9, 0.4)
			style.border_color = Color(0.3, 0.6, 0.9, 1.0)
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", style)

		var inner := VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Preview image — first frame of idle animation
		var img := TextureRect.new()
		img.custom_minimum_size = Vector2(THUMB_SIZE, THUMB_SIZE)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sf.has_animation("idle") and sf.get_frame_count("idle") > 0:
			img.texture = sf.get_frame_texture("idle", 0)
		inner.add_child(img)

		# Pet name
		var lbl := Label.new()
		lbl.text = pet_name.capitalize()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(lbl)

		btn.add_child(inner)
		_grid.add_child(btn)


func _on_pet_selected(pet_name: String) -> void:
	if pet_name == _current_pet:
		return
	_current_pet = pet_name
	for entry in _pet_catalog:
		if entry["name"] == pet_name:
			pet_selected.emit(pet_name, entry["sprite_frames"] as SpriteFrames)
			break
	_rebuild_grid()
