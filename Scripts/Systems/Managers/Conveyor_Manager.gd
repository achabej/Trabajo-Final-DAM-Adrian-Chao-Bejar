# ConveyorManager.gd (singleton, debe añadirse a AutoLoad)
extends Node

var conveyors: Array = []

#Temporizador
var tick_timer: Timer
var tick_interval := 0.2

func _ready():
	tick_timer = Timer.new()
	tick_timer.wait_time = tick_interval
	tick_timer.one_shot = false
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick_timeout)
	add_child(tick_timer)

func _on_tick_timeout():
	tick_conveyor()

func register_conveyor(conveyor: Node):
	if conveyor not in conveyors:
		conveyors.append(conveyor)
		print("Conveyor registrado")

func unregister_conveyor(conveyor: Node):
	conveyors.erase(conveyor)

func get_all_conveyors() -> Array:
	return conveyors.duplicate()

func tick_conveyor():
	for conveyor in conveyors:
		if is_instance_valid(conveyor):
			conveyor.try_move()
