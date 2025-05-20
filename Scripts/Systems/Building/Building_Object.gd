extends StaticBody3D

var objects: Array[Node3D] = []  # Lista de objetos válidos con los que estamos en colisión.
var ActiveBuildableObject: bool = true
var isBuild = false

@export var notBuildList: Array[String] = []
@export var SpawnActor: bool = true
@export var Actor: PackedScene


func _ready() -> void:
	$Area3D.connect("body_entered", Callable(self, "_on_body_entered"))
	$Area3D.connect("body_exited", Callable(self, "_on_body_exited"))

func _process(delta: float) -> void:
	if ActiveBuildableObject and not isBuild:
		var can_build := true
		for obj in objects:
			if isInProhibitedGroup(obj):
				can_build = false
				break
		BuildManager.AbleToBuild = can_build

# Cambia el material de todos los MeshInstance3D que no estén protegidos
func apply_material_to_meshes(mat: Material) -> void:
	_apply_material_recursive($Mesh, mat)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and not child.is_in_group("Ignore_Material_Change"):
			child.set_surface_override_material(0, mat)
		_apply_material_recursive(child, mat)  # Recursivo para todos los niveles

func isInProhibitedGroup(child: Node3D) -> bool:
	for group in notBuildList:
		if child.is_in_group(group):
			return true
	return false

# Spawnea una copia del objeto
func runSpawn():
	if SpawnActor:
		var ActorInstance = Actor.instantiate()
		get_tree().root.add_child(ActorInstance)
		ActorInstance.global_position = $SpawnPoint.global_position

# Gestiona la entrada de objetos en el área
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ignore_Build_Validation"):
		return 
	
	if not objects.has(body) and (body.is_in_group("Build") or body.is_in_group("Player") or isInProhibitedGroup(body)):
		objects.append(body)

# Gestiona la salida de objetos en el área
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Ignore_Build_Validation"):
		return 

	if objects.has(body) and (body.is_in_group("Build") or body.is_in_group("Player") or isInProhibitedGroup(body)):
		objects.erase(body)
