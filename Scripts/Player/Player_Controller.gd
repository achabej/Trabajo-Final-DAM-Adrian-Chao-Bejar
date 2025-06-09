extends CharacterBody3D

# Configuración de movimiento
@export var WALK_SPEED = 6.5
@export var RUN_SPEED = 10
@export var AIM_SPEED = 3

# ======JETPACK======
@export var JETPACK_LIFT = 8
@export var MAX_JETPACK_HEIGHT = 2.0
@export var JETPACK_TIME = 2.0
@export var jetpack_enabled: bool = true
@onready var jetpack_bar = $"CanvasLayer/HUD/Jetpack_Bar"
@export var JETPACK_MAX_ABSOLUTE_Y: float = 10.0
var jetpack_cooldown_timer := 0.0
var jetpack_min_height := 4.0
var current_max_height := 4.0
var height_increase_speed := 8

# Variables adicionales para el empuje del jetpack
var lift_min_value := 4.0
var current_lift := 4.0
var lift_increase_speed := 6.0

# Variables locales de movimiento
var current_speed = WALK_SPEED
var jetpack_time_left = JETPACK_TIME
var is_jetpacking = false
var recharge_delay = 0.2
var recharge_timer = 0.0
var starting_jetpack_y = 0.0

# Configuración de la cámara
@export var camera: Camera3D
@export var min_y_angle_deg: float = -90.0
@export var max_y_angle_deg: float = -45.0
@onready var cam_node = $CamNode
var vertical_angle := deg_to_rad(-45.0) #Angulo principal
var target_vertical_angle := deg_to_rad(-45.0) #Angulo siguiente
var vertical_angle_lerp_speed := 10.0 #Velocidad de giro

# Modelo del jugador
@onready var player_model = preload("res://addons/Godot_4_3D_Characters/addons/gdquest_gdbot/gdbot_skin.tscn").instantiate()
const BLEND_SPEED = 5.0
@onready var player_mesh = $PlayerMesh
@onready var health_controller = $HealthController
@onready var hand_controller = $PlayerMesh/weapon_holder
var current_y_rotation := 0.0

@onready var jetpack_sound: AudioStreamPlayer3D = $JetpackLoop


# Rotación horizontal del jugador
const ROTATION_SPEED = 6.0
const ROTATION_SHOOT_SPEED = 15.0

func _ready() -> void:
	# Añade el modelo 3D visual al esqueleto del jugador
	$PlayerMesh/Mesh.add_child(player_model)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var angle_step := deg_to_rad(5)  # Sensibilidad del scroll

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_vertical_angle -= angle_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_vertical_angle += angle_step

		# Limita el ángulo vertical deseado
		target_vertical_angle = clamp(target_vertical_angle, deg_to_rad(min_y_angle_deg), deg_to_rad(max_y_angle_deg))

func _physics_process(delta: float) -> void:
	if GameManager.currentState == GameManager.State.Ending:
		player_mesh.visible = false
		$CanvasLayer/HUD.visible = false
		$CanvasLayer/Game_Over.visible = false
		$CanvasLayer/Dialogue.visible = false
		camera.current = false
		return
	
	#Detener el movimiento si hay un dialogo
	check_dialog_state(delta)
	
	# Aplica impulso a cuerpos rígidos con los que colisiona
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision and collision.get_collider() is RigidBody3D:
			var rigid = collision.get_collider() as RigidBody3D
			var force_dir = velocity.normalized()
			rigid.apply_central_impulse(force_dir * 0.5)

	# Procesa funcionalidades del jugador
	handle_jetpack(delta)
	handle_shooting(delta)
	handle_movement(delta)

	# Interpolación suave hacia el ángulo deseado
	vertical_angle = lerp(vertical_angle, target_vertical_angle, vertical_angle_lerp_speed * delta)

	# Aplicar la rotación suavizada a la cámara
	var rot = cam_node.rotation
	rot.x = vertical_angle
	cam_node.rotation = rot

	# Cambia al modo construcción si se activa la acción correspondiente
	if Input.is_action_just_pressed("Building_Mode"):
		BuildManager.ChangeState()

func handle_jetpack(delta: float) -> void:
	if DialogManager.is_dialogue_active:
		return
	
	$PlayerMesh/Trail_Node.visible = is_jetpacking
	
	if is_jetpacking:
		if !jetpack_sound.playing:
			jetpack_sound.play()
	else:
		jetpack_sound.stop()

	# Aplica gravedad personalizada si no está en el suelo
	if not is_on_floor():
		velocity.y += -10.0 * delta
	else:
		velocity.y = 0
		if recharge_timer >= recharge_delay:
			if jetpack_time_left < JETPACK_TIME:
				jetpack_time_left = min(jetpack_time_left + delta, JETPACK_TIME)
		else:
			recharge_timer += delta

	# Actualiza la barra visual del jetpack
	if jetpack_bar:
		jetpack_bar.value = (jetpack_time_left / JETPACK_TIME) * jetpack_bar.max_value

	# Maneja el cooldown del jetpack
	if not jetpack_enabled:
		jetpack_cooldown_timer += delta
		if jetpack_cooldown_timer >= 0.15:
			jetpack_enabled = true
			jetpack_cooldown_timer = 0.0

	# Activa el uso del jetpack si es posible
	if jetpack_enabled and jetpack_time_left > 0 and Input.is_action_pressed("jump"):
		recharge_timer = 0
		jetpack_time_left = max(jetpack_time_left - delta, 0)

		if not is_jetpacking:
			starting_jetpack_y = global_transform.origin.y
			current_max_height = jetpack_min_height
			current_lift = lift_min_value
			is_jetpacking = true

		current_lift = min(current_lift + lift_increase_speed * delta, JETPACK_LIFT)
		current_max_height = min(current_max_height + height_increase_speed * delta, MAX_JETPACK_HEIGHT)

		var relative_max = starting_jetpack_y + current_max_height
		var absolute_max = JETPACK_MAX_ABSOLUTE_Y
		var effective_max_height = min(relative_max, absolute_max)

		if global_transform.origin.y < effective_max_height:
			velocity.y = current_lift
		else:
			velocity.y = 0
	else:
		if is_jetpacking:
			is_jetpacking = false
			jetpack_enabled = false

func handle_shooting(delta: float) -> void:
	if DialogManager.is_dialogue_active:
		return

	# Obtiene el arma actual del jugador
	var current_weapon = hand_controller.get_current_weapon()

	# Controla la rotación y el disparo mientras se apunta
	if Input.is_action_pressed("right_click") and current_weapon and not BuildManager.Building:
		var offset = -PI * 0.05
		var screen_pos = camera.unproject_position(global_transform.origin)
		var mouse_pos = get_viewport().get_mouse_position()
		var angle = screen_pos.angle_to_point(mouse_pos)

		var direction_to_mouse = Vector3(cos(angle + offset), 0, sin(angle + offset)).normalized()
		look_in_direction(direction_to_mouse, delta, ROTATION_SHOOT_SPEED)

		if Input.is_action_pressed("left_click"):
			current_weapon.shoot()

	# Detiene el disparo al soltar el clic
	if Input.is_action_just_released("left_click") or Input.is_action_just_released("right_click"):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()

func handle_movement(delta: float) -> void:
	if DialogManager.is_dialogue_active:
		return

	# Calcula dirección del input y movimiento
	var current_weapon = hand_controller.get_current_weapon()
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_rot := Input.get_axis("ui_left", "ui_right")
	var is_moving = input_dir.length() > 0.1
	var direction := (global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Rota el personaje con teclas de rotación
	if input_rot:
		global_rotate(up_direction, PI * -1.7 * delta * input_rot)
		input_dir = Vector2.ZERO

	# Determina velocidad y animación según situación
	if is_jetpacking:
		current_speed = WALK_SPEED
		player_model.jump()
	elif Input.is_action_pressed("right_click") and current_weapon and not BuildManager.Building:
		current_speed = AIM_SPEED
	elif Input.is_action_pressed("sprint"):
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if is_moving and not (Input.is_action_pressed("right_click") and current_weapon and not BuildManager.Building):
		look_in_direction(direction, delta, ROTATION_SPEED)

	move_and_slide()

	# Aplica animaciones según el estado del jugador
	if not is_on_floor():
		if velocity.y < 0:
			player_model.fall()
		else:
			player_model.jump()
	elif is_moving:
		var target_blend = 0.0
		var anim_speed = 1.0

		if Input.is_action_pressed("sprint") and not Input.is_action_pressed("right_click"):
			target_blend = 1.0
			anim_speed = 1.3
		elif Input.is_action_pressed("right_click"):
			target_blend = 0.1
			anim_speed = 0.55

		player_model.walk_run_blending = lerp(player_model.walk_run_blending, target_blend, delta * BLEND_SPEED)
		player_model.set_anim_speed(anim_speed)
		player_model.walk()
	else:
		player_model.walk_run_blending = lerp(player_model.walk_run_blending, 0.0, delta * BLEND_SPEED)
		player_model.idle()

func look_in_direction(direction: Vector3, delta: float, rotationSpeed: float) -> void:
	# Gira suavemente el personaje hacia una dirección objetivo
	var target_rotation = atan2(-direction.x, -direction.z)
	var current_rotation = player_mesh.rotation.y
	player_mesh.rotation.y = lerp_angle(current_rotation, target_rotation, rotationSpeed * delta)

# Controla el estado del jugador cuando hay un dialogo
func check_dialog_state(delta: float) -> void:
	# Bloqueo por diálogo activo
	if DialogManager.is_dialogue_active:
		# Bloquear movimiento, disparo y construcción
		$CanvasLayer/HUD.visible = false
		velocity = Vector3.ZERO
		move_and_slide()
		player_model.idle()
		if BuildManager.CurrentSpawnable:
			BuildManager.CurrentSpawnable = null
		
		hand_controller.hide_weapon()
		
		# Suavemente rotar el jugador hacia la cámara
		var to_camera = (camera.global_transform.origin - global_transform.origin)
		to_camera.y = 0
		to_camera = to_camera.normalized()
		look_in_direction(to_camera, delta, 4.0)

		# Cámara: suavemente rotar y hacer zoom
		target_vertical_angle = deg_to_rad(-20.0)
		camera.fov = lerp(camera.fov, 30.0, 3.0 * delta)  # Zoom in

		return  # No ejecutar más lógica mientras hay diálogo

	else:
		# Restaurar cámara cuando no hay diálogo
		$CanvasLayer/HUD.visible = true
		camera.fov = lerp(camera.fov, 60.0, 3.0 * delta)  # Zoom out
		hand_controller.show_weapon()

#Metodo para visualizar el daño en el jugador
func is_damage_visual():
	var tween = create_tween()
	var mesh = player_mesh.get_node_or_null("Mesh/GDbotSkin/gdbot/Armature/Skeleton3D/gdbot_mesh")

	var original_scale = player_mesh.scale
	var enlarged_scale = original_scale * 1.2

	$Hit.play()
	
	# Escalado por daño
	tween.tween_property(player_mesh, "scale", enlarged_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_mesh, "scale", original_scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func die():
	$CanvasLayer/Game_Over.show_game_over()
