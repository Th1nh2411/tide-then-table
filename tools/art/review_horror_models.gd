extends SceneTree
## Render imported assets with the same lit concept materials used in game.

func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	root.size = Vector2i(512, 512)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("333940")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 0.9
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(camera)
	camera.make_current()
	var ids: Array = JSON.parse_string(FileAccess.get_file_as_string("res://build/hunyuan_free/verified.json"))["complete"]
	DirAccess.make_dir_recursive_absolute("res://build/horror_integration/review")
	for entry: Dictionary in ids:
		var id := String(entry["name"])
		var model := ConceptModel3D.spawn(world, id, Vector3.ZERO, 2.0)
		await process_frame
		var bounds := AABB()
		var first := true
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var center := bounds.get_center()
		var extent := bounds.size.length()
		camera.size = maxf(extent * 1.05, 1.0)
		for angle: int in range(3):
			var yaw := float(angle) * 2.1 + 0.35
			camera.position = center + Vector3(sin(yaw), 0.55, cos(yaw)) * extent * 2.0
			camera.look_at(center)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/horror_integration/review/%s_%d.png" % [id, angle])
		model.queue_free()
		await process_frame
	print("HORROR REVIEW: 25 models, 3 angles each")
	quit()
