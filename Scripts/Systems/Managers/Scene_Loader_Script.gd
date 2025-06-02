extends Node3D
@onready var black_overlay = $"../CanvasLayer/black_overlay"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Inicializar lógicas del juego
	GameManager.init()
	ConveyorManager.init()
	BuildManager.init()
	
	await get_tree().create_timer(0.5).timeout

	# Empieza completamente negro
	black_overlay.modulate.a = 1.0
	black_overlay.visible = true

	# Fade-in desde negro
	var tween := create_tween()
	tween.tween_property(black_overlay, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Esperar a que termine el fade-in antes de continuar
	await tween.finished
	black_overlay.visible = false
