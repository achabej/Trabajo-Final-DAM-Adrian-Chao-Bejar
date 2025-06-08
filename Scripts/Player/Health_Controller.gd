extends Node3D

@export var health_bar : ProgressBar 
@export var max_health = 100 # Vida máxima
@export var tag_group: String = "enemy_bullet" #Grupo del cual el health controler recibirá daño
@export var mesh: Node3D = null
@export var can_heal: bool = false # Permite si la entidad se cura con el tiempo
var ready_to_heal: bool = false

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

# Funcion para reducir la vida
func damage(damage: float):
	$Heal_Delay.start()
	ready_to_heal = false
	
	$"..".is_damage_visual()
	current_health -= damage
	print("daño recibido")
	if current_health <= 0:
		dead()

# Funcion para aumentar la vida
func cure(health: float):
	current_health += health
	if current_health > max_health:
		current_health = max_health

#Destruye el npc
func dead():
	get_parent().die()
	
# Delay antes de empezar a curar
func _on_heal_delay_timeout() -> void:
	ready_to_heal = true
	if can_heal:
		$Heal_Timer.start()

# Delay entre curación
func _on_heal_timer_timeout() -> void:
	if ready_to_heal:
		cure(1)
