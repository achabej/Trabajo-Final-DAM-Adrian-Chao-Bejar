extends MeshInstance3D

@export var npc: Node3D
@export var camera: Camera3D
@export var height_offset: float = 2.5

func _ready():
	camera = get_viewport().get_camera_3d()

func _process(delta):
	if npc and camera:
		global_transform.origin = npc.global_transform.origin + Vector3.UP * height_offset
		look_at(camera.global_transform.origin, Vector3.UP)
