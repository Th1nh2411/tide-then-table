extends Node3D
## Isolated low-poly art study. Run with F6; no game state or saves.

var _rin: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _elapsed: float = 0.0
var _capture: bool = false

func mat(hex: String, metal: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.roughness = 0.85
	material.metallic = metal
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

func box(parent: Node3D, pos: Vector3, size: Vector3, color: String, metal: float = 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat(color, metal)
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
	mesh.material_override = mat(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func text3d(words: String, pos: Vector3, size: int, color: String) -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = size
	label.pixel_size = 0.008
	label.modulate = Color(color)
	label.outline_size = 0
	label.no_depth_test = false
	add_child(label)
	label.position = pos

func stool(pos: Vector3, color: String) -> void:
	box(self, pos + Vector3(0, 0.48, 0), Vector3(0.54, 0.12, 0.54), color)
	for x: float in [-0.19, 0.19]:
		for z: float in [-0.19, 0.19]:
			box(self, pos + Vector3(x, 0.23, z), Vector3(0.08, 0.46, 0.08), color)

func table(pos: Vector3) -> void:
	box(self, pos + Vector3(0, 0.83, 0), Vector3(1.35, 0.09, 1.05), "9ba8ad", 0.5)
	for x: float in [-0.52, 0.52]:
		for z: float in [-0.38, 0.38]:
			box(self, pos + Vector3(x, 0.4, z), Vector3(0.055, 0.8, 0.055), "667780", 0.5)
	cylinder(self, pos + Vector3(-0.23, 0.9, 0.06), 0.22, 0.045, "e8d9b7", 12)
	for i: int in range(3):
		var food := box(self, pos + Vector3(-0.3 + i * 0.07, 0.94, 0.06), Vector3(0.055, 0.04, 0.22), "c97649")
		food.rotation.y = 0.4
	cylinder(self, pos + Vector3(0.38, 1.0, -0.27), 0.055, 0.27, "9a3b35")
	box(self, pos + Vector3(0.18, 0.96, -0.27), Vector3(0.19, 0.17, 0.14), "d7bd87")
	for i: int in range(4):
		box(self, pos + Vector3(0.12 + i * 0.035, 1.1, -0.27), Vector3(0.015, 0.26, 0.015), "685448")

func make_rin(pos: Vector3) -> void:
	_rin = Node3D.new()
	add_child(_rin)
	_rin.position = pos
	_rin.rotation.y = -0.2
	box(_rin, Vector3(0, 1.12, 0), Vector3(0.46, 0.65, 0.27), "e9dfc5")
	box(_rin, Vector3(0, 0.73, 0), Vector3(0.47, 0.22, 0.29), "26313c")
	for x: float in [-0.13, 0.13]:
		box(_rin, Vector3(x, 0.43, 0), Vector3(0.15, 0.45, 0.17), "b78160")
		box(_rin, Vector3(x, 0.16, 0.065), Vector3(0.2, 0.09, 0.31), "303640")
	box(_rin, Vector3(0, 1.49, 0), Vector3(0.17, 0.15, 0.18), "b78160")
	box(_rin, Vector3(0, 1.73, 0), Vector3(0.42, 0.43, 0.36), "bd8c69")
	box(_rin, Vector3(0, 1.96, -0.02), Vector3(0.46, 0.15, 0.39), "202630")
	for i: int in range(5):
		var hair := box(_rin, Vector3(-0.2 + i * 0.095, 1.98 + (i % 2) * 0.055, 0.08), Vector3(0.13, 0.16, 0.28), "202630")
		hair.rotation.z = -0.3 + i * 0.13
	for x: float in [-0.115, 0.115]:
		box(_rin, Vector3(x, 1.76, 0.19), Vector3(0.19, 0.13, 0.025), "202630")
		box(_rin, Vector3(x, 1.76, 0.207), Vector3(0.13, 0.075, 0.012), "836e59")
	box(_rin, Vector3(0, 1.78, 0.21), Vector3(0.08, 0.025, 0.025), "202630")
	box(_rin, Vector3(0, 1.68, 0.2), Vector3(0.065, 0.08, 0.06), "b78160")
	box(_rin, Vector3(0.08, 1.59, 0.19), Vector3(0.08, 0.016, 0.012), "775345")
	box(_rin, Vector3(-0.225, 1.7, 0.01), Vector3(0.035, 0.065, 0.04), "c5c9bd")
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		_rin.add_child(arm)
		arm.position = Vector3(side * 0.3, 1.38, 0)
		arm.rotation.z = side * 0.08
		box(arm, Vector3(0, -0.28, 0), Vector3(0.145, 0.59, 0.16), "b78160")
		if side == -1:
			_left_arm = arm
		else:
			_right_arm = arm
	box(_rin, Vector3(0, 1.3, 0.15), Vector3(0.02, 0.2, 0.015), "303640")
	box(_rin, Vector3(0.025, 1.2, 0.16), Vector3(0.045, 0.045, 0.02), "a9b1ac")

func make_cart() -> void:
	var origin := Vector3(2.0, 0, -0.6)
	box(self, origin + Vector3(0, 0.65, 0), Vector3(2.1, 0.86, 0.8), "6e858b", 0.45)
	box(self, origin + Vector3(0, 1.12, 0), Vector3(2.3, 0.12, 0.98), "b2bdb4", 0.5)
	box(self, origin + Vector3(0, 0.7, 0.415), Vector3(1.75, 0.57, 0.025), "91a4a3", 0.3)
	for x: float in [-0.83, 0.83]:
		var wheel := cylinder(self, origin + Vector3(x, 0.22, 0.25), 0.19, 0.1, "26313c")
		wheel.rotation.x = PI / 2
	for x: float in [-0.98, 0.3]:
		for z: float in [-0.3, 0.3]:
			box(self, origin + Vector3(x, 1.57, z), Vector3(0.045, 0.84, 0.045), "b2bdb4", 0.4)
	box(self, origin + Vector3(-0.34, 2.0, 0), Vector3(1.45, 0.1, 0.82), "9a3b35")
	box(self, origin + Vector3(-0.34, 1.52, -0.32), Vector3(1.24, 0.52, 0.025), "466c72")
	for i: int in range(3):
		cylinder(self, origin + Vector3(-0.74 + i * 0.36, 1.23, 0.05), 0.14, 0.09, "dfd4ae")
	cylinder(self, origin + Vector3(0.72, 1.35, 0), 0.23, 0.38, "46545b")
	cylinder(self, origin + Vector3(0.72, 1.56, 0), 0.25, 0.055, "a8b4ac")
	box(self, origin + Vector3(0.72, 1.62, 0), Vector3(0.13, 0.07, 0.08), "303640")
	# Charcoal grill, with hard-edged ember blocks.
	box(self, Vector3(1.85, 0.44, 0.65), Vector3(1.1, 0.35, 0.57), "44434a")
	for i: int in range(6):
		box(self, Vector3(1.42 + i * 0.17, 0.63, 0.65), Vector3(0.1, 0.04, 0.45), "b2b0a0", 0.5)
		box(self, Vector3(1.42 + i * 0.17, 0.61, 0.65), Vector3(0.08, 0.05, 0.18), "d27b47")
	for x: float in [1.45, 2.25]:
		box(self, Vector3(x, 0.16, 0.65), Vector3(0.07, 0.32, 0.07), "303640")

func _ready() -> void:
	_capture = OS.get_cmdline_user_args().has("--capture-art")
	RenderingServer.set_default_clear_color(Color("202c38"))
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202c38")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("9aa8b4")
	settings.ambient_light_energy = 0.65
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_color = Color("ffd39b")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	box(self, Vector3(0, -0.17, 0), Vector3(10, 0.3, 7), "525f64")
	for x: int in range(-10, 10):
		for z: int in range(-5, 6):
			var color: String = "8e8c79" if (x + z) % 3 == 0 else "797e73"
			box(self, Vector3(x * 0.5 + 0.25, 0, z * 0.5), Vector3(0.48, 0.055, 0.48), color)
	box(self, Vector3(0, -0.035, 3.1), Vector3(10, 0.13, 0.25), "b4ab90")
	box(self, Vector3(0, -0.13, 3.7), Vector3(10, 0.08, 1), "35434d")
	for x: int in range(-4, 5, 2):
		box(self, Vector3(x, -0.08, 3.9), Vector3(0.9, 0.015, 0.06), "c5a968")
	box(self, Vector3(0, 1.65, -2.65), Vector3(10, 3.3, 0.22), "b6a183")
	box(self, Vector3(0, 0.38, -2.5), Vector3(10, 0.7, 0.12), "6c817a")
	box(self, Vector3(-2.8, 1.2, -2.48), Vector3(2.2, 2.3, 0.12), "46565b")
	for i: int in range(15):
		box(self, Vector3(-2.8, 0.22 + i * 0.14, -2.39), Vector3(2.15, 0.025, 0.025), "697575")
	box(self, Vector3(2.5, 1.2, -2.48), Vector3(2.5, 2.3, 0.12), "566c66")
	box(self, Vector3(0, 2.83, -2.42), Vector3(5.4, 0.64, 0.17), "763a36")
	text3d("HẢI SẢN XÓM ĐÈN", Vector3(0, 2.83, -2.31), 48, "f0d39b")
	for i: int in range(20):
		var awning := box(self, Vector3(-4.75 + i * 0.5, 2.48, -1.98), Vector3(0.49, 0.07, 1.05), "456c65" if i % 2 == 0 else "c6b89a")
		awning.rotation.x = 0.13
		box(self, Vector3(-4.75 + i * 0.5, 2.34, -1.47), Vector3(0.49, 0.24, 0.05), "456c65" if i % 2 == 0 else "c6b89a")
	table(Vector3(-2.5, 0, 0))
	stool(Vector3(-3.35, 0, 0.3), "355d77")
	stool(Vector3(-1.65, 0, 0.45), "9a4540")
	stool(Vector3(-2.5, 0, -0.85), "355d77")
	table(Vector3(-3.1, 0, 1.8))
	stool(Vector3(-2.2, 0, 1.8), "355d77")
	stool(Vector3(-3.9, 0, 1.8), "9a4540")
	make_cart()
	make_rin(Vector3(0, 0, 0.8))
	box(self, Vector3(3.8, 0.35, 0.25), Vector3(0.8, 0.7, 0.64), "bdd0c3")
	box(self, Vector3(3.8, 0.73, 0.25), Vector3(0.85, 0.08, 0.69), "ded5b6")
	# Menu board.
	box(self, Vector3(0.25, 0.77, 2.2), Vector3(0.95, 1.15, 0.09), "a27d4c")
	box(self, Vector3(0.25, 0.8, 2.26), Vector3(0.82, 0.98, 0.025), "273e43")
	text3d("HÔM NAY\n────────\nMỰC NƯỚNG\nỐC HƯƠNG\nTÔM LUỘC", Vector3(0.25, 0.8, 2.29), 13, "e5cf9d")
	for x: float in [-0.08, 0.58]:
		box(self, Vector3(x, 0.2, 2.2), Vector3(0.065, 0.4, 0.12), "a27d4c")
	# Warm practical lamp over the cart.
	box(self, Vector3(2, 2.26, -1.36), Vector3(1.15, 0.06, 0.1), "f7e5ae")
	var lamp := OmniLight3D.new()
	add_child(lamp)
	lamp.position = Vector3(2, 2.1, -0.6)
	lamp.light_color = Color("ffc27a")
	lamp.light_energy = 1.2
	lamp.omni_range = 4.0
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	camera.position = Vector3(8, 8, 12)
	camera.look_at(Vector3(0, 0.9, 0))
	camera.current = true
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	ui.add_child(title)
	title.position = Vector2(22, 14)
	title.text = "XÓM ĐÈN / THỬ PHONG CÁCH 3D"
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color("efdbb6")
	var subtitle := Label.new()
	ui.add_child(subtitle)
	subtitle.position = Vector2(23, 39)
	subtitle.text = "LOW-POLY • KHỐI RỜI • ÁNH ĐÈN CHIỀU"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.modulate = Color("aebbb3")
	if _capture:
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/shots/psx_quan_preview.png")
		get_tree().quit()

func _process(delta: float) -> void:
	_elapsed += delta
	if not is_instance_valid(_rin):
		return
	var stepped: float = floorf(_elapsed * 7.0) / 7.0
	_rin.position.y = sin(stepped * 2.0) * 0.015
	_left_arm.rotation.x = sin(stepped * 2.0) * 0.035
	_right_arm.rotation.x = -sin(stepped * 2.0) * 0.035
