extends MeshInstance3D
#Boton simple

var isGreen = true

var green = preload('res://Materials/MT_test_green.tres')
var red = preload('res://Materials/MT_test_red.tres')

func _ready() -> void:
	isGreen = true

func _on_interact():
	print("is pressing {isGreen}"+ str(isGreen))
	if isGreen:
		set_surface_override_material(0,red) 
		isGreen = false
	else:
		set_surface_override_material(0,green)
		isGreen = true
