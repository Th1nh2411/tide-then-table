extends Node3D
## Actual Hunyuan shape output; static geometry, no textures or animation rig.

var _pivot: Node3D
var _camera: Camera3D
var _close: bool = false
var _reduced: bool = true
var _model: Node3D
var _label: Label

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263440")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c2c8cc")
	settings.ambient_light_energy = 0.6
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-35, -35, 0)
	light.light_color = Color("ffdfb6")
	light.light_energy = 1.0
	_pivot = Node3D.new()
	add_child(_pivot)
	_load_model()
	_pivot.rotation.y = 0.6
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_update_camera()
	var ui := CanvasLayer.new()
	add_child(ui)
	_label = Label.new()
	_update_label()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 20)
	ui.add_child(_label)
	var reference := TextureRect.new()
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference.texture = load("res://assets/models/characters/rin_hunyuan_shape/input_front.png")
	reference.position = Vector2(24, 145)
	reference.size = Vector2(230, 428)
	ui.add_child(reference)
	var note := Label.new()
	note.text = "ẢNH ĐẦU VÀO"
	note.position = Vector2(24, 585)
	note.add_theme_font_size_override("font_size", 18)
	ui.add_child(note)
	if OS.get_cmdline_user_args().has("--capture-hunyuan"):
		await get_tree().create_timer(0.3).timeout
		for view_name: String in ["front", "side", "back", "three_quarter"]:
			_pivot.rotation.y = {"front": 0.0, "side": PI / 2.0, "back": PI, "three_quarter": 0.6}[view_name]
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/hunyuan21_trial/" + view_name + ".png")
		_close = true
		_update_camera()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/hunyuan21_trial/close.png")
		print("PASS actual Hunyuan mesh import and review views")
		get_tree().quit()

func _load_model() -> void:
	if is_instance_valid(_model):
		_pivot.remove_child(_model)
		_model.queue_free()
	var path: String = "res://assets/models/characters/rin_hunyuan_shape/rin_hunyuan_3k_lit.glb" if _reduced else "res://assets/models/characters/rin_hunyuan_shape/rin_hunyuan_shape.glb"
	var model: Node3D = load(path).instantiate()
	_model = model
	_pivot.add_child(model)
	var bounds := AABB()
	var found := false
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		# Tencent's shape export omits NORMAL. Rebuild display normals for lit review;
		# original downloaded GLBs stay untouched. This is neutral clay, not texture generation.
		var rebuilt := ArrayMesh.new()
		for surface: int in mesh.mesh.get_surface_count():
			var tool := SurfaceTool.new()
			tool.create_from(mesh.mesh, surface)
			tool.generate_normals()
			tool.commit(rebuilt)
		mesh.mesh = rebuilt
		var clay := StandardMaterial3D.new()
		clay.albedo_color = Color("b7ada1")
		clay.roughness = 0.9
		clay.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = clay
		var box := mesh.global_transform * mesh.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
	assert(found and bounds.size.y > 0.0, "Hunyuan output contains no usable mesh")
	var scale_factor := 1.84 / bounds.size.y
	model.scale = Vector3.ONE * scale_factor
	model.position = -bounds.get_center() * scale_factor + Vector3(0, 0.92, 0)

func _update_label() -> void:
	_label.text = "RIN • HUNYUAN3D 2.1\n" + ("3.000 tam giác" if _reduced else "78.972 tam giác gốc") + " • chưa texture / rig\n← →: xoay   4: cận   B: đổi bản"

func _update_camera() -> void:
	_camera.size = 1.05 if _close else 2.1
	_camera.position = Vector3(0, 1.65 if _close else 1.35, 4)
	_camera.look_at(Vector3(0, 1.36 if _close else 0.94, 0))
	_camera.h_offset = -0.28

func _process(delta: float) -> void:
	if _pivot:
		_pivot.rotation.y += (float(Input.is_physical_key_pressed(KEY_LEFT)) - float(Input.is_physical_key_pressed(KEY_RIGHT))) * delta * 1.6

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_4:
		_close = not _close
		_update_camera()
	if key.physical_keycode == KEY_B:
		_reduced = not _reduced
		_load_model()
		_update_label()
