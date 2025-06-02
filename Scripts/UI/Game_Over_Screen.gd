extends Control

func _process(delta: float) -> void:
	if GameManager.currentState == GameManager.State.Die:
		get_tree().paused = true

func show_game_over():
	modulate.a = 0
	visible = true

	# Fade-in desde negro
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Esperar a que termine el fade-in antes de continuar
	await tween.finished
	
	GameManager.currentState = GameManager.State.Die

func _on_confirm_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
