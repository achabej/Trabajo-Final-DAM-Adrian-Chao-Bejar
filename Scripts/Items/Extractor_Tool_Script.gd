extends Node

@onready var laser_raycast: RayCast3D = $Laser/Raycast
@onready var laser_mesh: Node3D = $Laser/Laser_Mesh
@onready var impact_particles: GPUParticles3D = $Laser/ParticleEndLaser
@onready var extraction_timer: Timer = $ExtractorTimer
@onready var attack_timer: Timer = $AttackTimer  

@export var damage: float = 1
@export var default_length: float = 1

var is_shooting: bool = false
var current_deposit: Node = null

func _ready() -> void:
	stop_shooting()

func shoot():
	is_shooting = true
	laser_raycast.enabled = true
	laser_mesh.visible = true

	# Actualizar el raycast
	laser_raycast.force_raycast_update()

	var hit_distance = default_length
	var did_hit = false

	if laser_raycast.is_colliding():
		var collider = laser_raycast.get_collider()
		print(collider)
		
		if collider.is_in_group("Deposit") or collider.is_in_group("Tree"):
			current_deposit = collider
			if extraction_timer.is_stopped():
				extraction_timer.start()
		elif collider.is_in_group("Enemy"):
			if attack_timer.is_stopped():
				collider.get_node("HealthController").damage(5)
				attack_timer.start()
		else:
			current_deposit = null
			extraction_timer.stop()

		did_hit = true
		var origin = laser_raycast.global_transform.origin
		var collision_point = laser_raycast.get_collision_point()
		hit_distance = origin.distance_to(collision_point) / 8.5

		# Posicionar partículas
		impact_particles.global_position = collision_point
		if not impact_particles.emitting:
			impact_particles.restart()
			impact_particles.emitting = true
	else:
		impact_particles.emitting = false
		current_deposit = null
		extraction_timer.stop()

	# Ajustar tamaño del láser
	laser_mesh.scale.z = hit_distance

func stop_shooting():
	is_shooting = false
	laser_raycast.enabled = false
	laser_mesh.visible = false
	impact_particles.emitting = false
	extraction_timer.stop()
	attack_timer.stop() 
	current_deposit = null

func _on_extractor_timer_timeout() -> void:
	if current_deposit and is_shooting:
		var mat_name = current_deposit.resource_type
		BuildManager.increase_mat(mat_name, 1)
