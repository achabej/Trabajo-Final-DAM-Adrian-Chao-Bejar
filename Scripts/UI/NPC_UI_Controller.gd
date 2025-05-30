extends MeshInstance3D

@export var npc: Node3D
@export var camera: Camera3D
@export var height_offset: float = 2.5

func _ready():
	if not camera:
		camera = get_viewport().get_camera_3d()
	
	_set_viewport_mat(self, $SubViewport)

func _process(delta):
	if npc and camera:
		global_transform.origin = npc.global_transform.origin + Vector3.UP * height_offset
		look_at(camera.global_transform.origin, Vector3.UP)

func _set_viewport_mat(_display_mesh: MeshInstance3D, _sub_viewport: SubViewport, _surface_id: int = 0) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _sub_viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mat.flags_unshaded = true
	
	_display_mesh.set_surface_override_material(_surface_id, mat)
