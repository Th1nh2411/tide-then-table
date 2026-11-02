class_name PsxLook3D
extends CanvasLayer
## Trial PS1 look for the 3D scenes (SceneRouter toggles it with F8 in debug
## builds): the 3D world is drawn natively at `pixel_res` by a SubViewport
## that follows the game camera and is shown nearest-upscaled under the UI
## (whole pixels, no dropped edges); opaque StandardMaterial3Ds become
## `psx_vertex` (nearest textures, optional vertex snap). MSAA on the low-res
## image keeps edges from crawling as the camera moves. Removing the node restores
## every original material and the game's own 3D view.

const VERTEX_SHADER := preload("res://scenes/world3d/psx_vertex.gdshader")
const SCREEN_SHADER := preload("res://scenes/world3d/psx_screen.gdshader")
const META := "psx_original"
## The hidden full-size 3D render is kept, but drawn at this scale to stay cheap.
const HIDDEN_3D_SCALE := 0.25

@export var pixel_res := Vector2i(640, 360)
## PS1 vertex wobble; off by default (it makes edges jitter as the camera moves).
@export var vertex_snap := false
@export var snap_res := Vector2(320, 180)
@export var color_levels := 32.0
@export var dither := 0.0

var _converted: Dictionary = {}  # source material -> ShaderMaterial
var _meshes: Array[MeshInstance3D] = []
var _view: SubViewport
var _camera: Camera3D
var _root_scale := 1.0


func _ready() -> void:
	layer = -1  # over the game's 3D image, before every UI layer
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000  # after the game moved its camera this frame
	_view = SubViewport.new()
	_view.size = pixel_res
	_view.msaa_3d = Viewport.MSAA_4X
	_view.positional_shadow_atlas_size = 2048
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	_camera = Camera3D.new()
	_view.add_child(_camera)
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.texture = _view.get_texture()
	var screen := ShaderMaterial.new()
	screen.shader = SCREEN_SHADER
	screen.set_shader_parameter("levels", color_levels)
	screen.set_shader_parameter("dither", dither)
	rect.material = screen
	add_child(rect)
	_root_scale = get_tree().root.scaling_3d_scale
	get_tree().root.scaling_3d_scale = HIDDEN_3D_SCALE
	for node in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		_apply(node as MeshInstance3D)
	get_tree().node_added.connect(_on_node_added)


## Copies the game camera, so picking and gameplay keep using the real one.
func _process(_delta: float) -> void:
	var source := get_tree().root.get_camera_3d()
	visible = source != null
	if source == null:
		return
	_camera.global_transform = source.global_transform
	_camera.projection = source.projection
	_camera.fov = source.fov
	_camera.size = source.size
	_camera.near = source.near
	_camera.far = source.far
	_camera.keep_aspect = source.keep_aspect
	_camera.h_offset = source.h_offset
	_camera.v_offset = source.v_offset
	_camera.cull_mask = source.cull_mask
	_camera.environment = source.environment
	_camera.attributes = source.attributes


func _exit_tree() -> void:
	get_tree().root.scaling_3d_scale = _root_scale
	get_tree().node_added.disconnect(_on_node_added)
	for mesh in _meshes:
		if is_instance_valid(mesh) and mesh.has_meta(META):
			var saved: Array = mesh.get_meta(META)
			mesh.material_override = saved[0]
			for i in range(1, saved.size()):
				mesh.set_surface_override_material(i - 1, saved[i])
			mesh.remove_meta(META)
	_meshes.clear()


func _on_node_added(node: Node) -> void:
	if node is MeshInstance3D:
		# Builders set materials right after add_child; convert once they have.
		_apply.call_deferred(node)


func _apply(mesh: MeshInstance3D) -> void:
	if not is_instance_valid(mesh) or mesh.mesh == null or mesh.has_meta(META):
		return
	var saved: Array = [mesh.material_override]
	for i in mesh.mesh.get_surface_count():
		saved.append(mesh.get_surface_override_material(i))
	mesh.set_meta(META, saved)
	_meshes.append(mesh)
	if mesh.material_override:
		mesh.material_override = _convert(mesh.material_override)
		return
	for i in mesh.mesh.get_surface_count():
		mesh.set_surface_override_material(i, _convert(mesh.get_active_material(i)))


## Opaque, lit StandardMaterial3Ds only; anything else is kept as it is.
func _convert(source: Material) -> Material:
	var base := source as BaseMaterial3D
	if base == null or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
			or base.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL:
		return source
	if _converted.has(base):
		return _converted[base]
	var m := ShaderMaterial.new()
	m.shader = VERTEX_SHADER
	m.set_shader_parameter("albedo_color", base.albedo_color)
	m.set_shader_parameter("use_tex", base.albedo_texture != null)
	if base.albedo_texture:
		m.set_shader_parameter("albedo_tex", base.albedo_texture)
	m.set_shader_parameter("use_vertex_color", base.vertex_color_use_as_albedo)
	m.set_shader_parameter("uv_scale_offset", Vector4(base.uv1_scale.x, base.uv1_scale.y, base.uv1_offset.x, base.uv1_offset.y))
	m.set_shader_parameter("roughness", base.roughness)
	if base.emission_enabled:
		var e := base.emission * base.emission_energy_multiplier
		m.set_shader_parameter("emission", Vector3(e.r, e.g, e.b))
	m.set_shader_parameter("snap", vertex_snap)
	m.set_shader_parameter("snap_res", snap_res)
	_converted[base] = m
	return m
