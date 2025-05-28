extends Node

@export var material: PackedScene = preload("res://Prefabs/Buildings/Materials/Iron.tscn")
@export var resource_type: String = ""

func _on_screen_exited():
	set_process(false)
	set_physics_process(false)
