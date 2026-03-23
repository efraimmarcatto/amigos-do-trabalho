@tool
extends EditorPlugin

## GlobalInput editor plugin — registers GlobalInput as an autoload singleton.


func _enter_tree() -> void:
	add_autoload_singleton("GlobalInput", "res://addons/global_input/global_input.gdextension")


func _exit_tree() -> void:
	remove_autoload_singleton("GlobalInput")
