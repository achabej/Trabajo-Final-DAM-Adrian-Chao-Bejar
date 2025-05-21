extends Node3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("get_material_type"):
		var material_type = body.get_material_type()
		print("Material detectado:", material_type)
		
		# Obtener la fase actual
		var phase_key = "Phase%d" % GameManager.current_phase
		
		# Comprobar si el material está dentro de los recursos requeridos en la fase actual
		if GameManager.phases.has(phase_key):
			if GameManager.phases[phase_key]["Resources"].has(material_type):
				GameManager.add_mat(material_type, 1)
				body.queue_free()
			else:
				print("Material", material_type, "no requerido en la fase actual")
		else:
			print("Fase actual no válida:", phase_key)
