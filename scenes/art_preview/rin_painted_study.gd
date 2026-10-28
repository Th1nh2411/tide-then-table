extends Node3D
## Painted Rin comparison. B switches the earlier mesh study; 5 shows game scale.

var _model: Node3D
var _player: AnimationPlayer
var _camera: Camera3D
var _close: bool = true
var _painted: bool = true
var _game_scale: bool = false
var _variant_label: Label

func _ready() -> void:
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
	_load_model()
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_update_camera()
	var ground := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.55
	disc.height = 0.025
	ground.mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("485c60")
	ground.material_override = material
	add_child(ground)
	ground.position.y = -0.025
	var ui := CanvasLayer.new()
	add_child(ui)
	var reference := TextureRect.new()
	reference.texture = load("res://assets/sprites/portraits/rin/base.png")
	reference.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reference.position = Vector2(16, 95)
	reference.size = Vector2(160, 160)
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ui.add_child(reference)
	var label := Label.new()
	label.text = "RIN • MESH + TEXTURE\nB: đổi bản  1/2/3: đứng/đi/bưng\n← →: xoay  4: cận  5: cỡ trong quán"
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(16, 16)
	ui.add_child(label)
	var note := Label.new()
	note.text = "PORTRAIT ĐÃ DUYỆT"
	note.add_theme_font_size_override("font_size", 10)
	note.position = Vector2(22, 265)
	ui.add_child(note)
	_variant_label = Label.new()
	_variant_label.position = Vector2(22, 285)
	_variant_label.add_theme_font_size_override("font_size", 11)
	_variant_label.text = "ĐANG XEM: TEXTURE"
	ui.add_child(_variant_label)
	_play("Idle")
	if OS.get_cmdline_user_args().has("--capture-painted"):
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/characters/rin_painted/godot_preview.png")
		print("PASS imported Rin, animations: ", _player.get_animation_list() if _player else PackedStringArray())
		get_tree().quit()

func _load_model() -> void:
	var rotation_y: float = _model.rotation.y if is_instance_valid(_model) else 0.7
	if is_instance_valid(_model):
		remove_child(_model)
		_model.queue_free()
	var path: String = "res://assets/models/characters/rin_painted/rin_painted.glb" if _painted else "res://assets/models/characters/rin_portrait_study.glb"
	_model = load(path).instantiate()
	add_child(_model)
	_model.rotation.y = rotation_y
	_player = null
	for node: Node in _model.find_children("*", "AnimationPlayer", true, false):
		_player = node as AnimationPlayer
		break
	_play("Idle")

func _update_camera() -> void:
	if _game_scale:
		_camera.size = 14.0
		_camera.position = Vector3(4.5, 12, 15)
		_camera.look_at(Vector3(0, 0.7, 0))
		_camera.h_offset = 0
		return
	_camera.size = 1.05 if _close else 2.1
	_camera.position = Vector3(0, 1.65 if _close else 1.4, 4)
	_camera.look_at(Vector3(0, 1.36 if _close else 0.94, 0))
	# Leave room for the portrait panel without skewing the character.
	_camera.h_offset = -0.28

func _play(clip: String) -> void:
	if not _player:
		return
	for name: String in _player.get_animation_list():
		if name == clip or name.ends_with("/" + clip):
			_player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
			_player.play(name)
			return

func _process(delta: float) -> void:
	if _model:
		var direction: float = float(Input.is_physical_key_pressed(KEY_LEFT)) - float(Input.is_physical_key_pressed(KEY_RIGHT))
		_model.rotation.y += direction * delta * 1.6

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: _play("Idle")
		KEY_2: _play("Walk")
		KEY_3: _play("Carry")
		KEY_B:
			_painted = not _painted
			_load_model()
			_variant_label.text = "ĐANG XEM: TEXTURE" if _painted else "ĐANG XEM: MESH CŨ"
		KEY_5:
			_game_scale = not _game_scale
			_update_camera()
		KEY_4:
			_game_scale = false
			_close = not _close
			_update_camera()
