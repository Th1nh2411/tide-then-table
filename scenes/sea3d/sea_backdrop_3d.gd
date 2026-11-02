class_name SeaBackdrop3D
extends RefCounted
## The 3D sea's backdrop: the night sky panorama (moon turned to match the
## moon light, so water glints line up) and island silhouettes on the horizon.

const SKY := preload("res://assets/textures/sea3d/night_sky_panorama_v1.png")
const ISLANDS := preload("res://assets/textures/sea3d/distant_islands_night_v1.png")
## Where the moon sits in the panorama (u, 0..1 across the image).
const MOON_U := 0.675
## Island strips: centre, yaw, width. Height follows the 8:1 texture.
const STRIPS := [
	[Vector3(0, 0, -95), 0.0, 230.0],
	[Vector3(-125, 0, -20), PI * 0.5, 150.0],
	[Vector3(125, 0, -20), -PI * 0.5, 150.0],
]
## Island baseline in the texture, from the top (0..1).
const BASELINE_V := 0.867


## Sky for `env`; `moon` is the scene's moon light (its +Z points at the moon).
## `panorama` / `moon_u`: another painted sky and where its moon sits (đêm âm).
static func apply_sky(env: Environment, moon: DirectionalLight3D, panorama: Texture2D = SKY, moon_u: float = MOON_U) -> void:
	var material := PanoramaSkyMaterial.new()
	material.panorama = panorama
	material.energy_multiplier = 1.0
	var sky := Sky.new()
	sky.sky_material = material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	# Panorama u = atan(x, -z) / TAU; turn the sky so the painted moon is where the light comes from.
	var to_moon := moon.global_basis.z
	var light_u := fposmod(atan2(to_moon.x, -to_moon.z) / TAU, 1.0)
	env.sky_rotation = Vector3(0, (moon_u - light_u) * TAU, 0)
	env.fog_sky_affect = 0.25


static func build_islands(parent: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = ISLANDS
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = true
	material.albedo_color = Color(0.85, 0.88, 0.95)
	for strip: Array in STRIPS:
		var width: float = strip[2]
		var height := width / 8.0
		var quad := QuadMesh.new()
		quad.size = Vector2(width, height)
		var node := MeshInstance3D.new()
		node.name = "DistantIslands"
		node.mesh = quad
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
		var centre: Vector3 = strip[0]
		node.position = centre + Vector3(0, SeaWater3D.WATER_Y + height * (BASELINE_V - 0.5), 0)
		node.rotation.y = strip[1]
