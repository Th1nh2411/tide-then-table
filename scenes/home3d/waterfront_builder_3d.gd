class_name WaterfrontBuilder3D
extends RefCounted
## Builds Xóm Đèn's waterfront: the village ground, Rin's house (ông Tư's)
## with its door, the pier running out to sea with ông Tư's thúng tied at the
## end, lamp posts, dark neighbours, the lane sign, two lighthouses, and the
## dock omens (DockOmens3D). The sea lies towards -Z, like the night sea's
## north. The village map (VillageBuilder3D) uses the pieces; the epilogue
## (RamEpilogue3D) builds it whole.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const DOOR := Vector3(-1.0, 0, 9.4)
const THUNG := Vector3(6.0, 0, -10.6)
const LANE := Vector3(-14.0, 0, 8.0)
const SHORE_Z := 2.0
const PIER_POST := Vector3(7.0, 0.12, -9.4)
const NEAR_LIGHTHOUSE := Vector3(-11.0, -0.2, -4.0)
const FAR_LIGHTHOUSE := Vector3(30.0, -0.2, -60.0)
const WATER_Y := -0.35


## The whole waterfront on its own (RamEpilogue3D): light, sea, house, lamps.
static func build(host: Node3D, evening: bool) -> void:
	_light(host, evening)
	SeaBackdrop3D.build_islands(host)
	build_ground(host)
	water(host)
	_house(host, evening)
	build_scenery(host)
	for at: Vector3 in lamp_posts(host):
		_lamp(host, at, evening)
	if evening:  # the omens are read before the night's choice
		build_omens(host)


## Village ground and the sandy edge of the shore.
static func build_ground(host: Node3D) -> void:
	# Packed sandy earth, wet sand at the waterline.
	B.box(host, Vector3(0, -0.1, 8.0), Vector3(34, 0.2, 12), "4a4136", true).material_override = HorrorMaterials.tiled("lane_dirt", 3.0, Color(0.95, 0.88, 0.74))
	B.box(host, Vector3(0, -0.12, SHORE_Z + 0.6), Vector3(34, 0.2, 1.4), "8a7a5e", true).material_override = HorrorMaterials.tiled("lane_dirt", 2.0, Color(0.8, 0.74, 0.62))


## Rin's house front as a closed block (the village map builds the real room instead).
static func _house(host: Node3D, _evening: bool) -> void:
	ConceptModel3D.sized(host, "rin_house", Vector3(-1.0, 0, 12.0), Vector3(7.0, 3.6, 5.0), PI)
	B.solid_block(host, Vector3(-1.0, 1.6, 12.0), Vector3(7.0, 3.2, 5.0))



## Neighbours, the pier with ông Tư's thúng, the lighthouses and the lane sign.
static func build_scenery(host: Node3D) -> void:
	for i in range(2):
		var x := -8.5 if i == 0 else 7.5
		ConceptModel3D.sized(host, "neighbour_house_a" if i == 0 else "neighbour_house_b", Vector3(x, 0, 12.5), Vector3(4.5, 2.8, 4.0), PI)
		B.solid_block(host, Vector3(x, 1.4, 12.5), Vector3(4.5, 2.8, 4.0))
	ConceptModel3D.fit(host, "fishing_nets_drying", Vector3(-11.8, 0, 7.0), Vector3(3.0, 1.7, 1.1))
	B.solid_block(host, Vector3(-11.8, 0.7, 7.0), Vector3(2.4, 1.4, 0.5))
	ConceptModel3D.sized(host, "stone_steps", Vector3(10.5, -0.05, 3.5), Vector3(1.4, 0.45, 1.8), PI)
	# The pier and ông Tư's thúng at its end.
	B.box(host, Vector3(THUNG.x, 0.05, (SHORE_Z + THUNG.z) * 0.5 - 0.6), Vector3(1.8, 0.12, SHORE_Z - THUNG.z + 0.4), "6b5240", true).material_override = HorrorMaterials.tiled("floor_wood_planks", 1.2)
	for z in range(int(SHORE_Z) - 1, int(THUNG.z) - 1, -2):
		for side: float in [-0.8, 0.8]:
			B.box(host, Vector3(THUNG.x + side, -0.6, float(z)), Vector3(0.14, 1.3, 0.14), "3e3024")
	var hull := (load("res://scenes/art_pilots/boat_pilot.tscn") as PackedScene).instantiate() as Node3D
	host.add_child(hull)
	hull.position = THUNG + Vector3(-1.3, WATER_Y - 0.05, -0.4)
	hull.scale = Vector3(1, 0.75, 1)
	# Woven bamboo, tarred dark (the bare model reads as a pale disc in a plain hull).
	var weave := HorrorMaterials.tiled("floor_wood_planks", 0.3, Color(0.42, 0.34, 0.26))
	for mesh in hull.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = weave
	# A small lighthouse on the point, and the far one on Đá Canh Đêm: the dock omens use their beacons.
	SeaWorldBuilder3D.batch_model(host, "lighthouse", NEAR_LIGHTHOUSE, Vector3(0.6, 0.95, 0.6))
	SeaWorldBuilder3D.batch_model(host, "lighthouse", FAR_LIGHTHOUSE)
	# Hand-painted plank on a stake pointing up the lane.
	var plank := HorrorMaterials.tiled("door_wood_old", 0.6, Color(0.75, 0.7, 0.62))
	B.box(host, LANE + Vector3(0.6, 0.8, 0), Vector3(0.09, 1.7, 0.09), "4a3a2e").material_override = plank
	B.box(host, LANE + Vector3(0.6, 1.45, 0), Vector3(0.05, 0.32, 1.1), "c9b896").material_override = plank
	B.box(host, LANE + Vector3(0.6, 1.45, -0.62), Vector3(0.05, 0.2, 0.2), "c9b896").rotation.x = PI * 0.25
	var words := B.label(host, "RA QUÁN", LANE + Vector3(0.64, 1.45, 0), 28, "e9dcc0")
	words.rotation.y = PI * 0.5


## Lamp posts along the shore; returns where their bulbs hang.
static func lamp_posts(host: Node3D) -> Array[Vector3]:
	var bulbs: Array[Vector3] = []
	for x: float in [-6.0, 4.0]:
		VillageProps3D.place(host, "lamp_post_village", Vector3(x, 0, 3.6), Vector3(0.5, 3.2, 1.0))
		B.solid_block(host, Vector3(x, 0.6, 3.6), Vector3(0.3, 1.2, 0.3))
		bulbs.append(Vector3(x, 2.88, 3.6 - 0.7))
	return bulbs


## The dock omen props (lanterns, beacons, pier head), seen before the night's choice.
static func build_omens(host: Node3D) -> DockOmens3D:
	var beacons: Array[Vector3] = [NEAR_LIGHTHOUSE + Vector3(0, 3.35, 0), FAR_LIGHTHOUSE + Vector3(0, 3.6, 0)]
	return DockOmens3D.build(host, PIER_POST, beacons, Vector3(THUNG.x, WATER_Y + 0.25, THUNG.z - 2.0))


## The sea off the shore: `size` metres, centred `centre_x` across. The
## shader's zones are in world z, so `world_z` is the host's own z offset.
static func water(host: Node3D, size: Vector2 = Vector2(160, 110), centre_x: float = 0.0, world_z: float = 0.0) -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 120
	plane.subdivide_depth = 80
	water.mesh = plane
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = SeaWater3D.SHADER
	m.set_shader_parameter("reef_z", -40.0 + world_z)
	m.set_shader_parameter("near_z", -8.0 + world_z)
	m.set_shader_parameter("boat_pos", Vector3(0, -100, 9999))  # no boat here: no hull hole / ring
	water.material_override = m
	host.add_child(water)
	water.position = Vector3(centre_x, WATER_Y, SHORE_Z - size.y * 0.5)


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
		var sky := Sky.new()
		sky.sky_material = SeaBackdrop3D.panorama_material(load("res://assets/textures/sea3d/sky_dawn_overcast.png") as Texture2D)
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
