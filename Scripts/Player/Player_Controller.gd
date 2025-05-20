extends CharacterBody3D

#MOVEMENT CONFIG
@export var WALK_SPEED = 6.5
@export var RUN_SPEED = 10
@export var AIM_SPEED = 3

#JETPACK CONFIG
@export var JETPACK_LIFT = 8
@export var MAX_JETPACK_HEIGHT = 2.0  
@export var JETPACK_TIME = 2.0 
@export var jetpack_enabled: bool = true 
@onready var jetpack_bar = $"CanvasLayer/Jetpack_Bar"

#VARIABLES LOCALES
var current_speed = WALK_SPEED
var jetpack_time_left = JETPACK_TIME
var is_jetpacking = false
var recharge_delay = 2.0  
var recharge_timer = 0.0 

@export var camera: Camera3D

@onready var player_mesh = $PlayerMesh 
@onready var health_controller = $HealthController
@onready var hand_controller = $PlayerMesh/weapon_holder  

const ROTATION_SPEED = 6.0  # Rotación normal
const ROTATION_SHOOT_SPEED = 15.0  # Rotación al disparar

func _physics_process(delta: float) -> void:

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision and collision.get_collider() is RigidBody3D:
			var rigid = collision.get_collider() as RigidBody3D
			var force_dir = velocity.normalized()
			rigid.apply_central_impulse(force_dir * 0.5) 
	
	# Llamamos a la función para manejar el jetpack
	handle_jetpack(delta)

	# Llamamos a la función para manejar el disparo
	handle_shooting(delta)

	# Movimiento
	handle_movement(delta)
	
	if Input.is_action_just_pressed("Building_Mode"):
		BuildManager.ChangeState()
# Método para manejar el jetpack
func handle_jetpack(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y += -10.0 * delta  # Aplica gravedad si no está en el suelo
	else:
		velocity.y = 0
		
		# Si el jugador ha tocado el suelo y el retraso se ha activado
		if recharge_timer >= recharge_delay:
			# Comienza a recargar el jetpack después del retraso
			if jetpack_time_left < JETPACK_TIME:
				jetpack_time_left = min(jetpack_time_left + delta, JETPACK_TIME)
				#print("Jetpack recargado: ", jetpack_time_left)
		else:
			# Inicia el temporizador cuando el jugador toca el suelo
			recharge_timer += delta
			#print("Esperando para recargar: ", recharge_timer)

	# Actualiza la barra del jetpack con el valor de jetpack_time_left
	if jetpack_bar:
		jetpack_bar.value = (jetpack_time_left / JETPACK_TIME) * jetpack_bar.max_value

	# Jetpack (Solo si está habilitado y el tiempo no ha terminado)
	if jetpack_enabled and jetpack_time_left > 0 and Input.is_action_pressed("jump"):
		recharge_timer = 0
		
		# Reduce el tiempo de uso del jetpack, pero no permite que sea menor que 0
		jetpack_time_left -= delta  # Reduce el tiempo de uso del jetpack
		jetpack_time_left = max(jetpack_time_left, 0) 
		print(jetpack_time_left)
			
		# Verificamos la altura máxima antes de aplicar el impulso
		if global_transform.origin.y < MAX_JETPACK_HEIGHT: 
			if not is_jetpacking:
				velocity.y = JETPACK_LIFT  # Elevación controlada
				is_jetpacking = true
		else:
			# Si el jugador ya ha alcanzado la altura máxima, no aplicamos más impulso
			velocity.y = 0  
	else:
		# Si el jetpack ya no está activo, la gravedad actúa normalmente
		is_jetpacking = false
		
# Método para manejar el disparo
func handle_shooting(delta: float) -> void:
	var current_weapon = hand_controller.get_current_weapon()

	# Disparar si hay un arma equipada
	if Input.is_action_pressed("right_click") and current_weapon and !BuildManager.Building:
		var offset = -PI * 0.05  # Ajuste de rotación
		var screen_pos = camera.unproject_position(global_transform.origin)
		var mouse_pos = get_viewport().get_mouse_position()
		var angle = screen_pos.angle_to_point(mouse_pos)
		
		var direction_to_mouse = Vector3(cos(angle + offset), 0, sin(angle + offset)).normalized()
		look_in_direction(direction_to_mouse, delta, ROTATION_SHOOT_SPEED)
		
		if Input.is_action_pressed("left_click"):
			current_weapon.shoot()  # Disparar con el arma equipada
		
	if (Input.is_action_just_released("left_click") or Input.is_action_just_released("right_click")):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()


# Método para manejar el movimiento
func handle_movement(delta: float) -> void:
	var current_weapon = hand_controller.get_current_weapon()

	# Controla la velocidad si se está esprintando, apuntando o caminando
	if is_jetpacking:
		current_speed = WALK_SPEED
	else:
		if Input.is_action_pressed("right_click") and current_weapon and !BuildManager.Building:  # Cuando se apunta
			current_speed = AIM_SPEED  
		elif Input.is_action_pressed("sprint"): 
			current_speed = RUN_SPEED
		else:
			current_speed = WALK_SPEED
	
	# Calcula el movimiento dependiendo del input
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_rot := Input.get_axis("ui_left", "ui_right")

	if input_rot:
		global_rotate(up_direction, PI * -1.7 * delta * input_rot)
		input_dir = Vector2.ZERO  # Evita mover mientras rota

	var direction := (global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	move_and_slide()

	# Rota al jugador según el input
	if direction.length() > 0.1 and not (Input.is_action_pressed("right_click") and current_weapon and !BuildManager.Building): 
		look_in_direction(direction, delta, ROTATION_SPEED)

# Rota al jugador según el input
func look_in_direction(direction: Vector3, delta: float, rotationSpeed: float) -> void:
	var target_rotation = atan2(-direction.x, -direction.z)  
	var current_rotation = player_mesh.rotation.y
	player_mesh.rotation.y = lerp_angle(current_rotation, target_rotation, rotationSpeed * delta)
