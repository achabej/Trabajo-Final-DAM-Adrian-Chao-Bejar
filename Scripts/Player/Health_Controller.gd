extends Node3D

@export var health_bar : ProgressBar 
@export var max_health = 100
@export var tag_group: String = "enemy_bullet"
@export var mesh: Node3D = null
#Vida actual
var current_health

#Escala cuando recibe daño
var original_scale
var enlarged_scale 
	 
func _ready() -> void:
	current_health = max_health
	original_scale = mesh.scale
	enlarged_scale = original_scale * 0.8
	
func _process(delta: float) -> void:
	if health_bar != null:
		health_bar.value = current_health

func damage(damage: float):
	$"..".is_damage_visual()
	current_health -= damage
	print("daño recibido")
	if current_health <= 0:
		dead()

#Destruye el npc
func dead():
	get_parent().die()
