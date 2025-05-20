extends RichTextLabel

func update_materials_needed_UI(building_name: String) -> void:
	var canvas = $CanvasLayer
	var label := canvas.get_node("Materials_Needed") as RichTextLabel
	label.clear()

	# Obtener los costes del edificio desde BuildManager
	var costs = BuildManager.building_costs.get(building_name, {})
	if costs.is_empty():
		label.text = "[center]Este edificio no requiere materiales[/center]"
		return

	# Construir el texto con formato y colores
	for mat in costs.keys():
		var required = costs[mat]
		var owned = BuildManager.materiales.get(mat, 0)
		var color = "[color=green]" if owned >= required else "[color=red]"
		label.append_text("%s%s: %d/%d[/color]  " % [color, mat, owned, required])
