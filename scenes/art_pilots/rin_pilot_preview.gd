extends Node3D

var _pivot: Node3D
var _visual: RinPilotVisual
var _camera: Camera3D
var _close := false
var _fishing := false
var _rod: BoneAttachment3D

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
	_visual = load("res://scenes/art_pilots/rin_pilot.tscn").instantiate() as RinPilotVisual
	_pivot.add_child(_visual)
	_rod = BoneAttachment3D.new()
	_rod.bone_name = "Hand.L" if _visual.skeleton.find_bone("Hand.L") >= 0 else "Wrist.L"
	_visual.skeleton.add_child(_rod)
	var rod := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3(0.035, 0.035, 1.6)
	rod.mesh = shape
	var rod_material := StandardMaterial3D.new()
	rod_material.albedo_color = Color("884b2b")
	rod.material_override = rod_material
	_rod.add_child(rod)
	# BoneAttachment owns its transform; put the grip offset on its child mesh.
	var rest_correction := _visual.hand_rest_basis("L").inverse()
	var skeleton_scale := _visual.skeleton.global_basis.get_scale()
	rod.basis = rest_correction * Basis(Vector3.RIGHT, -1.2) * Basis.from_scale(Vector3.ONE / skeleton_scale)
	rod.position = rest_correction * (Basis(Vector3.RIGHT, -1.2) * Vector3(0, 0, 0.7)) / skeleton_scale
	_rod.visible = false
	_pivot.rotation.y = 0.6
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_update_camera()
	var ui := CanvasLayer.new()
	add_child(ui)
	var label := Label.new()
	label.text = "RIN • PILOT 2\nRig và Walk gốc • màu và tóc Rin\n1/2/3: đứng/đi/bưng   5: ném cần\n← →: xoay   4: cận"
	label.position = Vector2(24, 20)
	label.add_theme_font_size_override("font_size", 20)
	ui.add_child(label)
	var reference := TextureRect.new()
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference.texture = load("res://assets/sprites/portraits/rin/base.png")
	reference.position = Vector2(24, 160)
	reference.size = Vector2(256, 256)
	reference.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ui.add_child(reference)
	if OS.get_cmdline_user_args().has("--capture-rin-pilot"):
		await get_tree().create_timer(0.3).timeout
		_visual.sample_motion("Idle", 0.0)
		for view_name: String in ["front", "side", "back", "three_quarter"]:
			_pivot.rotation.y = {"front": 0.0, "side": PI / 2.0, "back": PI, "three_quarter": 0.6}[view_name]
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/art_pilots/rin/" + view_name + ".png")
		for clip: String in ["Walk", "Carry"]:
			_visual.sample_motion(clip, 0.25)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/art_pilots/rin/" + clip.to_lower() + ".png")
		_visual.sample_motion("Idle", 0.0)
		_fishing = true
		_rod.visible = true
		_update_camera()
		for time: float in [0.0, 0.45, 0.75, 1.2]:
			_visual.sample_motion("Cast", time)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/rin_cast/cast_%02d.png" % int(time * 100))
		_fishing = false
		_rod.visible = false
		_visual.sample_motion("Idle", 0.0)
		_close = true
		_update_camera()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/art_pilots/rin/close.png")
		print("PASS Rin pilot colour/rig preview")
		get_tree().quit()

func _update_camera() -> void:
	_camera.size = 1.05 if _close else 2.1
	_camera.position = Vector3(0, 1.65 if _close else 1.35, 4)
	_camera.look_at(Vector3(0, 1.36 if _close else 0.94, 0))
	_camera.h_offset = -0.28
	if _fishing:
		_camera.size = 3.8
		_camera.position = Vector3(0, 1.8, 4)
		_camera.look_at(Vector3(0, 1.2, 0))

func _process(delta: float) -> void:
	if _pivot:
		_pivot.rotation.y += (float(Input.is_physical_key_pressed(KEY_LEFT)) - float(Input.is_physical_key_pressed(KEY_RIGHT))) * delta * 1.6

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.physical_keycode in [KEY_1, KEY_2, KEY_3, KEY_5]:
		_fishing = key.physical_keycode == KEY_5
		_rod.visible = _fishing
		_close = false
		_update_camera()
	match key.physical_keycode:
		KEY_1: _visual.set_motion("Idle")
		KEY_2: _visual.set_motion("Walk")
		KEY_3: _visual.set_motion("Carry")
		KEY_5:
			_visual.sample_motion("Cast", 0.0)
			_visual.animation.play("Cast")
		KEY_4:
			_close = not _close
			_update_camera()
