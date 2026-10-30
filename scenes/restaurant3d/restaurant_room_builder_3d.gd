class_name RestaurantRoomBuilder3D
extends RefCounted
## Builds the restaurant's static 3D room and fills the host's per-table arrays.
## Host (RestaurantScene3D) fields written: demo_camera, player, body, guests, order_labels,
## orders, dirty_tables, table_plates, ready_plates, bao_model, bao_label.

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")
const STOOL_PILOT = preload("res://assets/models/ready/stool/stool.glb")
const TABLE_PILOT = preload("res://assets/models/ready/table/table.glb")

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
	var beer := RestaurantBatchVisuals.add(root, "beer_tower", Vector3(0, 0.02, 0))
	beer.name = "BeerTower"
	beer.visible = false
	return root

static func build_cat(host: Node3D) -> PersonRig3D:
	var cat := PersonRig3D.build(host, "cat")
	cat.position = Vector3(-2.0, 0, -6.2)
	return cat

static func build(host: Node3D) -> void:
	_lighting(host)
	var depth := L.FRONT_Z - L.BACK_Z
	var mid_z := (L.FRONT_Z + L.BACK_Z) * 0.5
	var width := L.ROOM_X * 2.0
	_shell(host, depth, mid_z, width)
	RestaurantLease3D.build(host)
	_decor(host)
	_tables(host)
	_kitchen(host)
	box(host, Vector3(0, 1.4, L.FRONT_Z), Vector3(width, 3.0, 0.15), "35434d", true).visible = false
	for x: float in [-L.ROOM_X, L.ROOM_X]:
		box(host, Vector3(x, 1.4, mid_z), Vector3(0.15, 3.0, depth), "35434d", true).visible = false
	_player(host)

static func _lighting(host: Node3D) -> void:
	var environment := WorldEnvironment.new()
	environment.name = "RestaurantEnvironment"
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202c38")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("819796")
	settings.ambient_light_energy = 0.3
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		settings.ssao_enabled = true
		settings.ssao_radius = 0.35
		settings.ssao_intensity = 0.9
	environment.environment = settings
	host.add_child(environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "StreetKeyLight"
	host.add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-52, -30, 0)
	sunlight.light_color = Color("ffe1b8")
	sunlight.light_energy = 0.7
	sunlight.shadow_enabled = true
	sunlight.shadow_blur = 2.0
	sunlight.shadow_bias = 0.1
	sunlight.shadow_normal_bias = 2.0
	sunlight.directional_shadow_max_distance = 45.0
	# Downward pools of warm light give tables, people and counters a lit and a shaded side.
	RestaurantStringLights3D.build(host)
	# Keep the existing light rig, positioned over the compact cart-front dining area.
	(host.get_node("DiningStringLights") as Node3D).position.x = 10.3
	for lamp_pos: Vector3 in [Vector3(3, 3.2, -3.2), Vector3(10, 3.2, -3.5)]:
		_shop_light(host, lamp_pos)
	# Low-energy awning fill: it should not erase contact shadows under the furniture.
	for x: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		_lamp(host, Vector3(x, 2.4, L.BACK_Z + 1.6), "ffd9a0", 0.22, 4.0, false)
	var rim := DirectionalLight3D.new()
	rim.name = "CoolStreetFill"
	host.add_child(rim)
	rim.rotation_degrees = Vector3(-30, 150, 0)
	rim.light_color = Color("7f9fc4")
	rim.light_energy = 0.25
	var camera := RestaurantCamera3D.new()
	host.add_child(camera)
	camera.current = true
	host.demo_camera = camera

static func _shop_light(host: Node3D, pos: Vector3) -> void:
	var lamp := SpotLight3D.new()
	lamp.name = "WarmShopLight_%d" % host.get_child_count()
	host.add_child(lamp)
	lamp.position = pos
	lamp.rotation_degrees.x = -90.0
	lamp.light_color = Color("ffd3a0")
	lamp.light_energy = 1.5 if RenderingServer.get_current_rendering_method() == "gl_compatibility" else 4.0
	lamp.spot_range = 6.5
	lamp.spot_angle = 52.0
	lamp.spot_angle_attenuation = 0.6
	lamp.shadow_enabled = true
	lamp.shadow_bias = 0.1
	lamp.shadow_normal_bias = 1.5
	lamp.shadow_blur = 2.0
	# Visible fixture above each light, with its emitting panel below the housing.
	box(host, pos + Vector3(0, 0.12, 0), Vector3(0.72, 0.12, 0.24), "394a50")
	var panel := box(host, pos + Vector3(0, 0.045, 0), Vector3(0.6, 0.025, 0.16), "f2d98a")
	var material := panel.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color("ffd3a0")
	material.emission_energy_multiplier = 0.8

static func _lamp(host: Node3D, pos: Vector3, hex: String, energy: float, range_: float, shadow: bool) -> void:
	var lamp := OmniLight3D.new()
	host.add_child(lamp)
	lamp.position = pos
	lamp.light_color = Color(hex)
	lamp.light_energy = energy
	lamp.omni_range = range_
	lamp.shadow_enabled = shadow

## Floor, back wall, awning, sign, menu board, curb and road.
static func _shell(host: Node3D, depth: float, mid_z: float, width: float) -> void:
	# Coplanar ground receives object shadows without self-shadow acne between tiles.
	box(host, Vector3(0, -0.24, mid_z), Vector3(width, 0.4, depth), "394a50").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for x in range(int(width)):
		for z in range(int(depth)):
			var tile := box(host, Vector3(x - L.ROOM_X + 0.5, -0.02, z + L.BACK_Z + 0.5), Vector3(0.96, 0.05, 0.96), "8e8c79" if (x + z) % 3 == 0 else "797e73")
			tile.name = "LeaseTile_%d_%d" % [x,z]
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	box(host, Vector3(0, L.WALL_H * 0.5, L.BACK_Z - 0.2), Vector3(width, L.WALL_H, 0.3), "b6a183", true)
	box(host, Vector3(0, 0.4, L.BACK_Z - 0.02), Vector3(width, 0.8, 0.1), "577277")
	box(host, Vector3(L.GRILL_POSITION.x, 3.7, L.BACK_Z), Vector3(9, 0.65, 0.14), "7a4841")
	label(host, "HẢI SẢN XÓM ĐÈN", Vector3(L.GRILL_POSITION.x, 3.7, L.BACK_Z + 0.1), 52, "f2d98a")
	for n in range(int(width)):
		var color := "456c65" if n % 2 else "c6b89a"
		box(host, Vector3(n - L.ROOM_X + 0.5, 2.55, L.BACK_Z + 0.9), Vector3(0.98, 0.09, 1.1), color)
		box(host, Vector3(n - L.ROOM_X + 0.5, 2.4, L.BACK_Z + 1.46), Vector3(0.98, 0.24, 0.08), color)
	RestaurantBatchVisuals.add(host, "menu_board", L.BOARD_POSITION)
	solid_block(host, L.BOARD_POSITION + Vector3(0, 0.9, 0), Vector3(1.5, 1.1, 0.12))
	var menu_display := WorldMenuBoard3D.new()
	menu_display.name = "WorldMenuBoard"
	host.add_child(menu_display)
	menu_display.position = L.BOARD_POSITION
	box(host, Vector3(0, -0.05, L.FRONT_Z + 0.1), Vector3(width, 0.2, 0.3), "e7d5b3", true)
	box(host, Vector3(0, -0.2, L.FRONT_Z + 0.2 + L.ROAD_DEPTH * 0.5), Vector3(width, 0.2, L.ROAD_DEPTH), "202e37").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for x in range(-18, 19, 6):
		box(host, Vector3(x, -0.08, L.FRONT_Z + 0.2 + L.ROAD_DEPTH * 0.5), Vector3(2.0, 0.02, 0.15), "8e8c79")

## Lanterns and planters appear with the decor upgrade.
static func _decor(host: Node3D) -> void:
	for x: float in [-17.0, 17.0]:
		RestaurantBatchVisuals.add(host, "sidewalk_tree", Vector3(x, 0, 9.25))
	var decor_level := GameState.get_upgrade_level("decor")
	if decor_level > 0:
		for x in L.DECOR_LANTERNS:
			box(host, Vector3(x, 2.25, L.BACK_Z + 1.2), Vector3(0.04, 0.40, 0.04), "402751")
			box(host, Vector3(x, 2.02, L.BACK_Z + 1.2), Vector3(0.33, 0.28, 0.33), "de9e41")
	if decor_level > 1:
		for x in L.DECOR_PLANTERS:
			RestaurantBatchVisuals.add(host, "plant_pot", Vector3(x, 0, L.PLANTER_Z))

static func add_tables(host: Node3D, start_index: int) -> void:
	_tables(host,start_index)

static func _tables(host: Node3D, start_index := 0) -> void:
	var seats: UpgradeData = host.seats_upgrade
	var table_count := clampi(int(GameState.get_upgrade_value(seats)), 1, L.TABLES.size()) if seats else 4
	for i in range(start_index,table_count):
		var p: Vector3 = L.TABLES[i]
		var table: Node3D = TABLE_PILOT.instantiate()
		table.name = "DiningTable_%d" % i
		host.add_child(table)
		table.position = p
		table.rotation.y = L.TABLE_YAW
		WorldPresentation3D.cast_shadows(table)
		solid_block(host, p + Vector3(0, 0.8, 0), L.TABLE_COLLISION_SIZE)
		for side in [-1.0, 1.0]:
			var stool_pos := p + L.chair_offset(side)
			# Low plastic stool: .47 m footprint and .44 m seat, proportional to people.
			# Scale the collider with the visual so Rin cannot hit an invisible old edge.
			var stool: Node3D = STOOL_PILOT.instantiate()
			host.add_child(stool)
			stool.position = stool_pos
			stool.rotation.y = L.TABLE_YAW
			stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
			WorldPresentation3D.cast_shadows(stool)
			stool.name = "PilotStool_%d_%s" % [i, "blue" if side < 0 else "red"]
			if side > 0:
				var red := mat("a53030")
				for node: Node in stool.find_children("*", "MeshInstance3D", true, false):
					(node as MeshInstance3D).material_override = red
			var stool_size := Vector3(0.55, 0.52, 0.55) * WorldPresentation3D.RESTAURANT_STOOL_SCALE
			solid_block(host, stool_pos + Vector3.UP * stool_size.y * 0.5, stool_size)
		var guest := PersonRig3D.build(host, "guest", "7a4841" if i == 0 else "468232")
		guest.position = RestaurantSeating3D.seat(i,p)
		guest.rotation.y = RestaurantSeating3D.facing(i)
		guest.set_seated(true)
		host.guests.append(guest)
		guest.visible = false
		var partner := PersonRig3D.build(guest,"guest")
		partner.name = "SeatingPartner"
		partner.set_variant("guest_2" if i%2==0 else "guest_1")
		partner.global_position = host.to_global(RestaurantSeating3D.seat(i,p,true))
		partner.rotation.y = PI
		partner.sample_seating(1)
		partner.set_seated(true)
		guest.set_meta("seating_partner",partner)
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
	RestaurantBatchVisuals.upgrade(host, "kitchen", ["food_cart_0", "food_cart_1", "food_cart_2"], L.GRILL_POSITION)
	solid_block(host, L.GRILL_POSITION + Vector3(0, 0.7, 0), Vector3(2.8, 1.3, 1.25))
	RestaurantBatchVisuals.add(host, "charcoal_grill", L.GRILL_POSITION + Vector3(-2.25, 0, 0))
	box(host, L.KITCHEN_BOARD_POSITION + Vector3(0, 0.7, 0), Vector3(1.2, 1.3, 0.1), "884b2b", true)
	label(host, "BẾP\nBẢNG MÓN", L.KITCHEN_BOARD_POSITION + Vector3(0, 0.8, 0.07), 16, "e7d5b3")
	# Cô Năm keeps her grocery counter separate from the kitchen.
	RestaurantBatchVisuals.add(host, "grocery_counter", L.COUNTER_POSITION)
	solid_block(host, L.COUNTER_POSITION + Vector3(0, 0.75, 0), Vector3(3.6, 1.0, 0.8))
	RestaurantBatchVisuals.add(host, "grocery_crate", L.COUNTER_POSITION + Vector3(-2.45, 0, 0))
	RestaurantBatchVisuals.add(host, "crate", L.COUNTER_POSITION + Vector3(2.45, 0, 0))
	RestaurantBatchVisuals.add(host, "bottle", L.COUNTER_POSITION + Vector3(1.2, 1.36, 0.12))
	label(host, "TẠP HOÁ CÔ NĂM", L.COUNTER_POSITION + Vector3(0, 2.4, -0.45), 24, "f2d98a")
	PersonRig3D.build(host, "co_nam").position = L.COUNTER_POSITION + Vector3(-2.1, 0, -0.85)
	# Bảo cooks independently, leaving grill and beer to Rin.
	host.bao_model = PersonRig3D.build(host, "bao")
	host.bao_model.position = L.GRILL_POSITION + Vector3(-1.5, 0, -0.85)
	host.bao_label = label(host, "Bảo • bếp", L.GRILL_POSITION + Vector3(-1.5, 2.15, -0.85), 20, "f0d39b")
	RestaurantBatchVisuals.add(host, "plate_bench", L.PASS_POSITION)
	solid_block(host, L.PASS_POSITION + Vector3(0, 0.83, 0), Vector3(1.1, 0.12, 0.75))
	RestaurantBatchVisuals.add(host, "bin", L.PASS_POSITION + Vector3(-0.95, 0, 0))
	label(host, "NHẬN MÓN • E", L.PASS_POSITION + Vector3(0, 1.5, 0), 18, "e5cf9d")
	RestaurantBatchVisuals.add(host, "beer_keg", L.BEER_POSITION)
	solid_block(host, L.BEER_POSITION + Vector3(0, 0.85, 0), Vector3(0.5, 1.2, 0.5))
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
	(host.demo_camera as RestaurantCamera3D).target = player
	host.body = PersonRig3D.build(player, "rin")
