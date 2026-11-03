extends Node3D
## Visual review of the uncanny toolkit (not a test): plays each effect on a
## PSX character one by one, Space = next. With `-- --shots` it saves a PNG
## of each into build/shot/ and quits (run windowed: --resolution 1280x720).

const SHOT_DIR := "res://build/shot/"
const STEPS: Array[String] = ["stare", "freeze", "choppy", "glitch_face", "wrong_walk", "dash",
	"appear_close", "wrong_night_face", "tu_points", "reflection"]

var camera := Camera3D.new()
var rig: PersonRig3D
var actor: UncannyActor3D
var label := Label.new()
var _index := -1
var _shots := false
var _extra: Array[Node] = []


func _ready() -> void:
	_shots = "--shots" in OS.get_cmdline_user_args()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("0d1416")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("8090a0")
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.5, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color("3a3630")
	ground.material_override = dirt
	add_child(ground)
	camera.fov = 72.0
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	label.position = Vector2(8, 6)
	label.add_theme_color_override("font_color", Color("f2d98a"))
	layer.add_child(label)
	_next()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_SPACE:
		_next()


func _next() -> void:
	_index += 1
	if _index >= STEPS.size():
		if _shots:
			get_tree().quit()
			return
		_index = 0
	await _play(STEPS[_index])
	if _shots:
		await get_tree().create_timer(0.3).timeout
		_shot(STEPS[_index])
		_next()


func _reset_stage(kind: String = "guest_3") -> void:
	for node in _extra:
		if is_instance_valid(node):
			node.queue_free()
	_extra.clear()
	if rig:
		rig.queue_free()
	rig = PersonRig3D.build(self, kind)
	rig.position = Vector3(0, 0, -1.8)
	actor = UncannyActor3D.attach(rig)
	camera.global_transform = Transform3D(Basis(), Vector3(0, 1.55, 0))
	camera.look_at(Vector3(0, 1.3, -1.8))


func _play(step: String) -> void:
	label.text = "%d/%d  %s  (Space: tiếp)" % [_index + 1, STEPS.size(), step]
	_reset_stage("drowned" if step == "appear_close" else "guest_3")
	match step:
		"stare":
			# Body turned 150° away from the camera; the head still finds it.
			rig.rotation.y = deg_to_rad(150.0)
			actor.stare_at(camera, 150.0, 0.0)
		"freeze":
			rig.set_walking(1.0, 0.0)
			await get_tree().create_timer(0.35).timeout
			actor.freeze()
		"choppy":
			rig.set_walking(1.0, 0.0)
			actor.choppy(7.0)
		"glitch_face":
			rig.rotation.y = PI * 0.1
			actor.glitch_face(true)
		"wrong_walk":
			UncannyMoves3D.wrong_walk(actor, rig.position + Vector3(1.5, 0, 0), 2.0, true)
		"dash":
			rig.position = Vector3(0, 0, -9)
			UncannyMoves3D.dash_to(actor, Vector3(0, 0, -1.6), 0.3, 0.3, 2.0)
			await get_tree().create_timer(0.75).timeout
		"appear_close":
			# The last step of the chain: beside Rin at 1.1 m, staring.
			var side := Vector3.FORWARD.rotated(Vector3.UP, 1.75) * 1.1
			rig.position = Vector3(side.x, 0, side.z)
			UncannyMoves3D.face_dir(rig, -side)
			actor.stare_at(camera, 150.0, 0.0)
			camera.look_at(Vector3(side.x, 1.45, side.z))
		"wrong_night_face":
			rig.visible = false
			for variant in 1:
				var face := WrongNightScare3D.show_face(self, _index % 3)
				_extra.append(face)
		"tu_points":
			rig.visible = false
			var tu := TuGhostScare3D.new()
			tu.gate = func() -> bool: return true
			tu.after_seconds = 0.0
			add_child(tu)
			_extra.append(tu)
			await get_tree().create_timer(0.1).timeout
			camera.rotate_y(PI)  # Rin turns round
		"reflection":
			rig.visible = false
			var water := UncannyReflection3D.spawn(self, 0.02)
			_extra.append(water)
			camera.global_transform = Transform3D(Basis(), Vector3(0, 1.55, 0))
			camera.rotation.x = deg_to_rad(-40.0)
	await get_tree().create_timer(0.6).timeout


func _shot(step: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(SHOT_DIR + "uncanny_%s.png" % step))
	print("shot ", step)
