extends Node3D
@onready var black_overlay = $"../CanvasLayer/black_overlay"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Inicializar lógicas del juego
	GameManager.init()
	ConveyorManager.init()
	BuildManager.init()
	
	await GameManager.fade_black_overlay(true)
