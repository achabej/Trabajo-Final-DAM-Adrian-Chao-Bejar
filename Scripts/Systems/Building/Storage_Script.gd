extends Node3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if get_parent().is_in_group("Build") and body.has_method("get_material_type"):
		var material_type = body.get_material_type()

		if BuildManager.materiales.has(material_type):
			BuildManager.increase_mat(material_type, 1)
			body.queue_free()  # Elimina el objeto de la cinta
