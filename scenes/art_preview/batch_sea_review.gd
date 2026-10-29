extends Node3D

const IDS := ["ghe_cheo", "ghe_may", "lighthouse", "whale_shrine", "old_man_hut", "lobster_raft", "dock", "rock_1", "rock_2", "dolphin", "non_la", "net_buoy", "jellyfish"]
var model: Node3D
var camera: Camera3D
var caption: Label

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("263440")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c2c8cc")
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var light := DirectionalLight3D.new()
	add_child(light)
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_color = Color("ffdfb6")
	light.light_energy = 1.05
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_font_size_override("font_size", 24)
	layer.add_child(caption)
	for id: String in IDS:
		if model:
			remove_child(model)
			model.queue_free()
		model = load("res://assets/models/ready/" + id + "/" + id + ".glb").instantiate()
		add_child(model)
		var bounds := AABB()
		var found := false
		for child: Node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			var box := mesh.global_transform * mesh.get_aabb()
			bounds = bounds.merge(box) if found else box
			found = true
		var size: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
		var target := bounds.get_center()
		camera.size = size * 1.25
		camera.position = target + Vector3(size * .9, size * .7, size * 1.1)
		camera.look_at(target)
		caption.text = "HUNYUAN BATCH • " + id
		await get_tree().create_timer(.08).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/sea/" + id + ".png")
		camera.position = target + Vector3(-size * .9, size * .55, -size * 1.1)
		camera.look_at(target)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/sea/" + id + "_back.png")
	print("PASS sea batch 13-model visual review")
	get_tree().quit()
