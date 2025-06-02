extends Node

var phases_part := ["Phase_1", "Phase_2", "Phase_3", "Phase_4", "Phase_5"]

func _ready():
	var main_ship = get_node("/root/Terrain/Main_Ship_Constructor/Main_Ship")
	if main_ship:
		main_ship.connect("play_ending_anim", Callable(self, "_on_play_ending_anim"))
	
	for part in phases_part:
		var node = get_node_or_null(part)
		if node:
			node.visible = false
			_set_colliders_enabled(node, false)
			_set_particles_emitting(node, false)

	GameManager.connect("phase_changed", Callable(self, "_on_phase_changed"))

func _on_phase_changed(new_phase: int):
	print(new_phase)
	if new_phase - 2 < phases_part.size():
		var node_name = phases_part[new_phase - 2]
		var node = get_node_or_null(node_name)
		if node:
			node.visible = true
			_set_colliders_enabled(node, true)
			_set_particles_emitting(node, true)

func _set_colliders_enabled(root: Node, enabled: bool):
	for child in root.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			child.disabled = not enabled
		elif child.has_method("get_children"):
			_set_colliders_enabled(child, enabled)

func _set_particles_emitting(root: Node, emitting: bool):
	for child in root.get_children():
		if child is GPUParticles3D or child is CPUParticles3D:
			child.emitting = emitting
		elif child.has_method("get_children"):
			_set_particles_emitting(child, emitting)
