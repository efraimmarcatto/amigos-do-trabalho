extends PanelContainer

## Settings panel UI — language selection and other preferences.
## Panel slides in/out adjacent to the slide menu with tween animations.

signal settings_closed
signal monitor_changed(monitor_index: int)

const ANIM_DURATION: float = 0.3
const PANEL_WIDTH: float = 280.0
const PANEL_HEIGHT: float = 300.0
const GAP: float = 5.0

var _is_open: bool = false
var _open_x: float = 0.0
var _closed_x: float = 0.0
var _panel_tween: Tween

## Mapping of locale code to display name for the language dropdown.
var _languages: Array[Dictionary] = [
	{"locale": "en", "name": "English"},
	{"locale": "pt", "name": "Português"},
]

@onready var _vbox: VBoxContainer = $VBox
@onready var _title: Label = $VBox/Title
@onready var _close_button: Button = $VBox/CloseButton
@onready var _language_label: Label = $VBox/LanguageLabel
@onready var _language_dropdown: OptionButton = $VBox/LanguageDropdown
@onready var _monitor_label: Label = $VBox/MonitorLabel
@onready var _monitor_dropdown: OptionButton = $VBox/MonitorDropdown


func _ready() -> void:
	_close_button.pressed.connect(close_panel)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Load translations from CSV into TranslationServer
	_load_translations()

	# Populate language dropdown
	for i in range(_languages.size()):
		var lang: Dictionary = _languages[i]
		_language_dropdown.add_item(lang["name"], i)
	_language_dropdown.item_selected.connect(_on_language_selected)

	# Select current locale in dropdown
	_select_current_locale()

	# Populate monitor dropdown
	_populate_monitors()
	_monitor_dropdown.item_selected.connect(_on_monitor_selected)


func setup(menu_open_x: float, menu_panel_y: float) -> void:
	## Position the settings panel to slide in adjacent to the menu.
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
	_select_current_locale()
	_populate_monitors()
	visible = true
	_animate_x(_open_x)


func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
	_animate_x(_closed_x, true)
	settings_closed.emit()


func is_panel_open() -> bool:
	return _is_open


func get_close_duration() -> float:
	return ANIM_DURATION


func apply_language(locale: String) -> void:
	## Apply a language locale, updating TranslationServer and all UI text.
	TranslationServer.set_locale(locale)
	_update_all_ui_text()


func get_current_locale() -> String:
	return TranslationServer.get_locale().substr(0, 2)


func _animate_x(target_x: float, hide_after: bool = false) -> void:
	if _panel_tween and _panel_tween.is_running():
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(self, "position:x", target_x, ANIM_DURATION) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	if hide_after:
		_panel_tween.tween_callback(func(): visible = false)


func _load_translations() -> void:
	## Parse the CSV translation file and register translations with TranslationServer.
	var file := FileAccess.open("res://translations/translations.csv", FileAccess.READ)
	if not file:
		return

	# First line is the header: keys,en,pt,...
	var header := file.get_csv_line()
	if header.size() < 2:
		return

	# Build one Translation resource per locale (skip column 0 which is "keys")
	var translations: Array[Translation] = []
	for col in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[col]
		translations.append(t)

	# Parse each row
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		var key := row[0]
		for col in range(1, mini(row.size(), header.size())):
			translations[col - 1].add_message(key, row[col])

	# Register all translations
	for t in translations:
		TranslationServer.add_translation(t)


func _select_current_locale() -> void:
	var current := get_current_locale()
	for i in range(_languages.size()):
		if _languages[i]["locale"] == current:
			_language_dropdown.selected = i
			return
	# Default to English (index 0) if not found
	_language_dropdown.selected = 0


func _on_language_selected(index: int) -> void:
	if index < 0 or index >= _languages.size():
		return
	var locale: String = _languages[index]["locale"]
	apply_language(locale)


func get_current_monitor() -> int:
	return DisplayServer.window_get_current_screen()


func apply_monitor(monitor_index: int) -> void:
	## Apply a monitor selection, moving the window and emitting signal.
	var count := DisplayServer.screen_get_count()
	if monitor_index < 0 or monitor_index >= count:
		monitor_index = 0
	DisplayServer.window_set_current_screen(monitor_index)
	_select_current_monitor()
	monitor_changed.emit(monitor_index)


func _populate_monitors() -> void:
	_monitor_dropdown.clear()
	var count := DisplayServer.screen_get_count()
	for i in range(count):
		var screen_size := DisplayServer.screen_get_size(i)
		var label := "Monitor %d — %dx%d" % [i + 1, screen_size.x, screen_size.y]
		_monitor_dropdown.add_item(label, i)
	_select_current_monitor()


func _select_current_monitor() -> void:
	var current := DisplayServer.window_get_current_screen()
	var count := _monitor_dropdown.item_count
	if current >= 0 and current < count:
		_monitor_dropdown.selected = current
	elif count > 0:
		_monitor_dropdown.selected = 0


func _on_monitor_selected(index: int) -> void:
	if index < 0 or index >= DisplayServer.screen_get_count():
		return
	apply_monitor(index)


func _update_all_ui_text() -> void:
	## Refresh all UI text using tr() after a language change.
	# Settings panel itself
	_title.text = tr("SETTINGS_TITLE")
	_close_button.text = tr("CLOSE")
	_language_label.text = tr("LANGUAGE_LABEL")
	_monitor_label.text = tr("MONITOR_LABEL")

	# Update sibling panels and menus via tree
	var main_node := get_parent()
	if not main_node:
		return

	# Slide menu
	var smenu := main_node.get_node_or_null("SlideMenu")
	if smenu:
		var panel := smenu.get_node_or_null("MenuPanel")
		if panel:
			var vbox := panel.get_node_or_null("VBox")
			if vbox:
				var title_lbl := vbox.get_node_or_null("Title")
				if title_lbl:
					title_lbl.text = tr("MENU_TITLE")
				var shop_btn := vbox.get_node_or_null("ShopButton")
				if shop_btn:
					shop_btn.text = tr("SHOP_BUTTON")
				var inv_btn := vbox.get_node_or_null("InventoryButton")
				if inv_btn:
					inv_btn.text = tr("INVENTORY_BUTTON")
				var edit_btn := vbox.get_node_or_null("EditLayoutButton")
				if edit_btn:
					# Preserve "Save Edit" state if in edit mode
					if edit_btn.text == "Save Edit" or edit_btn.text == tr("SAVE_EDIT_BUTTON"):
						edit_btn.text = tr("SAVE_EDIT_BUTTON")
					else:
						edit_btn.text = tr("EDIT_LAYOUT_BUTTON")
				var settings_btn := vbox.get_node_or_null("SettingsButton")
				if settings_btn:
					settings_btn.text = tr("SETTINGS_BUTTON")
				var pet_btn := vbox.get_node_or_null("PetButton")
				if pet_btn:
					pet_btn.text = tr("SELECT_PET_BUTTON")

	# Shop panel
	var shop := main_node.get_node_or_null("ShopPanel")
	if shop:
		var shop_title := shop.get_node_or_null("VBox/Title")
		if shop_title:
			shop_title.text = tr("SHOP_TITLE")
		var shop_close := shop.get_node_or_null("VBox/CloseButton")
		if shop_close:
			shop_close.text = tr("CLOSE")

	# Inventory panel
	var inv := main_node.get_node_or_null("InventoryPanel")
	if inv:
		var inv_title := inv.get_node_or_null("VBox/Title")
		if inv_title:
			inv_title.text = tr("INVENTORY_TITLE")
		var inv_close := inv.get_node_or_null("VBox/CloseButton")
		if inv_close:
			inv_close.text = tr("CLOSE")

	# Pet selection panel
	var pet_panel := main_node.get_node_or_null("PetSelectionPanel")
	if pet_panel:
		var pet_title := pet_panel.get_node_or_null("VBox/Title")
		if pet_title:
			pet_title.text = tr("SELECT_PET_TITLE")
		var pet_close := pet_panel.get_node_or_null("VBox/CloseButton")
		if pet_close:
			pet_close.text = tr("CLOSE")

	# Interaction menu
	var imenu := main_node.get_node_or_null("InteractionMenu")
	if imenu:
		var imenu_title := imenu.get_node_or_null("VBox/Title")
		if imenu_title:
			imenu_title.text = tr("PET_ACTIONS_TITLE")
