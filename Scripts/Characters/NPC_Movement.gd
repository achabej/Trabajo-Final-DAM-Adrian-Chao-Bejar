extends CharacterBody3D

@onready var nav = $"NavigationAgent3D"
@onready var mesh = preload("res://addons/Godot_4_3D_Characters/addons/gdquest_beetle_bot/beetlebot_skin.tscn").instantiate()

@export var wander_radius: float = 5.0
@export var wander_wait_time: float = randf() * 2
@export var speed: float = 5.0                       # Velocidad del NPC
@export var min_distance_to_player: float = 6.0     # Distancia mínima para acercarse al jugador
@export var alert_time: float = 0.7                 # Tiempo que está en estado alerta
@export var attack_distance: float = 4.0             # Distancia para atacar

var current_state = State.Wandering
var wander_timer = 0.0
var alert_timer = 0.0
var attack_timer = 0.0
var player_in_range: bool = false
var NPC_mesh
var is_waiting: bool = false
var is_attacking : bool = false

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player: Node3D = null

enum State {
	Wandering,
	Alert,
	Follow,
	Attack
}

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	else:
		print("❌ No se encontró el jugador en el grupo 'Player'")
		
	$Mesh.add_child(mesh)
	NPC_mesh = $Mesh.get_child(0)

func _on_body_entered(body):
	if body == player:
		player_in_range = true
		current_state = State.Alert
		alert_timer = 0.0
		print("Jugador detectado, pasando a ALERT")

func _on_body_exited(body):
	if body == player:
		player_in_range = false
		current_state = State.Wandering
		is_waiting = true
		wander_timer = 0.0
		velocity = Vector3.ZERO
		move_and_slide()
		NPC_mesh.idle()  # Forzar animación idle
		print("Jugador perdido, pasando a WANDERING")


func _process(delta):
	match current_state:
		State.Wandering:
			_state_wandering(delta)
		State.Alert:
			_state_alert(delta)
		State.Follow:
			_state_follow(delta)
		State.Attack:
			_state_attack(delta)
	
	match current_state:
		State.Wandering, State.Follow:
			if velocity.length() > 0:
				NPC_mesh.walk()
			else:
				NPC_mesh.idle()
		State.Alert:
				NPC_mesh.idle()

func _state_wandering(delta):
	if is_waiting:
		wander_timer += delta
		if wander_timer >= wander_wait_time:
			is_waiting = false
			wander_timer = 0.0
			_choose_new_wander_target()
	else:
		if nav_agent.is_navigation_finished():
			is_waiting = true
			wander_timer = 0.0
			velocity = Vector3.ZERO
			move_and_slide()
		else:
			var dir = (nav_agent.get_next_path_position() - global_transform.origin).normalized()
			velocity = dir * speed
			move_and_slide()
			_rotate_mesh_towards(dir, delta)

func _choose_new_wander_target():
	var random_direction = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1, 1)
	).normalized()
	var random_target = global_transform.origin + random_direction * wander_radius
	nav_agent.target_position = random_target

func _state_alert(delta):
	alert_timer += delta
	velocity = Vector3.ZERO
	move_and_slide()
	
	# Mirar hacia el jugador sin moverse
	if player:
		var dir = (player.global_transform.origin - global_transform.origin).normalized()
		_rotate_mesh_towards(dir, delta)
	
	# Pasar a Follow si el tiempo de alerta se cumple
	if alert_timer >= alert_time:
		current_state = State.Follow
		print("Tiempo alerta terminado, pasando a FOLLOW")

func _state_follow(delta):
	if not player_in_range:
		# Si jugador ya no está en el área, regresa a wander y idle
		current_state = State.Wandering
		is_waiting = true
		wander_timer = 0.0
		velocity = Vector3.ZERO
		move_and_slide()
		NPC_mesh.idle()  # Forzar idle para que no parezca corriendo en el sitio
		print("Jugador fuera de rango, pasando a WANDERING")
		return

	# Moverse hacia el jugador
	var dir = (player.global_transform.origin - global_transform.origin).normalized()
	nav_agent.target_position = player.global_transform.origin
	velocity = dir * speed
	move_and_slide()
	_rotate_mesh_towards(dir, delta)

	# Si está muy cerca, atacar
	if (player.global_transform.origin - global_transform.origin).length() <= attack_distance:
		current_state = State.Attack
		attack_timer = 0.0
		print("Jugador cerca, pasando a ATTACK")

func _state_attack(delta):
	if not is_attacking:
		NPC_mesh.attack()
		player.get_node("HealthController").damage(5)
		is_attacking = true
		attack_timer = 0.0

	attack_timer += delta

	velocity = Vector3.ZERO
	move_and_slide()

	if player:
		var dir = (player.global_transform.origin - global_transform.origin).normalized()
		_rotate_mesh_towards(dir, delta)

	# Duración del ataque
	if attack_timer >= 1.2:
		is_attacking = false

		# Si jugador salió del área, regresa a wander
		if not player_in_range:
			current_state = State.Wandering
		else:
			# Si jugador está fuera del rango de ataque, vuelve a follow
			var dist = (player.global_transform.origin - global_transform.origin).length()
			if dist > attack_distance:
				current_state = State.Follow


# Función para rotar el mesh hacia la dirección del movimiento
func _rotate_mesh_towards(direction: Vector3, delta: float) -> void:
	if direction.length() == 0:
		return
	
	# Obtener la rotación Y actual del mesh
	var current_yaw = mesh.rotation.y
	
	# Calcular la rotación deseada hacia la dirección (solo Y)
	var target_direction = direction.normalized()
	var target_yaw = atan2(target_direction.x, target_direction.z)
	
	# Ajustar el target_yaw sumando 180 grados (en radianes) si el mesh está invertido
	target_yaw += deg_to_rad(180)
	
	# Interpolar la rotación Y para un giro suave
	var new_yaw = lerp_angle(current_yaw, target_yaw, 5.0 * delta)
	
	# Aplicar la nueva rotación (solo en Y)
	mesh.rotation.y = new_yaw

func die():
	# Instanciar el efecto Poof y añadirlo como hijo al NPC
	var poof_effect = preload("res://Prefabs/Effects/Poof_Effect.tscn").instantiate()
	poof_effect.global_transform.origin = global_transform.origin
	get_parent().add_child(poof_effect)

	# Ejecutar animación power_off en el mesh
	mesh.power_off()

	# Crear tween para la animación de escala
	var tween = create_tween()

	# Escalar un poco más (por ejemplo 1.2x)
	tween.tween_property(self, "scale", Vector3.ONE * 1.2, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Luego encoger hasta cero
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Al finalizar la tween, eliminar el NPC
	tween.connect("finished", Callable(self, "queue_free"))
