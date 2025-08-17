@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("WebControl", "Control", preload("web_control.gd"), null)

func _exit_tree() -> void:
	remove_custom_type("WebControl")
