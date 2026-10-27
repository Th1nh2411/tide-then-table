extends Node3D
## Standalone 3D gameplay prototype. No save or live-game state is touched.

enum Mode { RESTAURANT, SEA, FISHING }
const FISH_CATALOG = preload("res://data/fish/fish_catalog.tres")

var mode := Mode.RESTAURANT
var gold := 0
var fish := 0
var served := 0
var progress := 0.0
var player: Node3D
var camera: Camera3D
var world: Node3D
var hud: Label
var fishing_panel: ColorRect
var fishing_label: Label
var fishing_bar: ProgressBar
var target := 0.5
var boat_speed := 0.0
var boat_visual: Node3D
var sea_time := 0.0
var boat_velocity := Vector3.ZERO
var turn_velocity := 0.0
var restaurant_velocity := Vector3.ZERO
var rin_visual: Node3D
var rin_arms: Array[Node3D] = []
var rin_legs: Array[Node3D] = []
var guests: Array[Node3D] = []
var waves: Array[MeshInstance3D] = []
var buoys: Array[Node3D] = []
var wake: Array[MeshInstance3D] = []
var motion_time := 0.0

func material(color: String) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return result

func block(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: String, sides: int = 8) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = sides
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func _sign(text: String, pos: Vector3, font_size: int, color: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.005
	label.modulate = Color(color)
	label.outline_size = 0
	world.add_child(label)
	label.position = pos

func _stool(pos: Vector3, color: String) -> void:
	block(world, pos + Vector3(0, 0.48, 0), Vector3(0.62, 0.12, 0.62), color)
	for x in [-0.22, 0.22]:
		for z in [-0.22, 0.22]:
			block(world, pos + Vector3(x, 0.24, z), Vector3(0.07, 0.45, 0.07), color)

func _table(pos: Vector3) -> void:
	block(world, pos + Vector3(0, 0.79, 0), Vector3(1.5, 0.11, 1.18), "a8b8b0")
	for x in [-0.58, 0.58]:
		for z in [-0.43, 0.43]:
			block(world, pos + Vector3(x, 0.38, z), Vector3(0.08, 0.74, 0.08), "596e72")
	# A ceramic dish, chopsticks and a little red sauce keep the food readable.
	cylinder(world, pos + Vector3(-0.24, 0.88, 0.05), 0.27, 0.035, "eadab2", 10)
	for n in range(3):
		block(world, pos + Vector3(-0.38 + n * 0.11, 0.91, 0.06), Vector3(0.07, 0.035, 0.22), "bb7150")
	block(world, pos + Vector3(0.30, 0.90, -0.18), Vector3(0.08, 0.025, 0.34), "aa8c60")
	block(world, pos + Vector3(0.36, 0.90, -0.18), Vector3(0.08, 0.025, 0.34), "aa8c60")

func _guest(pos: Vector3, shirt: String) -> void:
	var guest := Node3D.new()
	world.add_child(guest)
	guest.position = pos
	guests.append(guest)
	block(guest, Vector3(0, 0.92, 0), Vector3(0.44, 0.68, 0.35), shirt)
	block(guest, Vector3(0, 1.48, 0), Vector3(0.38, 0.38, 0.37), "b68a68")
	block(guest, Vector3(0, 1.69, -0.03), Vector3(0.43, 0.11, 0.41), "303c43")
	for side in [-1.0, 1.0]:
		block(guest, Vector3(side * 0.29, 0.92, 0.12), Vector3(0.11, 0.5, 0.13), "b68a68")
		block(guest, Vector3(side * 0.12, 0.39, 0), Vector3(0.14, 0.45, 0.18), "344552")

func _ready() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("182b39")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	env.environment = settings
	add_child(env)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0
	add_child(camera)
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(14, 12)
	hud.add_theme_font_size_override("font_size", 15)
	hud.add_theme_color_override("font_color", Color("f1dfb1"))
	layer.add_child(hud)
	fishing_panel = ColorRect.new()
	fishing_panel.color = Color("102535ee")
	fishing_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	fishing_panel.visible = false
	layer.add_child(fishing_panel)
	fishing_label = Label.new()
	fishing_label.position = Vector2(130, 95)
	fishing_label.add_theme_font_size_override("font_size", 19)
	fishing_label.text = "CÂU CÁ / CANH VẠCH GIỮA\nA / D: di chuyển cần   SPACE: kéo   ESC: thoát"
	fishing_panel.add_child(fishing_label)
	fishing_bar = ProgressBar.new()
	fishing_bar.position = Vector2(130, 185)
	fishing_bar.size = Vector2(380, 28)
	fishing_bar.show_percentage = false
	fishing_panel.add_child(fishing_bar)
	_build_restaurant()

func _clear_world() -> void:
	rin_arms.clear()
	rin_legs.clear()
	guests.clear()
	waves.clear()
	buoys.clear()
	wake.clear()
	if is_instance_valid(world):
		world.queue_free()
	world = Node3D.new()
	add_child(world)
	player = Node3D.new()
	world.add_child(player)

func _build_restaurant() -> void:
	mode = Mode.RESTAURANT
	_clear_world()
	motion_time = 0.0
	restaurant_velocity = Vector3.ZERO
	# Street edge and old patterned cement tiles.
	block(world, Vector3(0, -0.20, 0), Vector3(16, 0.30, 11), "344854")
	for ix in range(16):
		for iz in range(11):
			var tile_color := "85877b" if (ix + iz) % 2 == 0 else "a29c83"
			block(world, Vector3(ix - 7.5, -0.025, iz - 5.0), Vector3(0.97, 0.04, 0.97), tile_color)
			if (ix + iz) % 4 == 0:
				block(world, Vector3(ix - 7.5, 0.0, iz - 5.0), Vector3(0.12, 0.015, 0.12), "53666a")
	block(world, Vector3(0, -0.02, 5.35), Vector3(16, 0.12, 0.30), "d2bd93")
	block(world, Vector3(0, -0.18, 6.05), Vector3(16, 0.22, 1.0), "3b4c59")
	for x in range(-7, 8, 3):
		block(world, Vector3(float(x), -0.06, 6.12), Vector3(1.0, 0.02, 0.06), "c7ae70")
	# Open-front shop, brick base, rolling door, painted sign and striped awning.
	block(world, Vector3(0, 1.5, -5.43), Vector3(16, 3.0, 0.24), "b4a083")
	block(world, Vector3(0, 0.39, -5.27), Vector3(16, 0.78, 0.08), "698079")
	for x in range(-7, 8, 2):
		block(world, Vector3(float(x), 1.33, -5.26), Vector3(0.05, 0.04, 0.03), "8c7059")
	block(world, Vector3(-5.1, 1.56, -5.18), Vector3(2.25, 2.85, 0.12), "485d60")
	for n in range(15):
		block(world, Vector3(-5.1, 0.20 + n * 0.17, -5.08), Vector3(2.1, 0.025, 0.025), "788987")
	block(world, Vector3(2.2, 1.54, -5.19), Vector3(2.5, 2.8, 0.11), "536d67")
	block(world, Vector3(0, 3.06, -5.12), Vector3(9.0, 0.67, 0.18), "7e403a")
	_sign("HẢI SẢN XÓM ĐÈN", Vector3(0, 3.04, -5.00), 55, "eed59e")
	for n in range(16):
		var stripe := "47716d" if n % 2 == 0 else "d3c3a0"
		block(world, Vector3(-7.5 + n, 2.55, -4.25), Vector3(0.98, 0.08, 1.62), stripe)
		block(world, Vector3(-7.5 + n, 2.40, -3.47), Vector3(0.98, 0.27, 0.07), stripe)
	# Tables leave the center aisle open for gameplay.
	for pos in [Vector3(-4.6, 0, -1.8), Vector3(-4.6, 0, 1.45), Vector3(-1.8, 0, -1.8)]:
		_table(pos)
		_stool(pos + Vector3(-1.05, 0, 0.15), "38667d")
		_stool(pos + Vector3(1.05, 0, 0.15), "9b4846")
	_guest(Vector3(-4.6, 0, 2.55), "496b67")
	_guest(Vector3(-1.8, 0, -0.76), "9a5a49")
	# Stainless cart and charcoal grill mark the existing E interaction point.
	block(world, Vector3(5, 0.66, -2.9), Vector3(3.0, 1.05, 1.25), "647e82")
	block(world, Vector3(5, 1.23, -2.9), Vector3(3.2, 0.12, 1.42), "b6c1b5")
	block(world, Vector3(5, 1.31, -2.88), Vector3(1.15, 0.12, 0.66), "37434c")
	for n in range(6):
		block(world, Vector3(4.5 + n * 0.19, 1.4, -2.88), Vector3(0.07, 0.045, 0.54), "c9a975")
	for x in [3.75, 6.25]:
		var wheel := cylinder(world, Vector3(x, 0.20, -2.16), 0.22, 0.10, "2a3540")
		wheel.rotation.x = PI / 2
	for x in [3.7, 6.3]:
		block(world, Vector3(x, 1.75, -3.48), Vector3(0.08, 1.1, 0.08), "a8b8b0")
	block(world, Vector3(5, 2.28, -3.48), Vector3(2.7, 0.11, 0.65), "914743")
	cylinder(world, Vector3(5.95, 1.52, -2.9), 0.25, 0.42, "53646b")
	cylinder(world, Vector3(5.95, 1.76, -2.9), 0.27, 0.06, "e2d9bb")
	block(world, Vector3(6.80, 0.45, -0.35), Vector3(1.05, 0.9, 0.85), "8baca9")
	block(world, Vector3(6.80, 0.94, -0.35), Vector3(1.14, 0.10, 0.94), "e0d5b6")
	# Menu board and practical lamps are solid geometry, not billboards.
	block(world, Vector3(1.1, 0.82, 2.6), Vector3(1.1, 1.34, 0.09), "9c7950")
	block(world, Vector3(1.1, 0.85, 2.67), Vector3(0.97, 1.18, 0.025), "263d43")
	_sign("HÔM NAY\nMỰC NƯỚNG\nTÔM LUỘC", Vector3(1.1, 0.87, 2.70), 17, "e5d29f")
	for x in [0.72, 1.48]:
		block(world, Vector3(x, 0.18, 2.6), Vector3(0.07, 0.36, 0.12), "9c7950")
	for x in [-4.5, 0.0, 5.0]:
		block(world, Vector3(x, 2.30, -3.45), Vector3(0.38, 0.14, 0.38), "f2daa3")
		block(world, Vector3(x, 2.48, -3.45), Vector3(0.05, 0.30, 0.05), "36454a")
	# Separate pivots produce stepped PSX walk motion without 2D billboards.
	rin_visual = Node3D.new()
	player.add_child(rin_visual)
	block(rin_visual, Vector3(0, 1.06, 0), Vector3(0.43, 0.62, 0.32), "e6ddc7")
	block(rin_visual, Vector3(0, 0.68, 0), Vector3(0.43, 0.22, 0.33), "2d3b47")
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		rin_visual.add_child(leg)
		leg.position = Vector3(side * 0.13, 0.57, 0)
		block(leg, Vector3(0, -0.23, 0), Vector3(0.14, 0.5, 0.18), "b88665")
		rin_legs.append(leg)
		var arm := Node3D.new()
		rin_visual.add_child(arm)
		arm.position = Vector3(side * 0.29, 1.33, 0)
		block(arm, Vector3(0, -0.30, 0), Vector3(0.12, 0.62, 0.14), "b88665")
		rin_arms.append(arm)
	block(rin_visual, Vector3(0, 1.72, 0), Vector3(0.41, 0.41, 0.37), "bd8c69")
	block(rin_visual, Vector3(0, 1.99, -0.02), Vector3(0.48, 0.15, 0.43), "26333e")
	for x in [-0.11, 0.11]:
		block(rin_visual, Vector3(x, 1.76, 0.19), Vector3(0.17, 0.11, 0.035), "29353e")
	player.position = Vector3(0, 0, 2.5)
	camera.position = Vector3(6.5, 11.5, 14.5)
	camera.look_at(Vector3(0, 0.8, -0.35))
	_update_hud()

func _build_sea() -> void:
	mode = Mode.SEA
	_clear_world()
	# Flat depth bands and short broken foam strokes keep the water legible.
	block(world, Vector3.ZERO, Vector3(95, 0.10, 95), "172038")
	block(world, Vector3(0, 0.055, 26), Vector3(94, 0.015, 38), "253a5e")
	block(world, Vector3(-18, 0.065, -5), Vector3(16, 0.015, 56), "202e37")
	for i in range(100):
		var x := float((i * 37) % 87) - 43.0
		var z := float((i * 53) % 83) - 41.0
		var length := 0.35 + float(i % 4) * 0.23
		waves.append(block(world, Vector3(x, 0.092, z), Vector3(length, 0.012, 0.055), "577277" if i % 3 else "3c5e8b"))
	# Xóm Đèn shore, pier and a small beacon stay behind the launch point.
	block(world, Vector3(0, 0.10, 10.5), Vector3(17, 0.28, 5), "394a50")
	for i in range(17):
		block(world, Vector3(i - 8.0, 0.27, 8.4), Vector3(0.8, 0.15, 0.45), "819796" if i % 3 else "577277")
	for z in range(9, 16, 2):
		block(world, Vector3(0, 0.40, float(z)), Vector3(3.5, 0.24, 1.65), "7a4841")
		for x in [-1.4, 1.4]:
			block(world, Vector3(x, 0.12, float(z)), Vector3(0.20, 0.45, 0.22), "402751")
	block(world, Vector3(0, 0.53, 8.4), Vector3(3.9, 0.05, 0.12), "e7d5b3")
	block(world, Vector3(-6.3, 1.38, 10.5), Vector3(0.9, 2.5, 0.9), "e7d5b3")
	block(world, Vector3(-6.3, 2.66, 10.5), Vector3(1.16, 0.28, 1.16), "a53030")
	block(world, Vector3(-6.3, 2.92, 10.5), Vector3(0.48, 0.23, 0.48), "f2d98a")
	for n in range(4):
		block(world, Vector3(-6.3 + n * 0.35, 0.105, 7.7 - n * 0.48), Vector3(0.32, 0.012, 0.07), "e8c170")
	# Distant silhouettes give landmarks without adding gameplay collision.
	for pos in [Vector3(-18, 0, -14), Vector3(20, 0, -20), Vector3(-25, 0, -35)]:
		block(world, pos + Vector3(0, 0.28, 0), Vector3(3.2, 0.48, 2.0), "394a50")
		block(world, pos + Vector3(-0.8, 0.67, -0.2), Vector3(0.9, 0.62, 1.0), "577277")
		block(world, pos + Vector3(1.0, 0.57, 0.3), Vector3(1.1, 0.42, 0.8), "202e37")
		for n in range(5):
			var angle := float(n) * TAU / 5.0
			block(world, pos + Vector3(cos(angle) * 2.1, 0.11, sin(angle) * 1.5), Vector3(0.45, 0.02, 0.07), "819796")
	block(world, Vector3(25, 0.36, -8), Vector3(5.0, 0.24, 2.9), "7a4841")
	for x in [22.8, 25.0, 27.2]:
		block(world, Vector3(x, 0.63, -8), Vector3(1.7, 0.18, 2.2), "ad7757")
	block(world, Vector3(27, 1.45, -9), Vector3(0.16, 1.8, 0.16), "e7d5b3")
	block(world, Vector3(27, 2.42, -9), Vector3(0.42, 0.25, 0.42), "f2d98a")
	# Three readable fishing patches match the existing Space trigger positions.
	for spot in [Vector3(5, 0, -12), Vector3(-10, 0, -22), Vector3(15, 0, -30)]:
		block(world, spot + Vector3(0, 0.08, 0), Vector3(5.8, 0.02, 5.8), "25562e")
		for segment in range(12):
			var angle := float(segment) * TAU / 12.0
			var foam := block(world, spot + Vector3(cos(angle) * 2.6, 0.13, sin(angle) * 2.6), Vector3(0.9, 0.025, 0.10), "a4dddb" if segment % 2 else "73bed3")
			foam.rotation.y = -angle
		for n in range(5):
			var offset := Vector3(float((n * 11) % 7) - 3.0, 0.17, float((n * 7) % 5) - 2.0) * 0.48
			block(world, spot + offset, Vector3(0.24, 0.02, 0.10), "5ff2e0")
		var buoy := Node3D.new()
		world.add_child(buoy)
		buoy.position = spot
		buoys.append(buoy)
		cylinder(buoy, Vector3(0, 0.27, 0), 0.19, 0.38, "e7d5b3", 8)
		block(buoy, Vector3(0, 0.50, 0), Vector3(0.28, 0.17, 0.28), "cf573c")
	# Boat and Rin are separate rigid pieces so the hull can bob as one.
	boat_visual = Node3D.new()
	player.add_child(boat_visual)
	block(boat_visual, Vector3(0, 0.22, 0), Vector3(1.55, 0.28, 3.05), "402751")
	block(boat_visual, Vector3(0, 0.44, 0.15), Vector3(1.72, 0.27, 2.35), "7a4841")
	block(boat_visual, Vector3(0, 0.62, -1.08), Vector3(1.22, 0.17, 0.85), "ad7757")
	block(boat_visual, Vector3(0, 0.57, 0.15), Vector3(1.22, 0.10, 1.68), "c09473")
	for x in [-0.73, 0.73]:
		block(boat_visual, Vector3(x, 0.72, 0.08), Vector3(0.11, 0.35, 2.45), "be772b")
	for z in [-0.63, 0.18, 0.95]:
		block(boat_visual, Vector3(0, 0.66, z), Vector3(1.31, 0.06, 0.13), "884b2b")
	block(boat_visual, Vector3(0, 1.12, 0.30), Vector3(0.36, 0.77, 0.30), "e7d5b3")
	block(boat_visual, Vector3(0, 1.63, 0.30), Vector3(0.34, 0.34, 0.34), "ad7757")
	block(boat_visual, Vector3(0, 1.83, 0.30), Vector3(0.65, 0.10, 0.65), "e8c170")
	block(boat_visual, Vector3(0, 1.92, 0.30), Vector3(0.31, 0.13, 0.31), "be772b")
	block(boat_visual, Vector3(0.58, 1.02, -0.85), Vector3(0.08, 0.82, 0.08), "e7d5b3")
	block(boat_visual, Vector3(0.58, 1.48, -0.85), Vector3(0.33, 0.22, 0.33), "f2d98a")
	for i in range(6):
		var wake_piece := block(world, Vector3.ZERO, Vector3(0.25 + i * 0.18, 0.02, 0.09), "73bed3" if i % 2 else "a4dddb")
		wake_piece.visible = false
		wake.append(wake_piece)
	player.position = Vector3(0, 0, 5)
	player.rotation.y = 0.0
	boat_speed = 0.0
	boat_velocity = Vector3.ZERO
	turn_velocity = 0.0
	sea_time = 0.0
	camera.global_position = player.global_position + Vector3(0, 8, 11)
	camera.look_at(player.global_position)
	_update_hud()

func _restaurant_blocked(pos: Vector3) -> bool:
	if absf(pos.x) > 7.4 or pos.z < -4.5 or pos.z > 4.8:
		return true
	for table_pos in [Vector3(-4.6, 0, -1.8), Vector3(-4.6, 0, 1.45), Vector3(-1.8, 0, -1.8)]:
		if absf(pos.x - table_pos.x) < 1.15 and absf(pos.z - table_pos.z) < 0.95:
			return true
	if pos.x > 3.15 and pos.x < 6.85 and pos.z > -3.95 and pos.z < -1.95:
		return true
	if absf(pos.x - 1.1) < 0.7 and absf(pos.z - 2.6) < 0.55:
		return true
	return false

func _sea_blocked(pos: Vector3) -> bool:
	if absf(pos.x) > 42.5 or absf(pos.z) > 42.5:
		return true
	if pos.z > 7.0 and absf(pos.x) < 9.5:
		return true
	for rock_pos in [Vector3(-18, 0, -14), Vector3(20, 0, -20), Vector3(-25, 0, -35)]:
		if pos.distance_to(rock_pos) < 2.8:
			return true
	if pos.distance_to(Vector3(25, 0, -8)) < 3.8:
		return true
	return false

func _physics_process(delta: float) -> void:
	if mode == Mode.RESTAURANT:
		motion_time += delta
		var input := Vector2(Input.get_axis("turn_left", "turn_right"), Input.get_axis("throttle_forward", "throttle_back")).normalized()
		var desired := Vector3(input.x, 0, input.y) * 4.2
		restaurant_velocity = restaurant_velocity.move_toward(desired, delta * (20.0 if input.length() > 0 else 27.0))
		var next_x := player.position + Vector3(restaurant_velocity.x * delta, 0, 0)
		if not _restaurant_blocked(next_x):
			player.position.x = next_x.x
		else:
			restaurant_velocity.x = 0.0
		var next_z := player.position + Vector3(0, 0, restaurant_velocity.z * delta)
		if not _restaurant_blocked(next_z):
			player.position.z = next_z.z
		else:
			restaurant_velocity.z = 0.0
		if restaurant_velocity.length() > 0.2:
			player.rotation.y = lerp_angle(player.rotation.y, atan2(restaurant_velocity.x, restaurant_velocity.z), minf(delta * 12.0, 1.0))
		var step := floorf(motion_time * 8.0) / 8.0
		var walking := minf(restaurant_velocity.length() / 4.2, 1.0)
		rin_visual.position.y = absf(sin(step * 11.0)) * 0.055 * walking
		for i in range(2):
			var side := -1.0 if i == 0 else 1.0
			rin_legs[i].rotation.x = side * sin(step * 11.0) * 0.42 * walking
			rin_arms[i].rotation.x = -side * sin(step * 11.0) * 0.36 * walking
		for i in range(guests.size()):
			guests[i].position.y = sin(floorf(motion_time * 5.0 + float(i) * 2.0)) * 0.035
			guests[i].rotation.z = sin(floorf(motion_time * 3.0 + float(i))) * 0.012
	elif mode == Mode.SEA:
		sea_time += delta
		var steer := Input.get_axis("turn_left", "turn_right")
		var thrust := Input.get_axis("throttle_back", "throttle_forward")
		var forward := Vector3.FORWARD.rotated(Vector3.UP, player.rotation.y)
		boat_velocity += forward * thrust * 5.8 * delta
		boat_velocity *= exp(-1.25 * delta)
		boat_velocity = boat_velocity.limit_length(8.0)
		boat_speed = boat_velocity.dot(forward)
		var target_turn := steer * (0.35 + minf(absf(boat_speed) * 0.13, 0.75))
		turn_velocity = move_toward(turn_velocity, target_turn, delta * 2.6)
		player.rotation.y += turn_velocity * delta
		var next := player.position + boat_velocity * delta
		if _sea_blocked(next):
			boat_velocity *= -0.24
			turn_velocity *= 0.45
		else:
			player.position = next
		boat_visual.position.y = sin(sea_time * 2.5) * 0.055
		boat_visual.rotation.z = sin(sea_time * 1.8) * 0.018 - turn_velocity * 0.025
		boat_visual.rotation.x = sin(sea_time * 2.1) * 0.014 + clampf(boat_speed * 0.006, -0.04, 0.04)
		for i in range(waves.size()):
			waves[i].position.x += sin(sea_time * 1.3 + float(i)) * delta * 0.10
			waves[i].position.y = 0.092 + sin(sea_time * 2.0 + float(i) * 0.7) * 0.013
		for i in range(buoys.size()):
			buoys[i].position.y = sin(sea_time * 2.4 + float(i) * 1.7) * 0.075
		var behind := Vector3.BACK.rotated(Vector3.UP, player.rotation.y)
		for i in range(wake.size()):
			wake[i].visible = boat_velocity.length() > 0.8
			wake[i].position = player.position + behind * (1.6 + float(i) * 0.55) + Vector3(0, 0.11, 0)
			wake[i].rotation.y = player.rotation.y
		camera.global_position = camera.global_position.lerp(player.global_position + Vector3(0, 8, 11).rotated(Vector3.UP, player.rotation.y), minf(delta * 4.0, 1.0))
		camera.look_at(player.global_position)
	elif mode == Mode.FISHING:
		target = clampf(target + Input.get_axis("turn_left", "turn_right") * delta * 0.7, 0.0, 1.0)
		fishing_bar.value = target * 100.0
		if Input.is_action_pressed("cast"):
			progress += delta * (0.55 if absf(target - 0.5) < 0.12 else -0.25)
		else:
			progress -= delta * 0.08
		progress = clampf(progress, 0.0, 1.0)
		fishing_label.text = "CÂU CÁ / CANH VẠCH GIỮA\nA / D: di chuyển cần   GIỮ SPACE: kéo   ESC: thoát\nTiến độ: %d%%" % roundi(progress * 100.0)
		if progress >= 1.0:
			fish += 1
			_close_fishing()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if mode == Mode.FISHING:
		if event.keycode == KEY_ESCAPE:
			_close_fishing()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_TAB:
		if mode == Mode.RESTAURANT:
			_build_sea()
		else:
			_build_restaurant()
	elif event.keycode == KEY_F1 and OS.is_debug_build() and mode == Mode.RESTAURANT:
		fish += FISH_CATALOG.fish.size()
	elif event.keycode == KEY_E and mode == Mode.RESTAURANT:
		if player.position.distance_to(Vector3(5, 0, -2.9)) < 3.0 and fish > 0:
			fish -= 1
			served += 1
			gold += 50
	elif event.keycode == KEY_SPACE and mode == Mode.SEA:
		for spot in [Vector3(5, 0, -12), Vector3(-10, 0, -22), Vector3(15, 0, -30)]:
			if player.position.distance_to(spot) < 5.0:
				mode = Mode.FISHING
				boat_speed = 0.0
				boat_velocity = Vector3.ZERO
				turn_velocity = 0.0
				progress = 0.0
				target = 0.5
				fishing_panel.visible = true
				break
	_update_hud()
	get_viewport().set_input_as_handled()

func _close_fishing() -> void:
	fishing_panel.visible = false
	mode = Mode.SEA
	boat_speed = 0.0
	boat_velocity = Vector3.ZERO
	turn_velocity = 0.0
	_update_hud()

func _update_hud() -> void:
	if mode == Mode.RESTAURANT:
		hud.text = "QUÁN XÓM ĐÈN  |  Cá: %d  Vàng: %d  Đã phục vụ: %d\nWASD: đi  •  E gần bếp: nấu & phục vụ  •  F1: thêm cá (debug)  •  TAB: ra biển" % [fish, gold, served]
	else:
		hud.text = "BIỂN ĐÊM  |  Cá: %d  Vàng: %d\nW/S: ga  •  A/D: lái  •  SPACE gần đốm sáng: câu cá  •  TAB: về quán" % [fish, gold]
