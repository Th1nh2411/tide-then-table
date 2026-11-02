class_name WaterfrontBuilder3D
extends RefCounted
## Builds Xóm Đèn's waterfront for WaterfrontScene3D: the village ground, Rin's
## house (ông Tư's) with its door, the pier running out to sea with ông Tư's
## thúng tied at the end, lamp posts, dark neighbours, and the lane to the
## restaurant, two lighthouses, and the dock omens (DockOmens3D). The sea lies
## towards -Z, like the night sea's north.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const DOOR := Vector3(-1.0, 0, 9.4)
const THUNG := Vector3(6.0, 0, -10.6)
const LANE := Vector3(-14.0, 0, 8.0)
const MORNING_START := Vector3(-1.0, 0, 8.4)
const EVENING_START := Vector3(-12.5, 0, 7.6)
const SHORE_Z := 2.0
const PIER_POST := Vector3(7.0, 0.12, -9.4)
const NEAR_LIGHTHOUSE := Vector3(-11.0, -0.2, -4.0)
const FAR_LIGHTHOUSE := Vector3(30.0, -0.2, -60.0)
const WATER_Y := -0.35


static func build(host: Node3D, evening: bool) -> void:
	_light(host, evening)
	# Village ground, a sandy edge, the sea beyond.
	B.box(host, Vector3(0, -0.1, 8.0), Vector3(34, 0.2, 12), "4a4136", true).material_override = HorrorMaterials.tiled("ground_village", 2.0)
	B.box(host, Vector3(0, -0.12, SHORE_Z + 0.6), Vector3(34, 0.2, 1.4), "8a7a5e", true)
	_water(host)
	# Rin's house: a low plastered front with a wooden door and one window.
	var wall := HorrorMaterials.tiled("wall_plaster_old", 2.2)
	var roof := HorrorMaterials.tiled("roof_tin_rusty", 1.4)
	B.box(host, Vector3(-1.0, 1.6, 12.0), Vector3(7.0, 3.2, 5.0), "8f877a", true).material_override = wall
	B.box(host, Vector3(-1.0, 3.35, 11.6), Vector3(7.6, 0.25, 5.8), "5b3a2e").material_override = roof
	B.box(host, DOOR + Vector3(0, 1.0, 0.0), Vector3(0.95, 2.0, 0.08), "4a3a2e")
	HorrorMaterials.picture(host, "door_wood_old", DOOR + Vector3(0, 1.0, -0.045), Vector2(0.95, 2.0), PI)
	var window := B.box(host, Vector3(1.4, 1.6, 9.46), Vector3(1.0, 0.8, 0.04), "2b2a26")
	if evening:
		var glow := window.material_override as StandardMaterial3D
		glow.albedo_color = Color("e9b36a")
		glow.emission_enabled = true
		glow.emission = Color("ffb35a")
		glow.emission_energy_multiplier = 0.6
	# Two dark neighbours down the lane.
	for x: float in [-8.5, 7.5]:
		B.box(host, Vector3(x, 1.4, 12.5), Vector3(4.5, 2.8, 4.0), "6f6a60", true).material_override = HorrorMaterials.tiled("wall_plaster_old", 2.2, Color(0.62, 0.66, 0.6))
		B.box(host, Vector3(x, 2.95, 12.2), Vector3(5.0, 0.2, 4.8), "4b3428").material_override = roof
	# The pier and ông Tư's thúng at its end.
	B.box(host, Vector3(THUNG.x, 0.05, (SHORE_Z + THUNG.z) * 0.5 - 0.6), Vector3(1.8, 0.12, SHORE_Z - THUNG.z + 0.4), "6b5240", true).material_override = HorrorMaterials.tiled("floor_wood_planks", 1.2)
	for z in range(int(SHORE_Z) - 1, int(THUNG.z) - 1, -2):
		for side: float in [-0.8, 0.8]:
			B.box(host, Vector3(THUNG.x + side, -0.6, float(z)), Vector3(0.14, 1.3, 0.14), "3e3024")
	var hull := (load("res://scenes/art_pilots/boat_pilot.tscn") as PackedScene).instantiate() as Node3D
	host.add_child(hull)
	hull.position = THUNG + Vector3(-1.3, WATER_Y - 0.05, -0.4)
	hull.scale = Vector3(1, 0.75, 1)
	# Lamp posts along the shore; the lane sign towards the restaurant.
	for x: float in [-6.0, 4.0]:
		B.box(host, Vector3(x, 1.4, 3.6), Vector3(0.1, 2.8, 0.1), "394a50")
		_lamp(host, Vector3(x, 2.7, 3.6), evening)
	# A small lighthouse on the point, and the far one on Đá Canh Đêm: the dock omens use their beacons.
	SeaWorldBuilder3D.batch_model(host, "lighthouse", NEAR_LIGHTHOUSE, Vector3(0.6, 0.95, 0.6))
	SeaWorldBuilder3D.batch_model(host, "lighthouse", FAR_LIGHTHOUSE)
	var beacons: Array[Vector3] = [NEAR_LIGHTHOUSE + Vector3(0, 3.35, 0), FAR_LIGHTHOUSE + Vector3(0, 3.6, 0)]
	if evening:  # the omens are read before the night's choice
		DockOmens3D.build(host, PIER_POST, beacons, Vector3(THUNG.x, WATER_Y + 0.25, THUNG.z - 2.0))
	B.box(host, LANE + Vector3(0.6, 0.8, 0), Vector3(0.08, 1.6, 0.08), "4a3a2e")
	var sign_ := B.box(host, LANE + Vector3(0.6, 1.5, 0), Vector3(0.05, 0.3, 1.0), "c9b896")
	sign_.rotation.y = 0.0
	var words := B.label(host, "RA QUÁN", LANE + Vector3(0.64, 1.5, 0), 28, "2a2230")
	words.rotation.y = PI * 0.5


static func _water(host: Node3D) -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 110)
	plane.subdivide_width = 120
	plane.subdivide_depth = 80
	water.mesh = plane
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = SeaWater3D.SHADER
	m.set_shader_parameter("reef_z", -40.0)
	m.set_shader_parameter("near_z", -8.0)
	m.set_shader_parameter("boat_pos", Vector3(0, -100, 9999))  # no boat here: no hull hole / ring
	water.material_override = m
	host.add_child(water)
	water.position = Vector3(0, WATER_Y, SHORE_Z - 55.0)


static func _light(host: Node3D, evening: bool) -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.fog_enabled = true
	var moon := DirectionalLight3D.new()
	host.add_child(moon)
	moon.shadow_enabled = true
	if evening:
		env.ambient_light_color = Color("819796")
		env.ambient_light_energy = 0.6
		env.fog_light_color = Color("172038")
		env.fog_density = 0.02
		moon.rotation_degrees = Vector3(-48, 152, 0)  # moon over the sea
		moon.light_color = Color("bacac7")
		moon.light_energy = 0.5
		SeaBackdrop3D.apply_sky(env, moon)
	else:
		# Grey dawn after the night: a pale overcast panorama, no sun.
		var sky_material := PanoramaSkyMaterial.new()
		sky_material.panorama = load("res://assets/textures/sea3d/sky_dawn_overcast.png") as Texture2D
		var sky := Sky.new()
		sky.sky_material = sky_material
		env.sky = sky
		env.background_mode = Environment.BG_SKY
		env.fog_sky_affect = 0.3
		env.ambient_light_color = Color("a9b2b8")
		env.ambient_light_energy = 0.9
		env.fog_light_color = Color("98a2aa")
		env.fog_density = 0.03
		moon.rotation_degrees = Vector3(-35, 140, 0)
		moon.light_color = Color("c8cfd4")
		moon.light_energy = 0.6
	world.environment = env
	host.add_child(world)
	SeaBackdrop3D.build_islands(host)


static func _lamp(host: Node3D, at: Vector3, on: bool) -> void:
	var bulb := B.box(host, at, Vector3(0.22, 0.22, 0.22), "f2d98a" if on else "6b6355")
	if not on:
		return
	var m := bulb.material_override as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color("ffd39b")
	m.emission_energy_multiplier = 1.5
	var light := OmniLight3D.new()
	host.add_child(light)
	light.position = at
	light.light_color = Color("ffc27a")
	light.light_energy = 1.4
	light.omni_range = 9.0
	light.shadow_enabled = true
