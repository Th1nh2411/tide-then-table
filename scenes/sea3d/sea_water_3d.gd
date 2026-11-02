class_name SeaWater3D
extends MeshInstance3D
## The 3D sea's water surface (sea_water.gdshader): one subdivided plane over
## the whole map at WATER_Y. Zone colours come from SeaLayout3D; the boat's
## blob shadow follows `boat` each frame.

const SHADER := preload("res://scenes/sea3d/sea_water.gdshader")
const WATER_Y := 0.1
## Vertices per metre of the swell mesh (about 1 per 0.8 m).
const GRID := 1.25

var boat: Node3D


static func build(sea: SeaScene3D) -> SeaWater3D:
	var water := SeaWater3D.new()
	water.name = "SeaWater"
	var size := SeaLayout3D.size_world()
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = int(size.x * GRID)
	plane.subdivide_depth = int(size.y * GRID)
	water.mesh = plane
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("reef_z", SeaLayout3D.rect_world(SeaLayout3D.REEF_RECT).position.y)
	m.set_shader_parameter("near_z", SeaLayout3D.rect_world(SeaLayout3D.NEAR_RECT).position.y)
	if Story.is_fog_open():
		var fog := SeaLayout3D.rect_world(SeaLayout3D.FOG_RECT)
		m.set_shader_parameter("fog_rect", Vector4(fog.position.x, fog.position.y, fog.size.x, fog.size.y))
	for light in sea.find_children("*", "DirectionalLight3D", false, false):
		# Built by build_environment before the water; its -Z points away from the moon.
		m.set_shader_parameter("moon_dir", (light as DirectionalLight3D).global_basis.z.normalized())
		break
	water.material_override = m
	water.boat = sea.boat
	# Same footprint as the boat's ContactShadow3D (round thúng, long ghe).
	var long_boat := sea.boat_data.id != "thuyen_thung"
	m.set_shader_parameter("boat_shadow", Vector2(1.3, 2.6) if long_boat else Vector2(1.45, 1.45))
	sea.add_child(water)
	water.position = Vector3(0, WATER_Y, 0)
	return water


func _process(_delta: float) -> void:
	if boat:
		var m := material_override as ShaderMaterial
		m.set_shader_parameter("boat_pos", boat.global_position)
		m.set_shader_parameter("boat_yaw", boat.global_rotation.y)
