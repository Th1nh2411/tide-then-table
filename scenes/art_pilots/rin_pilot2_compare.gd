extends Node3D
## Equal camera, lighting and animation time for original and edited pilot2.
var _models: Array[Node3D] = []
var _players: Array[AnimationPlayer] = []
var _clock := 0.0
var _clip := "CharacterArmature|Idle"
var _paused := false

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280,720)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263440")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c2c8cc")
	settings.ambient_light_energy = 0.7
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.light_color = Color("ffdfb6")
	light.rotation_degrees = Vector3(-35,-30,0)
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.7
	camera.position = Vector3(0,1.3,5)
	add_child(camera)
	camera.look_at(Vector3(0,1.0,0))
	camera.current = true
	var paths := ["res://assets/models/ready/rin/rin_pilot2.glb", "res://assets/models/ready/rin/rin_pilot.glb"]
	for i: int in 2:
		var model: Node3D = load(paths[i]).instantiate()
		add_child(model)
		model.position.x = -0.7 if i == 0 else 0.7
		_models.append(model)
		_players.append(model.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer)
		var label := Label3D.new()
		label.text = "RIN_PILOT2 GỐC" if i == 0 else "ĐỔI MÀU + TÓC + KÍNH"
		label.position = Vector3(model.position.x,2.03,0)
		label.font_size = 32
		label.pixel_size = 0.002
		add_child(label)
	var ui := CanvasLayer.new()
	add_child(ui)
	var help := Label.new()
	help.text = "Cùng camera, ánh sáng và thời điểm animation\n1: đứng   2: đi   Space: dừng   ←/→: xoay cả hai"
	help.position = Vector2(20,20)
	ui.add_child(help)
	_sample(0.0)
	if OS.get_cmdline_user_args().has("--capture-rin-compare"):
		set_process(false)
		for view: String in ["front","quarter"]:
			for model in _models:
				model.rotation.y = 0.0 if view == "front" else .6
			_sample(.25)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/rin2_exact/compare_"+view+".png")
		print("PASS original/edited pilot2 equal-pose comparison captured")
		get_tree().quit()

func _sample(time: float) -> void:
	for player in _players:
		player.play(_clip)
		player.seek(fmod(time,maxf(.001,player.get_animation(_clip).length)),true)
		player.pause()

func _process(delta: float) -> void:
	if not _paused:
		_clock += delta
	_sample(_clock)
	var turn := float(Input.is_physical_key_pressed(KEY_LEFT))-float(Input.is_physical_key_pressed(KEY_RIGHT))
	for model in _models:
		model.rotation.y += turn*delta

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: _clip = "CharacterArmature|Idle"
		KEY_2: _clip = "CharacterArmature|Walk"
		KEY_SPACE: _paused = not _paused
