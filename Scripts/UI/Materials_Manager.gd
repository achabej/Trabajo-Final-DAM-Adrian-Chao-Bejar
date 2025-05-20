extends Node

func _ready() -> void:
	update_mat_UI()

func update_mat_UI():
	for mat in get_children():
		var mat_name = mat.name
		
		if BuildManager.materiales.has(mat_name):
			var amount = BuildManager.materiales[mat_name]
			if amount >= 0:
				mat.show()  # o mat.visible = true
				var label = mat.get_node("Amount") as RichTextLabel
				if label:
					label.text = str(amount)
			else:
				mat.hide()  
		else:
			mat.hide() 
