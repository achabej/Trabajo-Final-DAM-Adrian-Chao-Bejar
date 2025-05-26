extends Node3D
class_name Extractor

@export var material_scene: PackedScene
@export var spawn_position: Node3D
@export var spawn_interval: float = 3.0

var spawn_timer: float = 0.0
var is_active: bool = false
var blocking_materials := 0
var current_conveyor: Node3D = null

var detected_material_scene: PackedScene = null  # Prefab detectado del depósito

# Animación
@onready var mesh: Node3D = $"../Mesh"
var anim_time := 0.0
var original_scale := Vector3.ONE	

func _ready() -> void:
	# Detector de conveyors
	var detector = get_node_or_null("ConveyDetector")
	if detector:
		detector.monitoring = true
		detector.connect("body_entered", Callable(self, "_on_convey_detector_body_entered"))
		detector.connect("body_exited", Callable(self, "_on_convey_detector_body_exited"))

	# Detector de depósitos
	var deposit_detector = get_node_or_null("DepositDetector")
	if deposit_detector:
		deposit_detector.connect("body_entered", Callable(self, "_on_deposit_detected"))

func _process(delta: float) -> void:
	if not is_active:
		return

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		if blocking_materials == 0:
			spawn_mat()
	
	# Animación mientras está activo
	if is_active:
		anim_time += delta * 5.0  # Velocidad de animación
		var scale_y = 1.0 + 0.1 * sin(anim_time)
		mesh.scale.y = original_scale.y * scale_y
	else:
		mesh.scale = original_scale

func spawn_mat() -> void:
	if material_scene and spawn_position and is_instance_valid(current_conveyor) and current_conveyor.is_in_group("Build"):
		var mat = material_scene.instantiate()
		get_tree().get_current_scene().add_child(mat)
		
		mat.global_position = spawn_position.global_position
		mat.add_to_group("Ignore_Build_Validation")

		var manager = current_conveyor.get_node_or_null("Convey_Manager")

func activate():
	is_active = true

func _on_convey_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group("Build") and body.is_in_group("Convey") and is_instance_valid(body):
		current_conveyor = body
	elif body.is_in_group("Material"):
		blocking_materials += 1
		print("🚫 Zona de spawn bloqueada")

func _on_convey_detector_body_exited(body: Node3D) -> void:
	if body == current_conveyor:
		current_conveyor = null
	elif body.is_in_group("Material"):
		blocking_materials = max(0, blocking_materials - 1)
		print("✅ Zona de spawn libre")
