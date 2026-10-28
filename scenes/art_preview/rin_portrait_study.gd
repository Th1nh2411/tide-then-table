extends Node3D
## Isolated imported Rin study. F6; 1/2/3 animations, arrows rotate, 4 close-up.

var _model: Node3D
var _player: AnimationPlayer
var _camera: Camera3D
var _close: bool = true

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
	_model = load("res://assets/models/characters/rin_portrait_study.glb").instantiate()
	add_child(_model)
	# glTF converts Blender front (-Y) to Godot front (+Z).
	_model.rotation.y = 0.7
	for node: Node in _model.find_children("*", "AnimationPlayer", true, false):
		_player = node as AnimationPlayer
		break
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
	label.text = "RIN • PORTRAIT → 3D\n\n1: đứng  2: đi  3: bưng\n← →: xoay  4: cận mặt"
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(16, 16)
	ui.add_child(label)
	var note := Label.new()
	note.text = "PORTRAIT ĐÃ DUYỆT"
	note.add_theme_font_size_override("font_size", 10)
	note.position = Vector2(22, 265)
	ui.add_child(note)
	_play("Idle")
	if OS.get_cmdline_user_args().has("--capture-rin"):
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/characters/rin_portrait_study/godot_preview.png")
		print("PASS imported Rin, animations: ", _player.get_animation_list() if _player else PackedStringArray())
		get_tree().quit()

func _update_camera() -> void:
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
		KEY_4:
			_close = not _close
			_update_camera()
