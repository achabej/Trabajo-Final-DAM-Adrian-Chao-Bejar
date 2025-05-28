extends CharacterBody3D

@onready var nav = $"NavigationAgent3D"
@onready var mesh = preload("res://addons/Godot_4_3D_Characters/addons/gdquest_beetle_bot/beetlebot_skin.tscn").instantiate()

@export var speed = 7
@export var distance_over_target = 4  # Distancia a la que el enemigo se detendrá cerca del jugador
@export var min_distance_to_player = 3  # Distancia mínima para que el enemigo se retire
@export var rotation_speed = 15

var gravity = 9.8
var next_location

func _ready() -> void:
	$Mesh.add_child(mesh)
