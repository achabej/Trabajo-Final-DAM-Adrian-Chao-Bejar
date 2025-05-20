extends StaticBody3D

var mat_scene: PackedScene  # El material extraído del depósito
var is_deposit_detected: bool = false  # Para saber si se ha detectado un depósito

func _process(delta: float) -> void:
	update_extractor_status()

# Cuando el cuerpo entra en la zona de colisión
func _on_body_entered(body: Node3D) -> void:
	# Verificar si el cuerpo pertenece al grupo 'Deposit'
	if not get_parent().get_parent().is_in_group("Build") and body.is_in_group("Deposit"):
		print("Depósito detectado: ", body.name)
		# Obtener el prefab del material asignado en el depósito
		mat_scene = body.get("material")  # Obtener el prefab del material
		get_parent().material_scene = mat_scene
		is_deposit_detected = true

# Cuando el cuerpo sale de la zona de colisión
func _on_body_exited(body: Node3D) -> void:
	if not get_parent().get_parent().is_in_group("Build") and body.is_in_group("Deposit"):
		print("Depósito perdido: ", body.name)
		mat_scene = null # Limpiar el prefab del material
		is_deposit_detected = false

# Actualiza el estado de construcción del extractor según si se detectó un depósito o no
func update_extractor_status() -> void:
	# Solo el extractor en modo construcción puede afectar la variable global
	if get_parent().get_parent().is_in_group("Build"):
		return

	if is_deposit_detected:
		BuildManager.AbleToBuild = true
	else:
		BuildManager.AbleToBuild = false
