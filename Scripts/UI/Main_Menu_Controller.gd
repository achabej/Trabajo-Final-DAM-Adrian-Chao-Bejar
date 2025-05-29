extends Control

@onready var Planet1_scene = preload("res://Scenes/Planet_1.tscn")

func _on_play_btn_pressed() -> void:
	var scene = Planet1_scene.instantiate()
	get_tree().root.add_child(scene)

	await get_tree().process_frame
	queue_free()

func _on_options_btn_pressed() -> void:
	pass # Replace with function body.

func _on_exit_btn_pressed() -> void:
	get_tree().quit()
