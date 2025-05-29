extends Control

@onready var Planet1_scene = preload("res://Scenes/Planet_1.tscn")

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_packed(Planet1_scene)

func _on_options_btn_pressed() -> void:
	pass # Replace with function body.

func _on_exit_btn_pressed() -> void:
	get_tree().quit()
