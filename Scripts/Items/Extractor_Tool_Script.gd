extends Node

@onready var laser_raycast: RayCast3D = $Laser/Raycast
@onready var laser_mesh: Node3D = $Laser/Laser_Mesh
@onready var impact_particles: GPUParticles3D = $Laser/ParticleEndLaser
@onready var extraction_timer: Timer = $ExtractorTimer
@onready var attack_timer: Timer = $AttackTimer  

@onready var sound_loop: AudioStreamPlayer3D = $LaserLoop

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

	if !sound_loop.playing:  
		sound_loop.play()

	laser_raycast.force_raycast_update()

	var hit_distance = default_length

	if laser_raycast.is_colliding():
		var collider = laser_raycast.get_collider()
		print(collider)

		if collider.is_in_group("Deposit") or collider.is_in_group("Tree"):
			current_deposit = collider
			if extraction_timer.is_stopped():
				extraction_timer.start()
		elif collider.is_in_group("Enemy"):
			current_deposit = null
			if attack_timer.is_stopped():
				attack_timer.start()  # Solo arrancamos el timer aquí
		else:
			current_deposit = null
			extraction_timer.stop()
			attack_timer.stop()

		var origin = laser_raycast.global_transform.origin
		var collision_point = laser_raycast.get_collision_point()
		hit_distance = origin.distance_to(collision_point) / 8.5

		impact_particles.global_position = collision_point
		if not impact_particles.emitting:
			impact_particles.restart()
			impact_particles.emitting = true
	else:
		impact_particles.emitting = false
		current_deposit = null
		extraction_timer.stop()
		attack_timer.stop()

	laser_mesh.scale.z = hit_distance


func stop_shooting():
	sound_loop.stop()

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

func _on_attack_timer_timeout() -> void:
	if is_shooting and laser_raycast.is_colliding():
		var collider = laser_raycast.get_collider()
		if collider.is_in_group("Enemy"):
			print("Dañando enemigo por timer")
			collider.get_node("HealthController").damage(5)
			attack_timer.start()  # Reinicia timer para siguiente daño
