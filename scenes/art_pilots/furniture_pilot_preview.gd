extends Node3D
## Review-only stage: actual Hunyuan stool plus existing pending table visual.

var _camera: Camera3D
var _set: Node3D
var _single: Node3D
var _label: Label

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263440")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c2c8cc")
	settings.ambient_light_energy = 0.6
	var environment := WorldEnvironment.new()
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-42, -30, 0)
	sun.light_color = Color("ffdfb6")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8, 8)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("69766e")
	floor.material_override = floor_material
	floor.position.y = -0.005
	add_child(floor)
	_set = load("res://scenes/art_pilots/furniture_pilot.tscn").instantiate()
	add_child(_set)
	_single = load("res://assets/models/ready/stool/stool.glb").instantiate()
	add_child(_single)
	_single.hide()
	_camera = Camera3D.new()
	add_child(_camera)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_set_camera(Vector3(3, 2.7, 4), Vector3(0, .4, 0), 3.8)
	var ui := CanvasLayer.new()
	add_child(ui)
	_label = Label.new()
	_label.position = Vector2(22, 18)
	_label.text = "GHẾ NHỰA • HUNYUAN THẬT • 600 TAM GIÁC\nBàn: visual hiện có, đang chờ quota Hunyuan"
	_label.add_theme_font_size_override("font_size", 18)
	ui.add_child(_label)
	if OS.get_cmdline_user_args().has("--capture-furniture"):
		await get_tree().create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/art_pilots/furniture/furniture_set.png")
		_set.hide()
		_single.show()
		for view_name: String in ["front", "side", "back", "three_quarter"]:
			_single.rotation.y = {"front": 0.0, "side": PI / 2.0, "back": PI, "three_quarter": .65}[view_name]
			_set_camera(Vector3(0, .65, 3), Vector3(0, .26, 0), .95)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/art_pilots/furniture/stool_" + view_name + ".png")
		_single.hide()
		_set.show()
		_set_camera(Vector3(4.5, 12, 15), Vector3(0, .4, 0), 14)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/art_pilots/furniture/game_scale.png")
		print("FURNITURE PILOT REVIEW PASS: actual stool; table remains pending quota")
		get_tree().quit()

func _set_camera(position_: Vector3, target: Vector3, size_: float) -> void:
	_camera.position = position_
	_camera.look_at(target)
	_camera.size = size_
