@tool
extends EditorPlugin

## Furniture Creator editor plugin — adds a bottom panel for creating/editing FurnitureData resources.

var _panel: Control


func _enter_tree() -> void:
	_panel = preload("res://addons/furniture_creator/furniture_creator_panel.tscn").instantiate()
	add_control_to_bottom_panel(_panel, "Furniture Creator")


func _exit_tree() -> void:
	if _panel:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
