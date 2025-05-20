extends Label3D


func _process(delta: float) -> void:
	if not get_parent().is_in_group("Build"):
		var z_target := global_transform.origin + Vector3.FORWARD
		look_at(z_target, Vector3.UP)
		rotation_degrees.x = -45
	_update_label()

# Actualiza el Label3D para informar de los materiales en la fabrica
func _update_label():
	var material_storage = $"../Test_Generator_Manager".material_storage
	var contents := ""
	for key in material_storage.keys():
		if material_storage[key] > 0:
			contents += "%s: %d\n" % [key, material_storage[key]]
	text = contents.strip_edges()
