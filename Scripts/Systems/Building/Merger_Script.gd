extends ConveyScript
class_name MergerScript

@onready var entrada_rays: Array = $Entradas.get_children()
@onready var salida_raycast: RayCast3D = $Convey_Manager/RayCast3D
@onready var timer: Timer = $MergerTimer

var entrada_index := 0

func _ready():
	timer.timeout.connect(Callable(self, "_on_merger_tick"))

# Ejecutado en cada tick del timer
func _on_merger_tick():
	# No procesar si ya hay material en el centro
	if current_material != null:
		try_send_to_output()
		return

	# Probar cada entrada una por una
	for i in range(entrada_rays.size()):
		var ray = entrada_rays[entrada_index]
		entrada_index = (entrada_index + 1) % entrada_rays.size()

		if ray.is_colliding():
			var material = ray.get_collider()
			if material and material.is_in_group("Material"):
				var source_convey = find_parent_with_group(material, "Convey")
				if source_convey:
					var source_manager = source_convey.get_node_or_null("Convey_Manager")
					if source_manager is ConveyScript and source_manager.current_material == material:
						current_material = material
						move_material_to_center(material)
						print("🔄 Material absorbido por MERGER desde:", source_convey.name)
						break

# Mueve el material al centro del merger
func move_material_to_center(material: RigidBody3D):
	var to_pos = get_center_position()
	to_pos.y = material.global_position.y

	var tween = create_tween()
	tween.tween_property(material, "global_position", to_pos, convey_velocity)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_input_move_finished"))

func _on_input_move_finished():
	print("✅ Material llegó al centro del merger.")

# Intenta enviar el material al conveyor de salida
func try_send_to_output():
	if current_material == null or not salida_raycast.is_colliding():
		return

	var salida_collider = salida_raycast.get_collider()
	if salida_collider:
		var salida_convey = find_parent_with_group(salida_collider, "Convey")
		if salida_convey:
			var salida_manager = salida_convey.get_node_or_null("Convey_Manager")
			if salida_manager is ConveyScript and salida_manager.current_material == null:
				var to_pos = salida_manager.get_center_position()
				to_pos.y = current_material.global_position.y

				var tween = create_tween()
				tween.tween_property(current_material, "global_position", to_pos, convey_velocity)
				tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_callback(Callable(self, "_on_output_move_finished"))

				print("➡️ Material enviado al conveyor de salida:", salida_convey.name)

func _on_output_move_finished():
	current_material = null
	print("✅ MERGER listo para nuevo material.")
