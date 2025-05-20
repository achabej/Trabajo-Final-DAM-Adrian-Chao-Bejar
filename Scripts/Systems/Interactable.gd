extends Node
#Metodo que se implementa para cualquier interaccion "F"
#Controla el input y el area para interactuar

#El nodo que lo implemente debe de tener el metodo "_on_interact()"

var inRange = false
@export var interact_obj: Node3D

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Interact") and inRange:
		interact_obj._on_interact()

func _on_area_3d_body_entered(body: Node3D) -> void:
	inRange = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	inRange = false
