extends Node3D

# Obtiene el objeto actual
func get_current_weapon():
	return $Extractor_Tool

# Función para ocultar el arma
func hide_weapon():
	$Extractor_Tool.visible = false

# Función para mostrar el arma
func show_weapon():
	$Extractor_Tool.visible = true
