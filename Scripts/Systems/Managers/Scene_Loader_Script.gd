extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame  

	GameManager.init()
	ConveyorManager.init()
	BuildManager.init()
