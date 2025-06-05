extends Node

var phases_part := ["Phase_1", "Phase_2", "Phase_3", "Phase_4", "Phase_5"]
@onready var building_sound = $HammerSound
@onready var complete_sound = $CompleteSound
var build_sound_count

func _ready():
	for part in phases_part:
		var node = get_node_or_null(part)
		if node:
			node.visible = false
			_set_colliders_enabled(node, false)
			_set_particles_emitting(node, false)

	GameManager.connect("phase_changed", Callable(self, "_on_phase_changed"))

func _on_phase_changed(new_phase: int):
	print(new_phase)

	build_sound_count = 0
	building_sound.play()

	if new_phase - 2 < phases_part.size():
		var node_name = phases_part[new_phase - 2]
		var node = get_node_or_null(node_name)
		if node:
			node.visible = true
			_set_colliders_enabled(node, true)
			_set_particles_emitting(node, true)

func _on_building_sound_finished():
	build_sound_count += 1
	if build_sound_count < 3:
		building_sound.play()  # Reproducir otra vez
	else:
		complete_sound.play()  # Después de 3 repeticiones

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
