extends Control

@export var button:Button
@export var delete_button:Button
@export var web_control:WebControl
@export var web_control2:WebControl
@export var web_control3:WebControl

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	
	web_control2.add_js_func("on_textarea_changed", JavaScriptBridge.create_callback(_on_textarea_changed))

func _on_button_pressed():
	web_control.visible = !web_control.visible
	web_control2.visible = !web_control2.visible
	web_control3.visible = !web_control3.visible

func _on_delete_button_pressed():
	web_control.queue_free()
	web_control2.queue_free()
	web_control3.queue_free()

func _on_textarea_changed(args):
	var s = args[0]
	print("on_textarea_changed:" + str(s))
