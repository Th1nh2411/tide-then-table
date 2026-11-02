class_name DarkNightLook
extends Resource
## How the sea looks on "đêm âm" (DarkNight3D): thick sickly fog, dark water,
## a red moon. apply() changes the already built sea (environment, moon
## light, water shader, islands) and adds the red moon disc.

@export_group("Fog and light")
@export var fog_color := Color("1c2219")
@export var fog_density := 0.05
@export_range(0.0, 1.0) var fog_sky_affect := 0.6
@export var ambient_color := Color("5b6b52")
@export var ambient_scale := 0.55
@export var background_color := Color("0a0c08")
@export var moon_light_color := Color("b0463a")
@export var moon_light_energy := 0.32
@export var lamp_color := Color("e8d28a")
@export var islands_tint := Color(0.32, 0.16, 0.14)

@export_group("Water")
@export var water_open := Color(0.018, 0.026, 0.022)
@export var water_reef := Color(0.025, 0.04, 0.03)
@export var water_near := Color(0.045, 0.06, 0.04)
@export var water_crest := Color(0.16, 0.19, 0.13)
@export var water_sky := Color(0.3, 0.07, 0.05)
@export var water_moon := Color(0.85, 0.2, 0.12)

@export_group("Red moon")
@export var moon_disc_color := Color(0.78, 0.16, 0.1)
@export var moon_halo_color := Color(0.6, 0.1, 0.06, 0.22)
@export var moon_distance := 220.0
@export var moon_radius := 6.5
## Low over the horizon (in view without looking up), same bearing as the moon light.
@export var moon_elevation_deg := 16.0


const DARK_SKY: Texture2D = preload("res://assets/textures/sea3d/sky_dark_night.png")
## Where the moon sits across sky_dark_night.png (u, 0..1).
const DARK_MOON_U := 0.48


func apply(sea: SeaScene3D) -> void:
	var world_env := sea.find_children("*", "WorldEnvironment", false, false)
	if not world_env.is_empty():
		var env := (world_env[0] as WorldEnvironment).environment
		var lights := sea.find_children("*", "DirectionalLight3D", false, false)
		if not lights.is_empty():
			# The painted blood-moon sky (assets/textures/sea3d/sky_dark_night.png), its moon on the light's bearing.
			SeaBackdrop3D.apply_sky(env, lights[0] as DirectionalLight3D, DARK_SKY, DARK_MOON_U)
		env.fog_light_color = fog_color
		env.fog_density = fog_density
		env.fog_sky_affect = fog_sky_affect
		env.background_color = background_color
		env.ambient_light_color = ambient_color
		env.ambient_light_energy *= ambient_scale
	for light in sea.find_children("*", "DirectionalLight3D", false, false):
		(light as DirectionalLight3D).light_color = moon_light_color
		(light as DirectionalLight3D).light_energy = moon_light_energy
	if is_instance_valid(sea.boat_lamp):
		sea.boat_lamp.light_color = lamp_color
	var water := sea.get_node_or_null("SeaWater") as SeaWater3D
	if water:
		water.set_palette({"open_color": water_open, "reef_color": water_reef, "near_color": water_near,
			"crest_color": water_crest, "sky_color": water_sky, "moon_color": water_moon})
	for node in sea.find_children("DistantIslands*", "MeshInstance3D", false, false):
		var material := (node as MeshInstance3D).material_override as StandardMaterial3D
		if material:
			material.albedo_color = islands_tint


## Towards the red moon: the moon light's bearing, moon_elevation_deg up.
func moon_direction(sea: SeaScene3D) -> Vector3:
	var bearing := Vector3(0.6, 0.0, -0.8)
	for light in sea.find_children("*", "DirectionalLight3D", false, false):
		bearing = (light as DirectionalLight3D).global_basis.z
		break
	bearing.y = 0.0
	var up := deg_to_rad(moon_elevation_deg)
	return bearing.normalized() * cos(up) + Vector3.UP * sin(up)


## Red disc + halo; the caller keeps it at moon_distance from the camera.
func build_moon(parent: Node3D) -> Node3D:
	var moon := Node3D.new()
	moon.name = "RedMoon"
	parent.add_child(moon)
	_disc(moon, moon_radius * 2.0, moon_disc_color)
	_disc(moon, moon_radius * 4.2, moon_halo_color)
	return moon


func _disc(parent: Node3D, size: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = size * 0.5
	mesh.height = size
	mesh.radial_segments = 24
	mesh.rings = 12
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_fog = true
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_FRONT
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
