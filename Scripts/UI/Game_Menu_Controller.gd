extends Control

var active = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Menu") and GameManager.currentState != GameManager.State.Die:
		active = !active
		
		if $Configuration.visible or $Exit_Notif.visible:
			$"Menu_default".visible = active
			$Configuration.visible = !active
			$Exit_Notif.visible = !active

		$"../HUD".visible = !active
		visible = active
	get_tree().paused = active

func _on_resume_btn_pressed() -> void:
	active = false
	visible = false


func _on_options_btn_pressed() -> void:
	$Menu_default.visible = false
	$Configuration.visible = true

func _on_save_btn_pressed() -> void:
	pass # Replace with function body.

func _on_exit_btn_pressed() -> void:
	$Menu_default.visible = false
	$Exit_Notif.visible = true

func _on_confirm_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
	
func _on_cancel_btn_pressed() -> void:
	$Menu_default.visible = true
	$Exit_Notif.visible = false
