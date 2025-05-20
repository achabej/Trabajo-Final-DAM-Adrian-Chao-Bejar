extends StaticBody3D
class_name Enter_Filter_Script

@export var allowed_material: String = ""
@onready var machine_node = $"../.."

signal material_entered(body: Node3D)

var materials_in_area: Array = []

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Material") and not materials_in_area.has(body):
		materials_in_area.append(body)

func _on_body_exited(body: Node3D) -> void:
	materials_in_area.erase(body)

func _physics_process(_delta: float) -> void:
	for body in materials_in_area:
		if not is_instance_valid(body):
			continue
		if not body.has_method("get_material_type"):
			continue

		var mat_type = body.get_material_type()
		if mat_type != allowed_material:
			continue

		if machine_node and machine_node.get_parent().is_in_group("Build") and machine_node.has_method("can_accept_material") and machine_node.has_method("receive_material"):
			if machine_node.can_accept_material(mat_type):
				machine_node.receive_material(body, mat_type)
				materials_in_area.erase(body)  # El material fue aceptado
				print("✅ Material aceptado (en revisión):", mat_type)
				break  # Procesa uno por frame
