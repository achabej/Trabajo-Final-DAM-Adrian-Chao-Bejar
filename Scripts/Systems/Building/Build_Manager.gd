extends Node3D

# Prefabs de los edificios
var extractor : PackedScene = preload("res://Prefabs/Buildings/Extractor.tscn")
var convey_line : PackedScene = preload("res://Prefabs/Buildings/Convey_Line.tscn")
var convey_merger : PackedScene = preload("res://Prefabs/Buildings/Convey_Line.tscn")
var furnace : PackedScene = preload("res://Prefabs/Buildings/Furnace.tscn")
var steelRefinery : PackedScene = preload("res://Prefabs/Buildings/SteelRefinery.tscn")
var cristalRefinery : PackedScene
var chipsFactory : PackedScene = preload("res://Prefabs/Buildings/ChipsFactory.tscn")
var platesFactory : PackedScene = preload("res://Prefabs/Buildings/PlatesFactory.tscn")

#var test_cube_generator : PackedScene = preload("res://Prefabs/Buildings/Test_Cube_Generator.tscn")
#var convey_curve : PackedScene = preload("res://Prefabs/Buildings/Convey_Curve.tscn")

var building_costs = {
	"Extractor": {"Wood": 10, "Iron": 10},
	"Convey_Line": {"Iron": 2},
	"Furnace": {"Iron": 20},
	"SteelRefinery": {"Iron": 20, "Copper": 20, "Cristal": 15},
	"PlatesFactory": {"Iron": 15, "Copper": 10, "Wood": 10},
	"ChipsFactory": {"Iron": 15, "Copper": 15, "Cristal": 20}
}

@onready var grid_map : GridMap
var CurrentSpawnable: StaticBody3D = null
var AbleToBuild: bool = false
var OnGrid: bool = false
var TargetGridCell: Vector3 = Vector3.ZERO
var MoveSpeed: float = 15.0

#Cantidad materiales
var materiales = {
	"Wood" : 0,
	"Iron" : 25,
	"Copper" : 0,
	"Cristal" : 0
}

# Texturas
var building_green : Material = preload("res://Materials/Building/building_green.tres")
var building_red : Material = preload("res://Materials/Building/building_red.tres")
var basic_mat : Material = preload("res://Materials/Basic_Mat.tres")

# Reloj
var tick_active: bool = false
var tick_interval := 0.2 # segundos
var tick_timer := 0.0

# Referencias
@onready var Player = $Player
var BuildingUI: Control
var Weapon_Holder
var Building: bool = false

func init():
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		Player = players[0]
		BuildingUI = Player.find_child("Building_Buttons", true, false)
		Weapon_Holder = Player.find_child("PlayerMesh", true, false).find_child("weapon_holder", true, false)

		if BuildingUI:
			BuildingUI.visible = false
	else:
		print("Player no encontrado.")
		
	var nodes = get_tree().get_nodes_in_group("GridMap")
	if nodes != null:
		grid_map = nodes[0]
	else:
		print("❌ No se encontró GridMap")

func _process(delta):
	# Gestiona el reloj de las construcciones
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		tick_active = true
	else:
		tick_active = false
	
	if GameManager.currentState == GameManager.State.Building:
		material_controller()
		move_to_closest_tile(delta)
		place_building(delta)
		handle_deletion(delta)

#======= Gestión de materiales =======
func increase_mat(mat, amount):
	materiales[mat] += amount
	var canvas_node = Player.get_node("CanvasLayer").get_node("HUD")
	
	canvas_node.get_node("Materials").update_mat_UI()
	var label = "+%d %s" % [amount, mat]
	canvas_node.get_node("Mat_PopUp_Controller").call("show_material_popup", label, Color.GREEN)

func decrease_mat(mat, amount):
	if(materiales[mat] - amount >= 0):
		materiales[mat] -= amount
	else:
		amount = materiales[mat]
		materiales[mat] = 0
	var canvas_node = Player.get_node("CanvasLayer").get_node("HUD")

	canvas_node.get_node("Materials").update_mat_UI()

	var label = "-%d %s" % [amount, mat]
	canvas_node.get_node("Mat_PopUp_Controller").call("show_material_popup", label, Color.RED)

#======= Funciones de construcción =======
# Mueve la construccion a la casilla mas cercana
func move_to_closest_tile	(delta):
	if CurrentSpawnable == null:
		return

	var result = raycast_from_camera()

	if result:
		var cursor_pos = result.position
		var grid_pos = world_to_cell(cursor_pos)
		TargetGridCell = grid_pos
		var target_position = cell_to_world(grid_pos)

		CurrentSpawnable.global_position = CurrentSpawnable.global_position.lerp(target_position, MoveSpeed * delta)

# Coloca la construccion en la posicion del raton
func place_building(delta):
	if CurrentSpawnable == null:
		return

	var target_position = cell_to_world(TargetGridCell)
	CurrentSpawnable.global_position = CurrentSpawnable.global_position.lerp(target_position, MoveSpeed * delta)

	if is_near_target(CurrentSpawnable.global_position, target_position):
		CurrentSpawnable.global_position = target_position
	
	if OnGrid and AbleToBuild and Input.is_action_just_pressed("left_click"):
		var name = CurrentSpawnable.scene_file_path.get_file().get_basename()
		if not has_required_materials(name):
			print("No hay suficientes materiales para construir ", name)
			return
		
		consume_materials(name)
		update_materials_needed_UI(name)

		var obj = CurrentSpawnable.duplicate()
		grid_map.add_child(obj)
		obj.global_position = target_position

		var collision_shape = obj.get_node("CollisionShape3D")
		if collision_shape:
			collision_shape.disabled = false

		change_material(obj, basic_mat)
		obj.add_to_group("Build")
		obj.isBuild = true

		if obj.has_node("Test_Generator_Manager"):
			var gen = obj.get_node("Test_Generator_Manager")
			if gen.has_method("activate"):
				gen.activate()

	if Input.is_action_just_pressed("Rotate_Building"):
		rotate_building()

# Elimina una construccion seleccionada
func handle_deletion(delta):
	if Building and Input.is_action_just_pressed("Delete_Building"):
		var result = raycast_from_camera()

		if result:
			var body = result.collider
			if body and body.is_in_group("Build"):
				var name = body.scene_file_path.get_file().get_basename()

				refund_materials(name) 
				update_materials_needed_UI(name)
				
				body.queue_free()
				print("Edificio eliminado: ", body.name)

# Rota la construccion
func rotate_building():
	if CurrentSpawnable != null:
		CurrentSpawnable.rotation_degrees.y += 90
		if CurrentSpawnable.rotation_degrees.y >= 360:
			CurrentSpawnable.rotation_degrees.y = 0

#Comprueba la distancia entre la construccion y la celda
func is_near_target(current_pos: Vector3, target_pos: Vector3) -> bool:
	return current_pos.distance_to(target_pos) < 0.05

#Gestiona el material del currentspawnable
func material_controller():
	if not CurrentSpawnable:
		return

	var name = CurrentSpawnable.scene_file_path.get_file().get_basename()

	if OnGrid and AbleToBuild and has_required_materials(name): 
		change_material(CurrentSpawnable, building_green)
	else:
		change_material(CurrentSpawnable, building_red)

#Cambia el material del currentspawnable
func change_material(obj: Node3D, material: Material):
	if obj == null:
		return
	var mesh_node = obj.get_node("Mesh")
	if mesh_node:
		for child in mesh_node.get_children():
			if child is MeshInstance3D:
				child.material_override = material

#Cambia entre modo construir y modo libre
func ChangeState():
	var label = Player.get_node("CanvasLayer").get_node("HUD").get_node("Materials_Needed") as RichTextLabel

	if Input.is_action_just_pressed("Building_Mode"):
		BuildingUI.visible = not BuildingUI.visible
		Building = BuildingUI.visible

		# Mostrar u ocultar texto de materiales también
		label.visible = Building

		if Building:
			if Weapon_Holder:
				Weapon_Holder.visible = false
		else:
			if CurrentSpawnable:
				CurrentSpawnable.queue_free()
				CurrentSpawnable = null
			if Weapon_Holder:
				Weapon_Holder.visible = true
			label.text = ""


#Comprueba si se tienen los materiales necesarios
func has_required_materials(building_name: String) -> bool:
	if not building_costs.has(building_name):
		return true # Si no hay coste definido, dejar construir

	var cost = building_costs[building_name]
	for mat in cost:
		if materiales.get(mat, 0) < cost[mat]:
			return false
	return true

#Consume los materiales
func consume_materials(building_name: String):
	if not building_costs.has(building_name):
		return

	var cost = building_costs[building_name]
	for mat in cost:
		decrease_mat(mat, cost[mat])

func refund_materials(building_name: String):
	if not building_costs.has(building_name):
		return

	var cost = building_costs[building_name]
	for mat in cost:
		var refund_amount = int(cost[mat])
		increase_mat(mat, refund_amount)

# Funciones para spawnear construcciones
func SpawnExtractor():
	SpawnObj(extractor)

func SpawnConveyLine():
	SpawnObj(convey_line)
	
func SpawnConveyMerger():
	SpawnObj(convey_merger)

func SpawnFurnace():
	SpawnObj(furnace)
	
func SpawnSteelRefinery():
	SpawnObj(steelRefinery)
	
func SpawnChipsFactory():
	SpawnObj(chipsFactory)
	
func SpawnPlatesFactory():
	SpawnObj(platesFactory)

#func SpawnConveyCurve():
#	SpawnObj(convey_curve)2

#func SpawnTestCubeGenerator():
#	SpawnObj(test_cube_generator)
	
func update_materials_needed_UI(building_name: String):
	var canvas = Player.get_node("CanvasLayer").get_node("HUD")
	var label = canvas.get_node("Materials_Needed") as RichTextLabel
	label.clear()
	label.show()
	
	var costs = building_costs.get(building_name, {})
	if costs.is_empty():
		label.text = "[center]Este edificio no requiere materiales[/center]"
		return

	for mat in costs.keys():
		var required = costs[mat]
		var owned = materiales.get(mat, 0)
		var color = "[color=green]" if owned >= required else "[color=red]"
		label.append_text("[center]%s%s: %d/%d[/color]  " % [color, mat, owned, required])


func world_to_cell(world_pos: Vector3) -> Vector3i:
	var local = grid_map.to_local(world_pos)
	return Vector3i(floor(local / grid_map.cell_size))

func cell_to_world(cell: Vector3i) -> Vector3:
	var cell_vec3 = Vector3(cell.x, cell.y, cell.z)
	return grid_map.to_global(cell_vec3 * grid_map.cell_size)

func SpawnObj(obj: PackedScene):
	if CurrentSpawnable:
		CurrentSpawnable.queue_free()

	CurrentSpawnable = obj.instantiate()
	grid_map.add_child(CurrentSpawnable)
	CurrentSpawnable.scale = Vector3.ONE

	var collision_shape = CurrentSpawnable.get_node("CollisionShape3D")
	if collision_shape:
		collision_shape.disabled = true

	GameManager.currentState = GameManager.State.Building
	
	# Actualiza el nombre actual y la UI
	var name = obj.resource_path.get_file().get_basename()
	update_materials_needed_UI(name)

# Método generalizado para realizar un raycast desde la cámara
func raycast_from_camera() -> Dictionary:
	# Obtener la cámara
	var camera = get_viewport().get_camera_3d()
	# Obtener la posición del ratón en la pantalla
	var mouse_pos = get_viewport().get_mouse_position()
	# Convertir la posición del ratón en un rayo 3D desde la cámara
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	# Realizar el raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	# Si hay colisión, devolver el resultado
	if result:
		return result
	else:
		return {}
