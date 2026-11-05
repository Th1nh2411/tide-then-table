extends SceneTree
## Render imported assets with the same lit concept materials used in game.

func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	root.size = Vector2i(512, 512)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
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
	var all_sides := OS.get_cmdline_user_args().has("--all-sides")
	var baseline := OS.get_cmdline_user_args().has("--baseline")
	if baseline and not FileAccess.file_exists("res://build/brief7/baseline_model.gd"):
		push_error("Run python3 tools/art/stage_horror_brief7_baseline.py first")
		quit(1)
		return
	var factory = load("res://build/brief7/baseline_model.gd") if baseline else ConceptModel3D
	var folder := "res://build/brief7/sides_before" if baseline else "res://build/brief7/sides_after"
	if not all_sides:
		folder = "res://build/horror_integration/review"
	var ids: Array = []
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ready/horror_models.json"))
	for id: String in catalog:
		ids.append({"name": id})
	DirAccess.make_dir_recursive_absolute(folder)
	for entry: Dictionary in ids:
		var id := String(entry["name"])
		var model: Node3D = factory.spawn(world, id, Vector3.ZERO, 2.0)
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
		for angle: int in range(6 if all_sides else 3):
			var yaw := float(angle) * 2.1 + 0.35
			camera.position = center + Vector3(sin(yaw), 0.55, cos(yaw)) * extent * 2.0
			if all_sides:
				var directions := [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN]
				camera.position = center + directions[angle] * extent * 2.0
				camera.look_at(center, Vector3.FORWARD if angle >= 4 else Vector3.UP)
			else:
				camera.look_at(center)
			await process_frame
			# An offscreen target keeps captures moving even when another window
			# covers this review. Do not wait for a visible-window redraw signal.
			RenderingServer.force_draw(false)
			viewport.get_texture().get_image().save_png(folder + "/%s_%d.png" % [id, angle])
		model.queue_free()
		await process_frame
	print("HORROR REVIEW: %d models, %d angles each" % [ids.size(), 6 if all_sides else 3])
	quit()
