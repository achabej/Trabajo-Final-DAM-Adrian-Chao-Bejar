extends RigidBody3D

@export var damage: float = 10.0  # Daño que causa la bala

func _ready():
	# Evitar colisiones con el disparador (ejemplo: el jugador)
	await get_tree().create_timer(0.1).timeout  # Pequeño retraso antes de activarse

	# Destruir la bala después de 5 segundos
	await get_tree().create_timer(5.0).timeout
	queue_free()
