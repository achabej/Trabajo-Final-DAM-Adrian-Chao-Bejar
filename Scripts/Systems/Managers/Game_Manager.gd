extends Node

enum State {
	Play,
	Building,
	Destroying
}

var currentState = State.Play

@export var tick_interval : float = 1.0  # Tiempo en segundos entre cada "tick"
var tick_timer : float = 0.0  # Temporizador para llevar el control del "tick"

func _ready() -> void:
	# Aquí puedes inicializar tu temporizador si es necesario
	tick_timer = tick_interval  # Inicia el temporizador para el primer "tick"
	
func _process(delta: float) -> void:
	# Actualiza el temporizador
	tick_timer -= delta
	
	# Si el temporizador llega a cero, genera un "tick"
	if tick_timer <= 0:
		# Reinicia el temporizador
		tick_timer = tick_interval
