class_name RestaurantRoomBuilder3D
extends RefCounted
## Builds the restaurant's static 3D room and fills the host's per-table arrays.
## Host (RestaurantScene3D) fields written: demo_camera, player, body, guests, order_labels,
## orders, dirty_tables, table_plates, ready_plates, bao_model, bao_label.

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")
const STOOL_PILOT = preload("res://assets/models/pilots/stool/stool.glb")

static func mat(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, hex: String, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat(hex)
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		solid_block(parent, pos, size)
	return mesh

## Invisible collider only.
static func solid_block(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var obstacle := StaticBody3D.new()
	parent.add_child(obstacle)
	obstacle.position = pos
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	obstacle.add_child(collision)

static func label(parent: Node3D, words: String, pos: Vector3, size: int, hex: String) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.font_size = size
	text.pixel_size = 0.005
	text.modulate = Color(hex)
	text.outline_size = 0
	parent.add_child(text)
	text.position = pos
	return text

static func plate_model(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	box(root, Vector3.ZERO, Vector3(0.36, 0.035, 0.3), "e8d9b7")
	for i: int in range(3):
		box(root, Vector3(-0.1 + i * 0.1, 0.045, 0), Vector3(0.075, 0.05, 0.18), "c97649")
	return root

static func build_cat(host: Node3D) -> PersonRig3D:
	var cat := PersonRig3D.build(host, "cat")
	cat.position = Vector3(-3.3, 0, -6.6)
	return cat

static func build(host: Node3D) -> void:
	_lighting(host)
	var depth := L.FRONT_Z - L.BACK_Z
	var mid_z := (L.FRONT_Z + L.BACK_Z) * 0.5
	var width := L.ROOM_X * 2.0
	_shell(host, depth, mid_z, width)
	_decor(host)
	_tables(host)
	_kitchen(host)
	box(host, Vector3(0, 1.4, L.FRONT_Z), Vector3(width, 3.0, 0.15), "35434d", true).visible = false
	for x: float in [-L.ROOM_X, L.ROOM_X]:
		box(host, Vector3(x, 1.4, mid_z), Vector3(0.15, 3.0, depth), "35434d", true).visible = false
	_player(host)

static func _lighting(host: Node3D) -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202c38")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9aa8b4")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	host.add_child(environment)
	var sunlight := DirectionalLight3D.new()
	host.add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-52, -30, 0)
	sunlight.light_color = Color("ffd39b")
	sunlight.light_energy = 1.1
	sunlight.shadow_enabled = true
	var lamp := OmniLight3D.new()
	host.add_child(lamp)
	lamp.position = Vector3(3, 2.8, -3.2)
	lamp.light_color = Color("ffc27a")
	lamp.light_energy = 1.0
	lamp.omni_range = 5.0
	var camera := Camera3D.new()
	host.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(4.5, 12, 15)
	camera.look_at(Vector3(0, 0, -0.5))
	camera.current = true
	host.demo_camera = camera

## Floor, back wall, awning, sign, menu board, curb and road.
static func _shell(host: Node3D, depth: float, mid_z: float, width: float) -> void:
	box(host, Vector3(0, -0.24, mid_z), Vector3(width, 0.4, depth), "394a50")
	for x in range(int(width)):
		for z in range(int(depth)):
			box(host, Vector3(x - L.ROOM_X + 0.5, -0.02, z + L.BACK_Z + 0.5), Vector3(0.96, 0.05, 0.96), "8e8c79" if (x + z) % 3 == 0 else "797e73")
	box(host, Vector3(0, L.WALL_H * 0.5, L.BACK_Z - 0.2), Vector3(width, L.WALL_H, 0.3), "b6a183", true)
	box(host, Vector3(0, 0.4, L.BACK_Z - 0.02), Vector3(width, 0.8, 0.1), "577277")
	box(host, Vector3(0, 3.7, L.BACK_Z), Vector3(9, 0.65, 0.14), "7a4841")
	label(host, "HẢI SẢN XÓM ĐÈN", Vector3(0, 3.7, L.BACK_Z + 0.1), 52, "f2d98a")
	for n in range(int(width)):
		var color := "456c65" if n % 2 else "c6b89a"
		box(host, Vector3(n - L.ROOM_X + 0.5, 2.55, L.BACK_Z + 0.9), Vector3(0.98, 0.09, 1.1), color)
		box(host, Vector3(n - L.ROOM_X + 0.5, 2.4, L.BACK_Z + 1.46), Vector3(0.98, 0.24, 0.08), color)
	box(host, L.BOARD_POSITION + Vector3(0, 0.9, 0), Vector3(1.5, 1.1, 0.12), "1c2a33", true)
	label(host, "THỰC ĐƠN", L.BOARD_POSITION + Vector3(0, 1.1, 0.1), 28, "f2d98a")
	box(host, Vector3(0, -0.05, L.FRONT_Z + 0.1), Vector3(width, 0.2, 0.3), "e7d5b3", true)
	box(host, Vector3(0, -0.2, L.FRONT_Z + 0.2 + L.ROAD_DEPTH * 0.5), Vector3(width, 0.2, L.ROAD_DEPTH), "202e37")
	for x in range(-18, 19, 6):
		box(host, Vector3(x, -0.08, L.FRONT_Z + 0.2 + L.ROAD_DEPTH * 0.5), Vector3(2.0, 0.02, 0.15), "8e8c79")

## Lanterns and planters appear with the decor upgrade.
static func _decor(host: Node3D) -> void:
	var decor_level := GameState.get_upgrade_level("decor")
	if decor_level > 0:
		for x in L.DECOR_LANTERNS:
			box(host, Vector3(x, 2.25, L.BACK_Z + 1.2), Vector3(0.04, 0.40, 0.04), "402751")
			box(host, Vector3(x, 2.02, L.BACK_Z + 1.2), Vector3(0.33, 0.28, 0.33), "de9e41")
	if decor_level > 1:
		for x in L.DECOR_PLANTERS:
			box(host, Vector3(x, 0.36, L.PLANTER_Z), Vector3(0.6, 0.72, 0.6), "7a4841")
			box(host, Vector3(x, 0.87, L.PLANTER_Z), Vector3(0.85, 0.45, 0.85), "468232")

static func _tables(host: Node3D) -> void:
	var seats: UpgradeData = host.seats_upgrade
	var table_count := clampi(int(GameState.get_upgrade_value(seats)), 1, L.TABLES.size()) if seats else 4
	for i in range(table_count):
		var p: Vector3 = L.TABLES[i]
		box(host, p + Vector3(0, 0.8, 0), Vector3(1.5, 0.12, 1.2), "c7cfcc", true)
		for x in [-0.57, 0.57]:
			for z in [-0.4, 0.4]:
				box(host, p + Vector3(x, 0.4, z), Vector3(0.07, 0.8, 0.07), "577277")
		for side in [-1.0, 1.0]:
			var stool_pos := p + Vector3(side * 1.02, 0, 0)
			# Actual Hunyuan-derived stool, canonical .55 x .55 x .52 m.
			# The collider below stays identical to preserve pathing/interactions.
			var stool: Node3D = STOOL_PILOT.instantiate()
			host.add_child(stool)
			stool.position = stool_pos
			stool.name = "PilotStool_%d_%s" % [i, "blue" if side < 0 else "red"]
			if side > 0:
				var red := mat("a53030")
				for node: Node in stool.find_children("*", "MeshInstance3D", true, false):
					(node as MeshInstance3D).material_override = red
			solid_block(host, stool_pos + Vector3(0, 0.26, 0), Vector3(0.55, 0.52, 0.55))
		var guest := PersonRig3D.build(host, "guest", "7a4841" if i == 0 else "468232")
		guest.position = p + Vector3(0, 0, 1.15)
		host.guests.append(guest)
		guest.visible = false
		host.order_labels.append(label(host, "", p + Vector3(0, 2.25, 0.6), 18, "f2d98a"))
		host.orders.append({})
		host.dirty_tables.append(false)
		var dish_visual := plate_model(host)
		dish_visual.position = p + Vector3(0, 0.9, 0)
		dish_visual.visible = false
		host.table_plates.append(dish_visual)
		var ready := plate_model(host)
		ready.position = L.PASS_POSITION + Vector3((i % 4) * 0.18 - 0.3, 0.95 + (i / 4) * 0.08, 0)
		ready.visible = false
		host.ready_plates.append(ready)

## Grill, kitchen sign, Cô Năm's counter, Bảo, plate pass and beer tap.
static func _kitchen(host: Node3D) -> void:
	box(host, L.GRILL_POSITION + Vector3(0, 0.7, 0), Vector3(2.8, 1.3, 1.25), "577277", true)
	box(host, L.GRILL_POSITION + Vector3(0, 1.42, 0), Vector3(3, 0.12, 1.4), "c7cfcc")
	box(host, L.GRILL_POSITION + Vector3(-0.4, 1.52, 0), Vector3(1.2, 0.1, 0.65), "394a50")
	for n in range(6):
		box(host, L.GRILL_POSITION + Vector3(-0.88 + n * 0.18, 1.6, 0), Vector3(0.06, 0.05, 0.48), "de9e41")
	box(host, Vector3(5.5, 0.7, 1.5), Vector3(1.2, 1.3, 0.1), "884b2b", true)
	label(host, "BẾP   E\nBẢNG MÓN", Vector3(5.5, 0.8, 1.57), 16, "e7d5b3")
	# Cô Năm keeps her grocery counter separate from the kitchen.
	box(host, L.COUNTER_POSITION + Vector3(0, 0.75, 0), Vector3(3.6, 1.0, 0.8), "468232", true)
	box(host, L.COUNTER_POSITION + Vector3(0, 1.3, 0), Vector3(3.8, 0.12, 1.0), "e7d5b3")
	label(host, "TẠP HOÁ CÔ NĂM", L.COUNTER_POSITION + Vector3(0, 2.4, -0.45), 24, "f2d98a")
	PersonRig3D.build(host, "co_nam").position = L.COUNTER_POSITION + Vector3(0, 0, -0.85)
	# Bảo cooks independently, leaving grill and beer to Rin.
	host.bao_model = PersonRig3D.build(host, "bao")
	host.bao_model.position = L.GRILL_POSITION + Vector3(-0.7, 0, -1.3)
	host.bao_label = label(host, "Bảo • bếp", L.GRILL_POSITION + Vector3(-0.7, 2.35, -1.3), 20, "f0d39b")
	box(host, L.PASS_POSITION + Vector3(0, 0.83, 0), Vector3(1.1, 0.12, 0.75), "a27d4c", true)
	for x: float in [-0.4, 0.4]:
		box(host, L.PASS_POSITION + Vector3(x, 0.4, 0), Vector3(0.07, 0.8, 0.6), "685448")
	label(host, "NHẬN MÓN • E", L.PASS_POSITION + Vector3(0, 1.5, 0), 18, "e5cf9d")
	box(host, L.BEER_POSITION + Vector3(0, 0.85, 0), Vector3(0.5, 1.2, 0.5), "91a4a3", true)
	label(host, "RÓT BIA • E", L.BEER_POSITION + Vector3(0, 1.75, 0), 18, "e5cf9d")

static func _player(host: Node3D) -> void:
	var player := CharacterBody3D.new()
	host.add_child(player)
	player.position = Vector3(0, 0, 2)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.6
	collider.shape = capsule
	collider.position.y = 0.8
	player.add_child(collider)
	host.player = player
	host.body = PersonRig3D.build(player, "rin")
