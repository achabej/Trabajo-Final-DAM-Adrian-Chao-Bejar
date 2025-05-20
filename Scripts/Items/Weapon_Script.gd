extends Node3D

@export var bala_prefab: PackedScene  # Prefab de la bala
@export var punto_disparo: Node3D  # Nodo donde aparece la bala
@export var fire_rate: float = 0.5  # Tiempo entre disparos
@export var damage: float = 10.0  # Daño de la bala
@export var velocidad_bala: float = 1000.0  # Velocidad de la bala

var tiempo_desde_ultimo_disparo: float = 0.0

func _process(delta: float) -> void:
	tiempo_desde_ultimo_disparo += delta

func shoot() -> void:
	if tiempo_desde_ultimo_disparo < fire_rate:
		return
	
	tiempo_desde_ultimo_disparo = 0.0

	if punto_disparo == null or bala_prefab == null:
		print("¡Error! 'punto_disparo' o 'bala_prefab' no están asignados.")
		return
	
	# Instanciar la bala
	var bala = bala_prefab.instantiate() as RigidBody3D
	if bala == null:
		print("¡Error! No se pudo instanciar la bala.")
		return
	
	# Configurar posición y dirección de la bala
	bala.global_transform = punto_disparo.global_transform
	bala.linear_velocity = -punto_disparo.global_transform.basis.z.normalized() * velocidad_bala

	# Agregar la bala a la escena
	get_tree().current_scene.add_child(bala)
