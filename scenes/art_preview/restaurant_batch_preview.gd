extends Node3D
## Inspection only: prepared geometry from the local Hunyuan restaurant batch.
const IDS := ["food_cart_0", "food_cart_1", "food_cart_2", "charcoal_grill", "beer_keg", "plate_bench", "fridge_0", "fridge_1", "fridge_2", "menu_board", "grocery_counter", "motorbike", "sidewalk_tree", "bin", "plant_pot", "beer_tower", "grocery_crate", "plastic_bag", "crate", "bottle"]
var _models: Array[Node3D] = []
var _camera: Camera3D

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("263440")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c2c8cc")
	env.ambient_light_energy = .65
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-30,0)
	sun.light_color = Color("ffdfb6")
	sun.light_energy = 1.0
	add_child(sun)
	for i in range(IDS.size()):
		var model: Node3D = load("res://assets/models/ready/%s/%s.glb" % [IDS[i],IDS[i]]).instantiate()
		add_child(model)
		model.position = Vector3((i % 5)*4.5-9,0,(i/5)*4.5-6.75)
		_models.append(model)
		var title := Label3D.new()
		title.text = IDS[i]
		title.position = model.position+Vector3(0,.03,1.5)
		title.rotation_degrees.x = -90
		title.font_size = 30
		title.pixel_size = .006
		add_child(title)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 27
	add_child(_camera)
	_camera.position = Vector3(12,20,25)
	_camera.look_at(Vector3(0,0,0))
	_camera.current = true
	if OS.get_cmdline_user_args().has("--capture-restaurant-batch"):
		await get_tree().create_timer(.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/restaurant/gallery.png")
		for i in range(IDS.size()):
			var bounds := AABB()
			var first := true
			for node: Node in _models[i].find_children("*","MeshInstance3D",true,false):
				var box := (node as MeshInstance3D).global_transform * (node as MeshInstance3D).get_aabb()
				bounds = box if first else bounds.merge(box)
				first = false
			var size := maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
			var target := bounds.get_center()
			_camera.size = size*1.5
			_camera.position = target+Vector3(2,1.5,3)*maxf(1,size)
			_camera.look_at(target)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/batch_integration/restaurant/%s.png" % IDS[i])
		print("PASS restaurant batch preview 20 prepared Hunyuan models")
		get_tree().quit()
