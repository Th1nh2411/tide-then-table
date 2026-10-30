class_name SeaFog3D
extends Node3D
## The fog over the north-east sea once Story.is_fog_open(): flat translucent
## blobs drifting slowly over FOG_RECT (the 3D take on the 2D FogArea).

const BLOB_COUNT: int = 14
const DRIFT_SPEED: float = 0.3
const DRIFT_UNITS: float = 1.7

var _blobs: Array[MeshInstance3D] = []
var _homes: Array[Vector3] = []
var _time: float = 0.0


func _ready() -> void:
	var rect := SeaLayout3D.rect_world(SeaLayout3D.FOG_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # same fog shape every day
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.95, 1.0, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(BLOB_COUNT):
		var blob := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		var r := rng.randf_range(50.0, 110.0) / SeaLayout3D.PX_PER_UNIT
		mesh.radius = r
		mesh.height = r * 0.5
		mesh.radial_segments = 12
		mesh.rings = 4
		blob.mesh = mesh
		blob.material_override = mat
		blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(blob)
		var home := Vector3(rng.randf_range(rect.position.x, rect.end.x), 0.6 + rng.randf() * 0.8,
			rng.randf_range(rect.position.y, rect.end.y))
		blob.position = home
		_blobs.append(blob)
		_homes.append(home)


func _process(delta: float) -> void:
	_time += delta
	for i in range(_blobs.size()):
		var t := _time * DRIFT_SPEED
		_blobs[i].position = _homes[i] + Vector3(sin(t + i), 0.0, cos(t * 0.7 + i * 2.0)) * DRIFT_UNITS
