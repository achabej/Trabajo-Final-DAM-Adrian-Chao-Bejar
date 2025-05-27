extends Area3D
class_name ConveyScript

@export var convey_velocity = 6.0
@export var raycast: RayCast3D

@onready var center = $Center
@onready var debug_label: Label3D = $Label3D

var entrada_rays: Array = []
var salida_raycast: RayCast3D = null
var entrada_index := 0

var current_material : CharacterBody3D = null
var target_position: Vector3 = Vector3.ZERO
var next_convey_manager: Node = null
var is_moving := false
var active_entry: Node = null

func _ready():
	ConveyorManager.register_conveyor(self)

	entrada_rays = $Entradas.get_children()
	salida_raycast = $Convey_Manager/RayCast3D

func _process(_delta):
	if current_material and not is_instance_valid(current_material):
		current_material = null
	if active_entry != null and not is_instance_valid(active_entry):
		active_entry = null
	
	$Label3D.text = str(active_entry)
	
	cleanup_invalid_references()

func _exit_tree():
	ConveyorManager.unregister_conveyor(self)
	for body in get_overlapping_bodies():
		if body.is_in_group("Material") and is_instance_valid(body):
			body.queue_free()

	for conveyor in ConveyorManager.get_all_conveyors():
		if conveyor.current_material != null:
			conveyor.try_move()
		if conveyor.active_entry == self:
			conveyor.active_entry = null
		if conveyor.next_convey_manager == self:
			conveyor.next_convey_manager = null
			conveyor.is_moving = false

	if is_instance_valid(next_convey_manager) and next_convey_manager.active_entry == self:
		next_convey_manager.active_entry = null

func _on_body_entered(body: Node3D) -> void:
	if !get_parent().is_in_group("Build"):
		return
	
	if body.get_parent().is_in_group("Build"):
		var machine_root = find_parent_with_group(body, "Machine")
		if machine_root:
			machine_root.set("current_conveyor", self.get_parent())
	elif body.is_in_group("Material") and current_material == null:
		current_material = body
		if body is CharacterBody3D:
			body.velocity = Vector3.ZERO

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Material") and body == current_material:
		await get_tree().process_frame
		if not is_instance_valid(body) or not get_overlapping_bodies().has(body):
			current_material = null

# Función asíncrona para mover el material suavemente hasta target_pos
func move_material_to(material: CharacterBody3D, target_pos: Vector3, speed: float) -> void:
	while is_instance_valid(material) and material.global_position.distance_to(target_pos) > 0.1:
		if not is_instance_valid(material):
			return
		var direction = (target_pos - material.global_position).normalized()
		material.global_position += direction * speed * get_process_delta_time()
		await get_tree().process_frame

	if is_instance_valid(material):
		material.global_position = target_pos

# Función principal para intentar mover el material al siguiente conveyor
func try_move() -> void:
	if is_moving or current_material == null or !get_parent().is_in_group("Build"):
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
	
	if next_convey_manager.active_entry == self and current_material == null:
		active_entry = null
		
	var from_pos = current_material.global_position
	var to_pos = next_convey_manager.get_center_position()
	to_pos.y = from_pos.y

	await move_material_to(current_material, to_pos, convey_velocity)
	
	_on_movement_finished()

func _on_movement_finished():
	if is_instance_valid(next_convey_manager):
		next_convey_manager.is_moving = false
		next_convey_manager.active_entry = null
	
	current_material = null
	next_convey_manager = null
	is_moving = false

func update_next_convey():
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider:
			var convey_node = find_parent_with_group(collider, "Convey")
			if convey_node:
				var manager = convey_node.get_node_or_null("Convey_Manager")
				if manager and manager != self and convey_node.is_in_group("Build"):
					target_position = manager.get_center_position()
					next_convey_manager = manager

func request_entry(from_conveyor: Node) -> bool:
	if current_material != null or is_moving:
		return false

	if active_entry == null:
		active_entry = from_conveyor
		return true

	return active_entry == from_conveyor

func cleanup_invalid_references():
	if not is_instance_valid(next_convey_manager):
		next_convey_manager = null
	if not is_instance_valid(active_entry):
		active_entry = null

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

func move_material_to_center(material: CharacterBody3D):
	var to_pos = get_center_position()
	to_pos.y = material.global_position.y

	# Usamos la función asíncrona para mover el material sin tween
	await move_material_to(material, to_pos, convey_velocity)

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

				await move_material_to(current_material, to_pos, convey_velocity)
				_on_output_move_finished()

func _on_output_move_finished():
	current_material = null

func get_center_position() -> Vector3:
	return center.global_transform.origin

func find_parent_with_group(node: Node, group_name: String) -> Node:
	var current = node
	while current:
		if current.is_in_group(group_name):
			return current
		current = current.get_parent()
	return null
