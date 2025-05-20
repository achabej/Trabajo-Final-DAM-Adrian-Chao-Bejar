extends Node3D

@onready var health_bar = $"../CanvasLayer/Health_bar"
@export var max_health = 100
@export var tag_group: String = "enemy_bullet"
var current_health

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if health_bar != null:
		health_bar.value = current_health

func damage(damage: float):
	current_health -= damage
	
	if current_health <= 0:
		dead()

#Destruye el npc
func dead():
	print("you died :(")
	get_parent().queue_free()

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group(tag_group):
		damage(body.damage)
		body.queue_free()
