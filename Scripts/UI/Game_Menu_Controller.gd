extends Control

var active = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Menu"):
		active = !active
	visible = active
	get_tree().paused = active

func _on_resume_btn_pressed() -> void:
	active = false

func _on_options_btn_pressed() -> void:
	pass # Replace with function body.

func _on_save_btn_pressed() -> void:
	pass # Replace with function body.

func _on_exit_btn_pressed() -> void:
	$Resume_Btn.visible = false
	$Options_Btn.visible = false
	$Exit_Btn.visible = false
	$Exit_Notif.visible = true

func _on_confirm_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
	get_parent().queue_free()
	
func _on_cancel_btn_pressed() -> void:
	$Resume_Btn.visible = true
	$Options_Btn.visible = true
	$Exit_Btn.visible = true
	$Exit_Notif.visible = false
