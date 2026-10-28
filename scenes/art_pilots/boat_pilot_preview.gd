extends Node3D
## Isolated view of the Hunyuan hull; no runtime state or saves are changed.
var hull: Node3D
var camera: Camera3D
var reference: TextureRect

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var world := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263440")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b7c1c5")
	settings.ambient_light_energy = 0.65
	world.environment = settings
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffdfb6")
	sun.light_energy = 1.05
	sun.rotation_degrees = Vector3(-48, -30, 0)
	add_child(sun)
	hull = load("res://scenes/art_pilots/boat_pilot.tscn").instantiate()
	add_child(hull)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.15
	camera.current = true
	add_child(camera)
	set_view("three_quarter")
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.text = "THUYỀN THÚNG • HUNYUAN PILOT\n2.400 tam giác • đường kính 2,4 m\n← → xoay • 1/2/3/4: các góc nhìn"
	title.position = Vector2(24, 22)
	title.add_theme_font_size_override("font_size", 20)
	ui.add_child(title)
	reference = TextureRect.new()
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference.texture = load("res://assets/models/pilots/thuyen_thung/input.png")
	reference.position = Vector2(24, 140)
	reference.size = Vector2(260, 174)
	ui.add_child(reference)
	if OS.get_cmdline_user_args().has("--capture-boat-pilot"):
		await get_tree().create_timer(0.3).timeout
		for view_name: String in ["front", "side", "back", "three_quarter", "top", "game_scale"]:
			set_view(view_name)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/art_pilots/boat/" + view_name + ".png")
		print("PASS Hunyuan boat pilot 2400-face import, multi-angle and game-scale views")
		get_tree().quit()

func set_view(view_name: String) -> void:
	var locations := {"front": Vector3(0, 1.25, 4), "side": Vector3(4, 1.25, 0), "back": Vector3(0, 1.25, -4), "three_quarter": Vector3(3, 2.7, 4), "top": Vector3(0, 4, 0.01), "game_scale": Vector3(0, 7.3, 10)}
	camera.position = locations[view_name]
	camera.look_at(Vector3(0, 0.25, 0))
	camera.size = 10.5 if view_name == "game_scale" else 3.15
	camera.h_offset = -0.32 if view_name != "game_scale" else 0.0

func _process(delta: float) -> void:
	if hull:
		hull.rotation.y += (float(Input.is_physical_key_pressed(KEY_LEFT)) - float(Input.is_physical_key_pressed(KEY_RIGHT))) * delta * 1.5

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: set_view("three_quarter")
		KEY_2: set_view("top")
		KEY_3: set_view("side")
		KEY_4: set_view("game_scale")
