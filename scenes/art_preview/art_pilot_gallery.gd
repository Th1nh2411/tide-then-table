extends Node3D
## Art review stage for the selected Hunyuan pilots; saves are disabled by the launch flag.

var _actor: PersonRig3D
var _camera: Camera3D
var _furniture: Node3D
var _boat: Node3D
var _clock := 0.0
var _view := 0
var _carry := false
var _raised := false
var _capture := false


func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_capture = OS.get_cmdline_user_args().has("--capture-art-pilots")
	var world := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263440")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c2c8cc")
	settings.ambient_light_energy = 0.65
	world.environment = settings
	add_child(world)
	var light := DirectionalLight3D.new()
	light.light_color = Color("ffdfb6")
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)
	light.rotation_degrees = Vector3(-45, -30, 0)
	_box(Vector3(0, -0.08, 0), Vector3(9.5, 0.15, 6), "687477")
	_box(Vector3(0, 1.35, -2.8), Vector3(9.5, 2.7, 0.12), "b6a183")
	var sign_text := Label3D.new()
	add_child(sign_text)
	sign_text.text = "HẢI SẢN XÓM ĐÈN"
	sign_text.position = Vector3(0, 2.25, -2.7)
	sign_text.font_size = 48
	sign_text.pixel_size = 0.008
	sign_text.modulate = Color("763a36")
	sign_text.outline_size = 0
	_actor = PersonRig3D.build(self, "rin")
	_actor.name = "PilotRin"
	_actor.position = Vector3(-2.1, 0, 0.45)
	_actor.rotation.y = 0.25
	_furniture = _instance("res://scenes/art_pilots/furniture_pilot.tscn")
	if _furniture:
		_furniture.position = Vector3(0, 0, -0.4)
	_boat = _instance("res://scenes/art_pilots/boat_pilot.tscn")
	if _boat:
		_boat.position = Vector3(2.85, 0, 0)
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_update_camera()
	var ui := CanvasLayer.new()
	add_child(ui)
	var heading := Label.new()
	heading.position = Vector2(22, 16)
	heading.text = "XÓM ĐÈN • ART PILOT\nWASD: đi Rin   1: đứng   2: bưng   3: giơ tay\n4/5/6: cận Rin/bàn ghế/thuyền   0: tổng   R: đặt lại"
	heading.add_theme_font_size_override("font_size", 18)
	ui.add_child(heading)
	var note := Label.new()
	note.text = "Rin, ghế, thuyền: Hunyuan • bàn giữ mẫu hiện tại khi chờ quota"
	note.position = Vector2(22, 682)
	note.add_theme_font_size_override("font_size", 16)
	ui.add_child(note)
	if _capture:
		await get_tree().create_timer(0.4).timeout
		await _shot("gallery")
		_view = 4
		_update_camera()
		await _shot("rin_idle")
		_actor.set_carrying(true)
		await get_tree().create_timer(0.2).timeout
		await _shot("rin_carry")
		_actor.set_carrying(false)
		_actor.set_raised(true)
		await get_tree().create_timer(0.2).timeout
		await _shot("rin_raised")
		_actor.set_raised(false)
		_view = 5
		_update_camera()
		await _shot("furniture")
		_view = 6
		_update_camera()
		await _shot("boat")
		print("PASS art pilot gallery capture")
		get_tree().quit()


func _instance(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		push_warning("Pilot still being prepared: " + path)
		return null
	var model: Node3D = load(path).instantiate()
	add_child(model)
	return model


func _box(position_: Vector3, size_: Vector3, color_: String) -> void:
	var instance := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size_
	instance.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color_)
	material.roughness = 0.9
	instance.material_override = material
	add_child(instance)
	instance.position = position_


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/art_pilots/" + label + ".png")


func _update_camera() -> void:
	var target := Vector3(0.3, 0.7, 0)
	_camera.size = 10.5
	_camera.position = Vector3(6.5, 5.5, 10)
	if _view == 4:
		target = _actor.position + Vector3(0, 0.96, 0)
		_camera.size = 2.25
		_camera.position = _actor.position + Vector3(0.5, 1.4, 4)
	elif _view == 5:
		target = Vector3(0, 0.45, -0.4)
		_camera.size = 4.5
		_camera.position = Vector3(3.0, 2.8, 4.0)
	elif _view == 6:
		target = Vector3(2.85, 0.4, 0)
		_camera.size = 3.8
		_camera.position = target + Vector3(2.4, 2.6, 3.2)
	_camera.look_at(target)


func _process(delta: float) -> void:
	_clock += delta
	if not is_instance_valid(_actor) or _capture:
		return
	var direction := Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		0,
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		_actor.position += direction * delta * 2.5
		_actor.position.x = clampf(_actor.position.x, -4.1, 4.1)
		_actor.position.z = clampf(_actor.position.z, -2.1, 2.5)
		_actor.rotation.y = atan2(direction.x, direction.z)
	_actor.set_walking(direction.length(), _clock)
	if _view == 4:
		_update_camera()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_0, KEY_4, KEY_5, KEY_6:
			_view = {KEY_0: 0, KEY_4: 4, KEY_5: 5, KEY_6: 6}[key.physical_keycode]
			_update_camera()
		KEY_1:
			_carry = false
			_raised = false
			_actor.set_carrying(false)
			_actor.set_raised(false)
		KEY_2:
			_carry = not _carry
			_actor.set_carrying(_carry)
		KEY_3:
			_raised = not _raised
			_actor.set_raised(_raised)
		KEY_R:
			_actor.position = Vector3(-2.1, 0, 0.45)
			_actor.rotation.y = 0.25
			_update_camera()
