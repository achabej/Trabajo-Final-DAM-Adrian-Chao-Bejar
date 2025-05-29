extends CharacterBody3D

@onready var nav = $"NavigationAgent3D"
@onready var mesh = preload("res://addons/Godot_4_3D_Characters/addons/gdquest_beetle_bot/beetlebot_skin.tscn").instantiate()

func _ready() -> void:
	$Mesh.add_child(mesh)
