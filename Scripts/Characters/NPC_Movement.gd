extends CharacterBody3D

@onready var nav = $"NavigationAgent3D"
@onready var mesh = $NPCMesh

@export var speed = 7
@export var distance_over_target = 4  # Distancia a la que el enemigo se detendrá cerca del jugador
@export var min_distance_to_player = 3  # Distancia mínima para que el enemigo se retire
@export var rotation_speed = 15

var gravity = 9.8
var next_location

func _process(delta: float) -> void:
	# Control de gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y -= 2
	
	# Calcular la distancia al jugador
	var distance_to_target = get_distance_to_target(nav.target_position)
	var next_location = nav.get_next_path_position()
	var current_location = global_transform.origin
	var direction_to_target = (next_location - current_location).normalized()
	
	# Si el enemigo está demasiado cerca del jugador, se aleja
	if distance_to_target < min_distance_to_player:
		# Moverse en la dirección opuesta al jugador
		var new_velocity = -direction_to_target * speed
		velocity = velocity.move_toward(new_velocity, 0.25)
		move_and_slide()
		look_in_direction(direction_to_target, delta, rotation_speed)
	
	# Si está lo suficientemente lejos del jugador, sigue el camino
	elif distance_to_target >= distance_over_target:
		# Moverse hacia el siguiente punto en el NavMesh
		var new_velocity = direction_to_target * speed
		velocity = velocity.move_toward(new_velocity, 0.25)
		move_and_slide()
		look_in_direction(direction_to_target, delta, rotation_speed)
	
	# Si está dentro de la distancia de descanso, se detiene
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		look_in_direction(direction_to_target, delta, rotation_speed)


func target_position(target):
	nav.target_position = target

# Método para rotar el enemigo hacia la dirección del movimiento
func look_in_direction(direction: Vector3, delta: float, rotation_speed: float) -> void:
	# Asegúrate de que la dirección no sea cero para evitar errores de rotación
	if direction.length() == 0:
		return
	
	# Calcula el ángulo de rotación hacia la dirección del movimiento
	var target_rotation = atan2(direction.x, direction.z)
	var current_rotation = mesh.rotation.y
	mesh.rotation.y = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)

# Método para calcular la distancia al objetivo
func get_distance_to_target(target_position: Vector3) -> float:
	var enemy_position = global_transform.origin
	return enemy_position.distance_to(target_position)
