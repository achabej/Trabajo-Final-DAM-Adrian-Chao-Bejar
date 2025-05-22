extends CharacterBody3D

#CONFIGURACION MOVIMIENTO
@export var WALK_SPEED = 6.5
@export var RUN_SPEED = 10
@export var AIM_SPEED = 3

#CONFIGURACION SALTO / JETPACK
@export var JETPACK_LIFT = 8
@export var MAX_JETPACK_HEIGHT = 2.0  
@export var JETPACK_TIME = 2.0 
@export var jetpack_enabled: bool = true 
@onready var jetpack_bar = $"CanvasLayer/Jetpack_Bar"
@export var JETPACK_MAX_ABSOLUTE_Y: float = 10.0 
var jetpack_cooldown_timer := 0.0
var jetpack_min_height := 4.0
var current_max_height := 4.0
var height_increase_speed := 8

# NUEVAS VARIABLES
var lift_min_value := 4.0
var current_lift := 4.0
var lift_increase_speed := 6.0

#VARIABLES LOCALES
var current_speed = WALK_SPEED
var jetpack_time_left = JETPACK_TIME
var is_jetpacking = false
var recharge_delay = 0.5 
var recharge_timer = 0.0 
var starting_jetpack_y = 0.0

#CONFIGURACION CAMARA
@export var camera: Camera3D
@export var rotation_speed: float = 0.01  
@export var min_y_angle_deg: float = -90.0 
@export var max_y_angle_deg: float = -45.0
@onready var cam_node = $CamNode
var mouse_delta_y := 0.0

# Modelo del jugador
@onready var player_model = preload("res://addons/Godot_4_3D_Characters/addons/gdquest_gdbot/gdbot_skin.tscn").instantiate()
const BLEND_SPEED = 5.0 
@onready var player_mesh = $PlayerMesh 
@onready var health_controller = $HealthController
@onready var hand_controller = $PlayerMesh/weapon_holder  
var current_y_rotation := 0.0  

#ROTACION HORIZONTAL
const ROTATION_SPEED = 6.0
const ROTATION_SHOOT_SPEED = 15.0

func _ready() -> void:
	$PlayerMesh/Mesh.add_child(player_model) 

func _input(event):
	if Input.is_action_pressed("Rotate_Cam") and event is InputEventMouseMotion:
		mouse_delta_y = -event.relative.y

func _physics_process(delta: float) -> void:

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision and collision.get_collider() is RigidBody3D:
			var rigid = collision.get_collider() as RigidBody3D
			var force_dir = velocity.normalized()
			rigid.apply_central_impulse(force_dir * 0.5) 
	
	handle_jetpack(delta)
	handle_shooting(delta)
	handle_movement(delta)

	if Input.is_action_pressed("Rotate_Cam"):
		current_y_rotation = clamp(current_y_rotation + mouse_delta_y * rotation_speed, deg_to_rad(min_y_angle_deg), deg_to_rad(max_y_angle_deg))
		var rot = cam_node.rotation
		rot.x = current_y_rotation
		cam_node.rotation = rot
	mouse_delta_y = 0.0

	if Input.is_action_just_pressed("Building_Mode"):
		BuildManager.ChangeState()

# --------------------------
# JETPACK CON CAMBIOS AQUI
# --------------------------
func handle_jetpack(delta: float) -> void:
	if not is_on_floor():
		velocity.y += -10.0 * delta
	else:
		velocity.y = 0
		if recharge_timer >= recharge_delay:
			if jetpack_time_left < JETPACK_TIME:
				jetpack_time_left = min(jetpack_time_left + delta, JETPACK_TIME)
		else:
			recharge_timer += delta

	if jetpack_bar:
		jetpack_bar.value = (jetpack_time_left / JETPACK_TIME) * jetpack_bar.max_value

	if not jetpack_enabled:
		jetpack_cooldown_timer += delta
		if jetpack_cooldown_timer >= 0.75:
			jetpack_enabled = true
			jetpack_cooldown_timer = 0.0

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

# --------------------------
# CONTROL DE DISPARO
# --------------------------
func handle_shooting(delta: float) -> void:
	var current_weapon = hand_controller.get_current_weapon()

	if Input.is_action_pressed("right_click") and current_weapon and !BuildManager.Building:
		var offset = -PI * 0.05
		var screen_pos = camera.unproject_position(global_transform.origin)
		var mouse_pos = get_viewport().get_mouse_position()
		var angle = screen_pos.angle_to_point(mouse_pos)

		var direction_to_mouse = Vector3(cos(angle + offset), 0, sin(angle + offset)).normalized()
		look_in_direction(direction_to_mouse, delta, ROTATION_SHOOT_SPEED)

		if Input.is_action_pressed("left_click"):
			current_weapon.shoot()

	if (Input.is_action_just_released("left_click") or Input.is_action_just_released("right_click")):
		if current_weapon and current_weapon.has_method("stop_shooting"):
			current_weapon.stop_shooting()

# --------------------------
# MOVIMIENTO DEL PERSONAJE
# --------------------------
func handle_movement(delta: float) -> void:
	var current_weapon = hand_controller.get_current_weapon()
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_rot := Input.get_axis("ui_left", "ui_right")
	var is_moving = input_dir.length() > 0.1
	var direction := (global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if input_rot:
		global_rotate(up_direction, PI * -1.7 * delta * input_rot)
		input_dir = Vector2.ZERO

	if is_jetpacking:
		current_speed = WALK_SPEED
		player_model.jump()
	elif Input.is_action_pressed("right_click") and current_weapon and !BuildManager.Building:
		current_speed = AIM_SPEED
	elif Input.is_action_pressed("sprint"):
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if is_moving and not (Input.is_action_pressed("right_click") and current_weapon and !BuildManager.Building):
		look_in_direction(direction, delta, ROTATION_SPEED)

	move_and_slide()

	if not is_on_floor():
		if velocity.y < 0:
			player_model.fall()
		else:
			player_model.jump()
	elif is_moving:
		var target_blend = 0.0
		var anim_speed = 1.0

		if Input.is_action_pressed("sprint") and !Input.is_action_pressed("right_click"):
			target_blend = 1.0
			anim_speed = 1.3
		elif Input.is_action_pressed("right_click"):
			target_blend = 0.1
			anim_speed = 0.55
		else:
			target_blend = 0.0
			anim_speed = 1.0

		player_model.walk_run_blending = lerp(player_model.walk_run_blending, target_blend, delta * BLEND_SPEED)
		player_model.set_anim_speed(anim_speed)
		player_model.walk()
	else:
		player_model.walk_run_blending = lerp(player_model.walk_run_blending, 0.0, delta * BLEND_SPEED)
		player_model.idle()

# --------------------------
# ROTACIÓN DEL JUGADOR
# --------------------------
func look_in_direction(direction: Vector3, delta: float, rotationSpeed: float) -> void:
	var target_rotation = atan2(-direction.x, -direction.z)  
	var current_rotation = player_mesh.rotation.y
	player_mesh.rotation.y = lerp_angle(current_rotation, target_rotation, rotationSpeed * delta)
