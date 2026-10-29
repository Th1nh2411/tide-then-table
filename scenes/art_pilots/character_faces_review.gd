extends Control
const IDS := ["bao","vy","vy_sau","co_nam","ong_tam","guest_1","guest_2","guest_3","guest_rich","guest_regular","staff","cat"]
const HEIGHTS := [1.72,1.60,1.60,1.58,1.62,1.70,1.58,1.68,1.72,1.68,1.68,.58]
var _models: Array[Node3D] = []
var _cameras: Array[Camera3D] = []
var _players: Array[AnimationPlayer] = []
var _walking := false
var _clock := 0.0
func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280,900)
	var background := ColorRect.new()
	background.color = Color("263440")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var help := Label.new()
	help.position = Vector2(16,12)
	help.text = "NHÂN VẬT • MẮT, MÀU VÀ DÁNG ĐI\n1: mặt trước   2: góc nghiêng   3: toàn thân   4/5: đi trước/nghiêng   6: nghiêng ngược"
	help.add_theme_font_size_override("font_size",18)
	add_child(help)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(0,65)
	grid.add_theme_constant_override("h_separation",0)
	grid.add_theme_constant_override("v_separation",0)
	add_child(grid)
	for i: int in IDS.size():
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(320,275)
		grid.add_child(cell)
		var label := Label.new()
		label.text = IDS[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(label)
		var container := SubViewportContainer.new()
		container.custom_minimum_size = Vector2(320,245)
		container.stretch = true
		cell.add_child(container)
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(320,245)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		container.add_child(viewport)
		var scene := Node3D.new()
		viewport.add_child(scene)
		var environment := WorldEnvironment.new()
		var settings := Environment.new()
		settings.background_mode = Environment.BG_COLOR
		settings.background_color = Color("263440")
		settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		settings.ambient_light_color = Color("c2c8cc")
		settings.ambient_light_energy = .7
		environment.environment = settings
		scene.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-30,-30,0)
		light.light_energy = .9
		scene.add_child(light)
		var model: Node3D = load("res://assets/models/ready/%s/%s.glb" % [IDS[i],IDS[i]]).instantiate()
		scene.add_child(model)
		_models.append(model)
		var animations := model.find_children("*","AnimationPlayer",true,false)
		if not animations.is_empty():
			var animation := animations[0] as AnimationPlayer
			_players.append(animation)
			animation.play("Idle")
			animation.advance(0)
			animation.pause()
		else:
			_players.append(null)
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.current = true
		scene.add_child(camera)
		_cameras.append(camera)
	_view(1)
	if OS.get_cmdline_user_args().has("--capture-character-walk"):
		set_process(false)
		var tag := "after"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--walk-review-tag="):
				tag = arg.trim_prefix("--walk-review-tag=")
		for mode: int in [4,5]:
			_view(mode)
			for phase: float in [0.0,0.25,0.5,0.75]:
				_sample_walk(phase)
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://build/character_walk_narrow/%s_%d_%02d.png" % [tag,mode,int(phase*100)])
		print("PASS character Walk front/quarter review captured")
		get_tree().quit()
	if OS.get_cmdline_user_args().has("--capture-character-faces"):
		var tag := "after"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--review-tag="):
				tag = arg.trim_prefix("--review-tag=")
		for mode: int in [1,2,3,6]:
			_view(mode)
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/character_face_refine/%s_%d.png" % [tag,mode])
		print("PASS character faces and palette review captured")
		get_tree().quit()
func _view(mode: int) -> void:
	_walking = mode in [4,5]
	for i: int in _models.size():
		_models[i].rotation.y = -.55 if mode == 6 else (.55 if mode in [2,5] else 0.0)
		var focus: float = float(HEIGHTS[i])*.9 if IDS[i] != "cat" else .445
		_cameras[i].size = .37 if IDS[i] != "cat" else .35
		if mode in [3,4,5]:
			focus = HEIGHTS[i]*.5
			_cameras[i].size = HEIGHTS[i]*1.15
		_cameras[i].position = Vector3(0,focus,2)
		_cameras[i].look_at(Vector3(0,focus,0))
		if not _walking and _players[i]:
			_players[i].play("Idle")
			_players[i].seek(0.0,true)
			_players[i].pause()

func _sample_walk(time: float) -> void:
	for player in _players:
		if not player:
			continue
		player.play("Walk")
		player.seek(fmod(time,player.get_animation("Walk").length),true)
		player.pause()

func _process(delta: float) -> void:
	if _walking:
		_clock += delta
		_sample_walk(_clock)
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6]:
		_view(key.physical_keycode-KEY_1+1)
