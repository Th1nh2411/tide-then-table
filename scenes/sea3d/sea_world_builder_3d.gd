class_name SeaWorldBuilder3D
extends RefCounted
## Builds the 3D sea's static world, places, boat and phone-map snapshot, and
## animates the decorative bits each frame.
## Host (SeaScene3D) fields written: wave_marks, bubble_spots, wake_marks,
## submerged, whirlpool_marks, rin_figure, boat_lamp, map_boat_proxy.

static var _materials: Dictionary = {}

static func mat(hex: String) -> StandardMaterial3D:
	if _materials.has(hex):
		return _materials[hex]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_materials[hex] = m
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat(hex)
	parent.add_child(node)
	node.position = pos
	return node

static func solid_box(parent: Node3D, pos: Vector3, size: Vector3, hex: String, show_visual: bool = true) -> void:
	box(parent, pos, size, hex).visible = show_visual
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = pos
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

## Lantern-style point light with optional shadows.
static func glow(parent: Node3D, pos: Vector3, hex: String, energy: float, range_: float, shadow: bool) -> OmniLight3D:
	var light := OmniLight3D.new()
	parent.add_child(light)
	light.position = pos
	light.light_color = Color(hex)
	light.light_energy = energy
	light.omni_range = range_
	light.shadow_enabled = shadow
	return light

## Batch-derived visuals are separate from the existing gameplay colliders.
static func batch_model(parent: Node3D, id: String, position_: Vector3 = Vector3.ZERO, scale_: Vector3 = Vector3.ONE) -> Node3D:
	var path := "res://assets/models/ready/" + id + "/" + id + ".glb"
	var visual: Node3D = load(path).instantiate()
	visual.name = "Batch_" + id
	parent.add_child(visual)
	visual.position = position_
	visual.scale = scale_
	WorldPresentation3D.cast_shadows(visual)
	return visual

static func label(parent: Node3D, text: String, pos: Vector3, size: int, hex: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.008
	l.modulate = Color(hex)
	l.outline_size = 0
	parent.add_child(l)
	l.position = pos

static func build_environment(sea: SeaScene3D) -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("090a14")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("819796")
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("172038")
	env.fog_density = 0.018
	if sea.weather:
		env.ambient_light_energy *= sea.weather.night_brightness
		if sea.weather.rain:
			env.fog_density = 0.028
	world_env.environment = env
	sea.add_child(world_env)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -28, 0)
	moon.light_color = Color("bacac7")
	moon.light_energy = 0.6
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 40.0
	moon.shadow_blur = 2.0
	moon.shadow_bias = 0.1
	moon.shadow_normal_bias = 2.0
	sea.add_child(moon)

static func build_world(sea: SeaScene3D) -> void:
	var size := SeaLayout3D.size_world()
	box(sea, Vector3.ZERO, Vector3(size.x, 0.12, size.y), "172038")
	for z_rect: Array in [[SeaLayout3D.NEAR_RECT, "253a5e", 0.07], [SeaLayout3D.REEF_RECT, "202e37", 0.075]]:
		var r := SeaLayout3D.rect_world(z_rect[0])
		box(sea, Vector3(r.get_center().x, float(z_rect[2]), r.get_center().y), Vector3(r.size.x, 0.02, r.size.y), str(z_rect[1]))
	if Story.is_fog_open():
		var fog := SeaLayout3D.rect_world(SeaLayout3D.FOG_RECT)
		box(sea, Vector3(fog.get_center().x, 0.085, fog.get_center().y), Vector3(fog.size.x, 0.02, fog.size.y), "2d4b52")
		sea.add_child(SeaFog3D.new())
	# Land strip behind the dock (the 2D shore).
	var shore_z: float = SeaLayout3D.to_world(Vector2(0, SeaLayout3D.SHORE_PX)).z
	solid_box(sea, Vector3(0, 0.2, (shore_z + size.y * 0.5) * 0.5 + 1.5), Vector3(size.x, 0.42, size.y * 0.5 - shore_z - 3.0), "394a50")
	for i in range(170):
		var x := float((i * 37) % 150) - 75.0
		var z := float((i * 53) % 100) - 50.0
		sea.wave_marks.append(box(sea, Vector3(x, 0.11, z), Vector3(0.3 + 0.2 * (i % 4), 0.015, 0.07), "577277" if i % 3 else "3c5e8b"))
	# Pier just behind the dock point (built around the old 5 -> START.z offset).
	var off := Vector3(sea.START.x, 0.0, sea.START.z - 5.0)
	solid_box(sea, off + Vector3(0, 0.20, 11), Vector3(18, 0.42, 5), "394a50")
	for z in range(9, 16, 2):
		solid_box(sea, off + Vector3(0, 0.45, float(z)), Vector3(3.5, 0.35, 1.7), "7a4841", false)
	# The inferred pier deck sits at the old collision top; posts extend underwater.
	batch_model(sea, "dock", off + Vector3(0, -0.73, 12.0))
	glow(sea, off + Vector3(-3.5, 2.4, 11.0), "ffc27a", 1.6, 9.0, true)
	glow(sea, off + Vector3(4.5, 2.4, 11.0), "ffc27a", 1.2, 8.0, false)
	batch_model(sea, "lighthouse", off + Vector3(-7.8, 0.02, 11.3), Vector3(0.6, 0.95, 0.6))
	label(sea, "BẾN XÓM ĐÈN", off + Vector3(-2.2, 1.6, 13.1), 30, "e7d5b3")
	var rock_index := 0
	for rock in SeaLayout3D.rocks():
		var pos: Vector3 = rock["pos"]
		var radius: float = rock["radius"]
		solid_box(sea, pos + Vector3(0, 0.32, 0), Vector3(radius * 2.2, 0.62, radius * 1.6), "394a50", false)
		var rock_id := "rock_1" if rock_index % 2 == 0 else "rock_2"
		var source_size := Vector3(2.5, 1.2, 2.2) if rock_index % 2 == 0 else Vector3(1.8, 1.5, 1.6)
		batch_model(sea, rock_id, pos + Vector3(0, 0.02, 0), Vector3(radius * 2.2, 0.95, radius * 1.6) / source_size)
		rock_index += 1
		for i in range(5):
			var angle := float(i) * TAU / 5.0
			box(sea, pos + Vector3(cos(angle) * radius * 1.7, 0.11, sin(angle) * radius * 1.3), Vector3(0.52, 0.02, 0.08), "819796")
	for rock in SeaLayout3D.submerged_rocks():
		var hidden := SubmergedRock3D.new()
		sea.add_child(hidden)
		hidden.setup(rock["pos"], float(rock["radius"]), sea.boat)
		sea.submerged.append(hidden)
	solid_box(sea, sea.RAFT_POS + Vector3(0, 0.32, 0), Vector3(5.0, 0.55, 3.0), "7a4841", false)
	batch_model(sea, "lobster_raft", sea.RAFT_POS + Vector3(0, -0.10, 0))
	# Shoals are only hinted by bubbles on the water (BubbleSpot3D).
	var bubble_mat := StandardMaterial3D.new()
	bubble_mat.albedo_color = Color("c9f1f0")
	bubble_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for shoal in sea.shoals:
		var spot := BubbleSpot3D.new()
		sea.add_child(spot)
		spot.setup(shoal, sea.boat, bubble_mat)
		sea.bubble_spots.append(spot)
	for i in range(6):
		var mark := box(sea, Vector3.ZERO, Vector3(0.22 + i * 0.13, 0.02, 0.10), "73bed3" if i % 2 else "a4dddb")
		mark.visible = false
		sea.wake_marks.append(mark)

static func build_pois(sea: SeaScene3D) -> void:
	# Reach points sit in open water. Buildings behind them carry the silhouette.
	batch_model(sea, "whale_shrine", sea.SHRINE_POS + Vector3(-1.4, 0.02, -0.6))
	label(sea, "MIẾU CÁ ÔNG", sea.SHRINE_POS + Vector3(-1.4, 2.0, -0.6), 21, "f2d98a")
	batch_model(sea, "lighthouse", sea.LIGHTHOUSE_POS + Vector3(-1.8, 0.02, -0.6))
	label(sea, "ĐÁ CANH ĐÊM", sea.LIGHTHOUSE_POS + Vector3(-1.8, 3.5, -0.6), 20, "e7d5b3")
	batch_model(sea, "old_man_hut", sea.HUT_POS + Vector3(-1.4, 0.02, -0.5))
	label(sea, "GÒ VỎ ỐC", sea.HUT_POS + Vector3(-1.4, 2.3, -0.5), 20, "f2d98a")
	label(sea, "BÈ TÔM HÙM ANH ÚT", sea.RAFT_POS + Vector3(0, 2.8, 0), 20, "f2d98a")
	glow(sea, sea.SHRINE_POS + Vector3(-1.4, 2.2, 0.4), "9fe0d0", 1.4, 9.0, true)
	glow(sea, sea.LIGHTHOUSE_POS + Vector3(-1.8, 4.0, 0.4), "fff0b0", 2.4, 16.0, true)
	glow(sea, sea.HUT_POS + Vector3(-1.4, 2.0, 0.5), "ffc27a", 1.4, 8.0, true)
	glow(sea, sea.RAFT_POS + Vector3(0, 2.2, 0), "ffc27a", 1.4, 8.0, true)
	if Story.is_fog_open():
		for i in range(18):
			var a := TAU * float(i) / 18.0
			var ring := box(sea, sea.WHIRLPOOL_POS + Vector3(cos(a) * 2.3, 0.16, sin(a) * 2.3),
				Vector3(0.8, 0.025, 0.11), "5ff2e0" if i % 3 == 0 else "73bed3")
			ring.rotation.y = -a
			sea.whirlpool_marks.append(ring)
		box(sea, sea.WHIRLPOOL_POS + Vector3(0, 0.22, 0), Vector3(0.5, 0.08, 0.5), "e6f6ff")
		label(sea, "???", sea.WHIRLPOOL_POS + Vector3(0, 1.2, 0), 28, "5ff2e0")

static func build_map_adapter(sea: SeaScene3D) -> void:
	# PhoneMap expects 2D map coordinates and a Node2D boat. Small proxies
	# preserve its existing pin/legend UI while the sea world itself is 3D.
	var rocks: Array = []
	for rock in SeaLayout3D.rocks():
		rocks.append({"pos": SeaLayout3D.to_map(rock["pos"]), "radius": float(rock["radius"]) * SeaLayout3D.PX_PER_UNIT, "color": Color("577277")})
	var places: Array = [
		{"pos": SeaLayout3D.to_map(sea.RAFT_POS), "label": "Bè tôm hùm anh Út"},
		{"pos": SeaLayout3D.to_map(sea.SHRINE_POS), "label": "Miếu Cá Ông"},
		{"pos": SeaLayout3D.to_map(sea.LIGHTHOUSE_POS), "label": "Hải đăng Đá Canh Đêm"},
		{"pos": SeaLayout3D.to_map(sea.HUT_POS), "label": "Gò Vỏ Ốc"},
		{"pos": SeaLayout3D.to_map(sea.START), "label": "Bến Xóm Đèn"},
	]
	PhoneMap._snap = {
		"size": SeaLayout3D.MAP_PX,
		"zones": [
			{"rect": SeaLayout3D.OPEN_RECT, "color": Color(0.1, 0.28, 0.48), "fog": false, "name": "Khơi xa"},
			{"rect": SeaLayout3D.REEF_RECT, "color": Color(0.16, 0.45, 0.6), "fog": false, "name": "Rạn đá"},
			{"rect": SeaLayout3D.NEAR_RECT, "color": Color(0.35, 0.68, 0.78), "fog": false, "name": "Gần bờ"},
		] + ([{"rect": SeaLayout3D.FOG_RECT, "color": Color(0.2, 0.32, 0.38), "fog": true, "name": "Sương"}] if Story.is_fog_open() else []),
		"land": [Rect2(0, SeaLayout3D.SHORE_PX, SeaLayout3D.MAP_PX.x, SeaLayout3D.MAP_PX.y - SeaLayout3D.SHORE_PX)],
		"rocks": rocks,
		"dock": SeaLayout3D.to_map(sea.START),
		"whirlpool": SeaLayout3D.to_map(sea.WHIRLPOOL_POS),
		"places": places,
		"range_y": lerpf(SeaLayout3D.SHORE_PX, SeaLayout3D.DEEP_PX, sea.boat_data.max_depth) if sea.boat_data.max_depth < 1.0 else -INF,
	}
	sea.map_boat_proxy = Node2D.new()
	sea.map_boat_proxy.add_to_group("boat")
	sea.add_child(sea.map_boat_proxy)
	sea.map_boat_proxy.position = SeaLayout3D.to_map(sea.boat.position)

static func build_boat(sea: SeaScene3D) -> void:
	var boat_id := sea.boat_data.id
	if boat_id == "thuyen_thung":
		# Generated hollow hull; controller/collider, actor and lamp remain separate.
		var hull := preload("res://scenes/art_pilots/boat_pilot.tscn").instantiate()
		hull.name = "HunyuanThungHull"
		# Keep the inferred interior above the sea's flat water planes during bob.
		# Rim remains y=.56; no replacement floor or added hull geometry.
		hull.scale.y = 0.75
		hull.position.y = 0.14
		sea.boat_visual.add_child(hull)
	else:
		batch_model(sea.boat_visual, "ghe_may" if boat_id == "ghe_may" else "ghe_cheo", Vector3(0, 0.12, 0))
	# Bare visual instance (not a PersonRig3D); in person_rin so a cutscene Rin hides it.
	var rider := preload("res://scenes/art_pilots/rin_pilot.tscn").instantiate()
	sea.boat_visual.add_child(rider)
	rider.add_to_group("person_rin")
	rider.name = "RinOnBoat"
	rider.position = Vector3(0, 0.20 if boat_id == "thuyen_thung" else 0.82 if boat_id == "ghe_may" else 0.39, 1.10 if boat_id == "ghe_may" else 0.30)
	rider.scale = Vector3.ONE * 0.85
	rider.rotation.y = PI
	sea.rin_figure = [rider]
	box(sea.boat_visual, Vector3(0.58, 1.02, -0.85), Vector3(0.08, 0.82, 0.08), "e7d5b3")
	box(sea.boat_visual, Vector3(0.58, 1.48, -0.85), Vector3(0.33, 0.22, 0.33), "f2d98a")
	var lamp := SpotLight3D.new()
	sea.boat_visual.add_child(lamp)
	lamp.position = Vector3(0.58, 1.45, -0.85)
	lamp.rotation_degrees.x = -70
	lamp.light_color = Color("f2d98a")
	lamp.light_energy = 2.5
	lamp.spot_range = 14.0
	lamp.spot_angle = 36.0
	lamp.shadow_enabled = true
	sea.boat_lamp = lamp

## Bob, wave marks, whirlpool, net buoys, wake and the follow camera.
static func animate(sea: SeaScene3D, delta: float, forward: Vector3, forward_speed: float) -> void:
	var t := sea.elapsed
	sea.boat_visual.position.y = sin(t * 2.5) * 0.06
	sea.boat_visual.rotation.z = sin(t * 1.8) * 0.025 - sea.yaw_velocity * 0.025
	sea.boat_visual.rotation.x = sin(t * 2.1) * 0.018 + forward_speed * 0.004
	for i in range(sea.wave_marks.size()):
		sea.wave_marks[i].position.y = 0.11 + sin(t * 2.1 + float(i) * 0.7) * 0.012
	var bubble_range := sea._bubble_range()
	for spot in sea.bubble_spots:
		spot.view_range = bubble_range
	for rock in sea.submerged:
		rock.view_range = bubble_range
	for i in range(sea.whirlpool_marks.size()):
		var a := TAU * float(i) / float(sea.whirlpool_marks.size()) + t * 0.65
		sea.whirlpool_marks[i].position = sea.WHIRLPOOL_POS + Vector3(cos(a) * 2.3, 0.16, sin(a) * 2.3)
		sea.whirlpool_marks[i].rotation.y = -a
	for i in range(sea.nets.size()):
		var net_node: Node3D = sea.nets[i]["node"]
		net_node.position.y = sin(t * 2.0 + float(i)) * 0.06
	var boat := sea.boat
	var behind := Vector3.BACK.rotated(Vector3.UP, boat.rotation.y)
	for i in range(sea.wake_marks.size()):
		sea.wake_marks[i].visible = boat.velocity.length() > 0.8
		sea.wake_marks[i].position = boat.position + behind * (1.65 + float(i) * 0.6) + Vector3(0, 0.13, 0)
		sea.wake_marks[i].rotation.y = boat.rotation.y
	var camera_target := boat.position + SeaScene3D.CAMERA_OFFSET.rotated(Vector3.UP, boat.rotation.y)
	sea.camera.position = sea.camera.position.lerp(camera_target, 1.0 - exp(-3.8 * delta))
	sea.camera.look_at(boat.position + forward * SeaScene3D.CAMERA_LOOK_AHEAD + Vector3.UP * .65)
