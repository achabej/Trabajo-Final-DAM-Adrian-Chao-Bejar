extends Area3D
class_name ConveyScript

# Velocidad del movimiento del material sobre la cinta
@export var convey_velocity = 4

# RayCast para detectar el siguiente conveyor (salida normal)
@export var raycast: RayCast3D

# Referencia al centro visual de la cinta y una etiqueta de depuración
@onready var center = $Center
@onready var debug_label: Label3D = $Label3D

# Raycasts para entradas múltiples (mergers)
var entrada_rays: Array = []

# RayCast para salida en modo merger
var salida_raycast: RayCast3D = null

# Temporizador que regula intentos de absorción en mergers
var timer: Timer = null

# Si esta cinta es un merger (tiene múltiples entradas)
var is_merger := false

# Índice rotativo para verificar entradas en mergers
var entrada_index := 0

# Referencia al material actual que se está moviendo
var current_material: RigidBody3D = null

# Posición objetivo del material en movimiento
var target_position: Vector3 = Vector3.ZERO

# Referencia al siguiente conveyor hacia donde se moverá el material
var next_convey_manager: Node = null

# Flag que indica si el conveyor está moviendo material actualmente
var is_moving := false

# Lista de conveyors detectados por este nodo
var detected_conveyors: Array = []

# Referencia al conveyor que nos detectó (para evitar duplicados)
var current_detected_conveyor: Node3D

# Conveyor que actualmente ha solicitado entrada a este nodo
var active_entry: Node = null


# -----------------------------------------------
# Método llamado al inicio. Registra el conveyor y detecta configuración.
func _ready():
	ConveyorManager.register_conveyor(self)

	entrada_rays = $Entradas.get_children()
	salida_raycast = $Convey_Manager/RayCast3D
	timer = $MergerTimer
	timer.timeout.connect(_on_merger_tick)

	is_merger = entrada_rays.size() > 0 and salida_raycast != null and timer != null


# -----------------------------------------------
# Se ejecuta cada frame. Limpia referencias inválidas.
func _process(_delta):
	if current_material and not is_instance_valid(current_material):
		current_material = null
	if active_entry != null and not is_instance_valid(active_entry):
		active_entry = null
	
	cleanup_invalid_references()


# -----------------------------------------------
# Se ejecuta cuando el nodo se elimina. Limpia referencias en otros conveyors.
func _exit_tree():
	ConveyorManager.unregister_conveyor(self)

	for body in get_overlapping_bodies():
		if body.is_in_group("Material") and is_instance_valid(body):
			body.queue_free()

	# Limpieza de las referencias  para evitar bloqueos
	for conveyor in ConveyorManager.get_all_conveyors():
		if conveyor.current_material != null:
			conveyor.try_move()
			
		if conveyor.detected_conveyors.has(self):
			conveyor.detected_conveyors.erase(self)

		if conveyor.active_entry == self:
			conveyor.active_entry = null

		if conveyor.next_convey_manager == self:
			conveyor.next_convey_manager = null
			conveyor.is_moving = false

	if is_instance_valid(next_convey_manager) and next_convey_manager.active_entry == self:
		next_convey_manager.active_entry = null


# -----------------------------------------------
# Detecta cuando entra un material o una máquina construida
func _on_body_entered(body: Node3D) -> void:
	if get_parent().is_in_group("Build") and body.get_parent().is_in_group("Build"):
		var machine_root = find_parent_with_group(body, "Machine")
		if machine_root:
			machine_root.set("current_conveyor", self.get_parent())
	elif body.is_in_group("Material") and current_material == null:
		current_material = body
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO


# -----------------------------------------------
# Detecta cuándo un material se ha ido completamente
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Material") and body == current_material:
		await get_tree().process_frame
		if not get_overlapping_bodies().has(body):
			current_material = null


# -----------------------------------------------
# Solicita mover el material al siguiente conveyor
func try_move():
	if not get_parent().is_in_group("Build"):
		return
	if is_moving or current_material == null:
		return

	update_next_convey()

	if not is_instance_valid(next_convey_manager):
		next_convey_manager = null
		return

	if not next_convey_manager.request_entry(self):
		return

	next_convey_manager.is_moving = true
	next_convey_manager.current_material = current_material
	is_moving = true

	var from_pos = current_material.global_position
	var to_pos = next_convey_manager.get_center_position()
	to_pos.y = from_pos.y

	var tween := create_tween()
	var distance = from_pos.distance_to(to_pos)
	var duration = distance / convey_velocity

	tween.tween_property(current_material, "global_position", to_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_movement_finished"))


# -----------------------------------------------
# Finaliza el movimiento, resetea estados
func _on_movement_finished():
	if is_instance_valid(next_convey_manager):
		next_convey_manager.is_moving = false
		next_convey_manager.active_entry = null
	
	current_material = null
	next_convey_manager = null
	is_moving = false


# -----------------------------------------------
# Lógica para mergers: intenta absorber materiales en la entrada
func _on_merger_tick():
	if current_material != null:
		try_send_to_output()
		return

	for i in range(entrada_rays.size()):
		var ray = entrada_rays[entrada_index]
		entrada_index = (entrada_index + 1) % entrada_rays.size()

		if ray.is_colliding():
			var material = ray.get_collider()
			if material and material.is_in_group("Material"):
				var source_convey = find_parent_with_group(material, "Convey")
				if source_convey:
					var source_manager = source_convey.get_node_or_null("Convey_Manager")
					if source_manager is ConveyScript and source_manager.current_material == material:
						current_material = material
						move_material_to_center(material)
						break


# -----------------------------------------------
# Anima el movimiento de entrada hacia el centro del merger
func move_material_to_center(material: RigidBody3D):
	var to_pos = get_center_position()
	to_pos.y = material.global_position.y

	var tween = create_tween()
	tween.tween_property(material, "global_position", to_pos, convey_velocity)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_input_move_finished"))


# -----------------------------------------------
# Intenta enviar el material hacia la salida
func try_send_to_output():
	if current_material == null or not salida_raycast.is_colliding():
		return

	var salida_collider = salida_raycast.get_collider()
	if salida_collider:
		var salida_convey = find_parent_with_group(salida_collider, "Convey")
		if salida_convey:
			var salida_manager = salida_convey.get_node_or_null("Convey_Manager")
			if salida_manager is ConveyScript and salida_manager.current_material == null:
				var to_pos = salida_manager.get_center_position()
				to_pos.y = current_material.global_position.y

				var tween = create_tween()
				tween.tween_property(current_material, "global_position", to_pos, convey_velocity)
				tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_callback(Callable(self, "_on_output_move_finished"))


# -----------------------------------------------
# Libera el material después de enviarlo
func _on_output_move_finished():
	current_material = null


# -----------------------------------------------
# Detecta el conveyor de salida mediante el raycast
func update_next_convey():
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider:
			var convey_node = find_parent_with_group(collider, "Convey")
			if convey_node:
				var manager = convey_node.get_node_or_null("Convey_Manager")
				if manager and manager != self:
					target_position = manager.get_center_position()
					next_convey_manager = manager
					if not manager.detected_conveyors.has(self):
						manager.detected_conveyors.append(self)
						current_detected_conveyor = manager


# -----------------------------------------------
# Devuelve la posición central de la cinta
func get_center_position() -> Vector3:
	return center.global_transform.origin


# -----------------------------------------------
# Busca el nodo padre que pertenezca al grupo dado
func find_parent_with_group(node: Node, group_name: String) -> Node:
	var current = node
	while current:
		if current.is_in_group(group_name):
			return current
		current = current.get_parent()
	return null


# -----------------------------------------------
# Solicita mover un material a esta cinta
func request_entry(from_conveyor: Node) -> bool:
	if current_material != null or is_moving:
		return false

	if active_entry == null:
		active_entry = from_conveyor
		return true

	return active_entry == from_conveyor

# Limpia referencias vacias entre conveyors (llamado en _process)
func cleanup_invalid_references():
	if not is_instance_valid(next_convey_manager):
		next_convey_manager = null
	if not is_instance_valid(active_entry):
		active_entry = null
	if not is_instance_valid(current_detected_conveyor):
		current_detected_conveyor = null
	detected_conveyors = detected_conveyors.filter(func(c): return is_instance_valid(c))
