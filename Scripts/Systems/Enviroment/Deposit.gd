extends Node

@export var material: PackedScene = preload("res://Prefabs/Buildings/Materials/Iron.tscn")
@export var resource_type: String = ""


func _on_visible_on_screen_enabler_3d_screen_entered() -> void:
	set_process(true)

func _on_visible_on_screen_enabler_3d_screen_exited() -> void:
	set_process(false)
