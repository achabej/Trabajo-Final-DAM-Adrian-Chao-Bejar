extends Node3D
class_name MachineWithInput

@export var spawn_position: Node3D
@export var spawn_interval: float = 3.0
@onready var label: Label3D = $Label3D

# Materiales necesarios
@export var required_materials: Array[Dictionary] = [
	{
		"Inputs": {},
		"Mat Spawn": null
	}
]

# Animación
@onready var mesh: Node3D = $"../Mesh"
var anim_time := 0.0
var original_scale := Vector3.ONE

var material_storage := {}
@onready var spawn_timer: Timer = $SpawnTimer
var is_active: bool = false
var current_conveyor: Node3D = null
var blocking_materials := 0

func _ready() -> void:
	original_scale = mesh.scale

	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = true
	spawn_timer.connect("timeout", _on_spawn_timer_timeout)

	for recipe in required_materials:
		var inputs: Dictionary = recipe.get("Inputs", {})
		for mat in inputs.keys():
			if not material_storage.has(mat):
				material_storage[mat] = 0


	var detector = get_node_or_null("ConveyDetector")
	if detector:
		detector.monitoring = true
		detector.connect("body_entered", _on_convey_detector_body_entered)
		detector.connect("body_exited", _on_convey_detector_body_exited)
	
	var mat_enter_points = get_node_or_null("MatEnterPoints")
	if mat_enter_points:
		for enter in mat_enter_points.get_children():
			var area := enter.get_node_or_null("Area3D")
			if area:
				area.connect("body_entered", _on_material_entered)

func _process(delta: float) -> void:
	# Si tiene todos los materiales, empieza a producir
	if not is_active and _has_all_required_materials():
		is_active = true
		spawn_timer.start()
		#print("✅ Todos los materiales disponibles, iniciando producción")

	# Animación mientras está activo
	if is_active:
		anim_time += delta * 5.0  # Velocidad de animación
		var scale_y = 1.0 + 0.1 * sin(anim_time)
		mesh.scale.y = original_scale.y * scale_y
	else:
		mesh.scale = original_scale	

func _has_all_required_materials() -> bool:
	for recipe in required_materials:
		var inputs: Dictionary = recipe.get("Inputs", {})
		var can_produce := true

		for material in inputs.keys():
			var required_amount = inputs[material]
			if material_storage.get(material, 0) < required_amount:
				can_produce = false
				break

		if can_produce:
			return true  # ✅ Esta receta sí se puede producir

	return false  # ❌ Ninguna receta se puede producir

func spawn_mat() -> void:
	if not spawn_position or not is_instance_valid(current_conveyor):
		return
	
	var best_recipe: Dictionary = {}
	var best_fill_ratio: float = 0.0

	for recipe in required_materials:
		var inputs: Dictionary = recipe.get("Inputs", {})
		var min_ratio := INF

		var can_produce := true
		for material in inputs.keys():
			var required = inputs[material]
			var available = material_storage.get(material, 0)

			if available < required:
				can_produce = false
				break

			var ratio = float(available) / float(required)
			min_ratio = min(min_ratio, ratio)

		if can_produce and min_ratio > best_fill_ratio:
			best_fill_ratio = min_ratio
			best_recipe = recipe

	if best_recipe.is_empty():
		return

	# Consumir materiales
	for material in best_recipe["Inputs"].keys():
		var amount = best_recipe["Inputs"][material]
		material_storage[material] -= amount

	# 🔁 Intentar recoger más materiales después de liberar espacio
	_collect_pending_materials_from_inputs()
	# Instanciar resultado
	var prefab: PackedScene = best_recipe["Mat Spawn"]
	var instance = prefab.instantiate()
	get_tree().get_current_scene().add_child(instance)
	instance.global_position = spawn_position.global_position
	instance.add_to_group("Ignore_Build_Validation")

	var manager = current_conveyor.get_node_or_null("Convey_Manager")
	if manager and manager is ConveyScript and manager.current_material == null:
		manager.current_material = instance
		

#Comprobamos si hay materiales en las entradas para recoger
func _collect_pending_materials_from_inputs() -> void:
	var mat_enter_points := get_node_or_null("MatEnterPoints")
	if mat_enter_points:
		for enter in mat_enter_points.get_children():
			var area := enter.get_node_or_null("Area3D")
			if area:
				for body in area.get_overlapping_bodies():
					if body.has_method("get_material_type"):
						var mat_type : String = body.get_material_type()
						if can_accept_material(mat_type):
							receive_material(body, mat_type)

#Metodo que se llama cuando termina el contador
func _on_spawn_timer_timeout() -> void:
	if blocking_materials == 0:
		spawn_mat()
	is_active = false

func _check_activation():
	if not is_active and _has_all_required_materials():
		is_active = true
		spawn_timer.start()

# Capacidad máxima basada en materiales requeridos
func get_max_material_storage() -> int:
	var total := 0
	for recipe in required_materials:
		var inputs: Dictionary = recipe.get("Inputs", {})
		for value in inputs.values():
			total += value
	return total

# Metodo que se llama cuando hay filtro y es para comprobar que tiene espacio para el material
func can_accept_material(mat_type: String) -> bool:
	var total := 0
	for stored in material_storage.values():
		total += stored
	return total <= get_max_material_storage()

# Metodo que se llama cuando hay filtro y es para añadir el material a la fabrica
func receive_material(body: Node3D, mat_type: String) -> void:
	material_storage[mat_type] += 1
	body.queue_free()
	_check_activation()

func _on_material_entered(body: Node3D) -> void:
	if not get_parent().is_in_group("Build"):
		return

	if not body.has_method("get_material_type"):
		return

	var mat_type = body.get_material_type()
	print(mat_type)

	if not can_accept_material(mat_type):
		# print("⛔ No se puede aceptar más de este material:", mat_type)
		return

	if material_storage.has(mat_type):
		material_storage[mat_type] += 1
		body.queue_free()
		_check_activation()
	print(material_storage)

func _on_convey_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group("Build") and body.is_in_group("Convey") and is_instance_valid(body):
		current_conveyor = body
	elif body.is_in_group("Material"):
		blocking_materials += 1
		#print("🚫 Zona de spawn bloqueada")

func _on_convey_detector_body_exited(body: Node3D) -> void:
	if body == current_conveyor:
		current_conveyor = null
	elif body.is_in_group("Material"):
		blocking_materials = max(0, blocking_materials - 1)
		#print("✅ Zona de spawn libre")
