extends Node3D
## Windowed, eye-level night captures of the actual village; no placement edits.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	SaveSystem.autosave_off = true
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().content_scale_size = Vector2i.ZERO
	get_window().size = Vector2i(1280, 720)
	GameState.reset()
	SceneRouter.set_psx_look(false)
	var view := SceneRouter.get_node_or_null("FirstPersonView")
	if view:
		view.process_mode = Node.PROCESS_MODE_DISABLED
	var village := (load(VillageLayout3D.SCENE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await get_tree().process_frame
	village.process_mode = Node.PROCESS_MODE_DISABLED
	village.player.visible = false
	village.hud.visible = false
	village.lighting.set_inside(false)
	village.lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	var camera := Camera3D.new()
	camera.fov = 75
	add_child(camera)
	camera.make_current()
	var seen: Dictionary = {}
	var suffix := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	var folder := "res://build/brief6/street_" + suffix
	DirAccess.make_dir_recursive_absolute(folder)
	var spans := StreetLife3D.spans_x(StreetFacades3D.BEND_X.x - 1.0, StreetFacades3D.JUNCTION_X, 2)
	for index: int in range(3):
		var id: String = "tube_house_" + ["a", "b", "c"][(index + 2) % 3]
		var x: float = spans[index].x
		seen[id] = true
		for i: int in range(3):
			await get_tree().process_frame
		camera.global_position = Vector3(x + 2.4, 1.6, 10.2)
		camera.look_at(Vector3(x, 3.2, 18.0))
		camera.make_current()
		camera.reset_physics_interpolation()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder + "/" + id + ".png")
		print("STREET SHOT ", id, " eye=", camera.global_position)
	if suffix == "after":
		for wanted: String in ["table_stall_folding", "food_cart_glass", "planter_tree_street"]:
			for node: Node in village.find_children("*", "Node3D", true, false):
				if str(node.get_meta("horror_model_id", "")) != wanted:
					continue
				var item := node as Node3D
				var point := item.global_position
				if wanted == "planter_tree_street" and point.x > -25.0:
					continue
				var eye := point + item.global_basis * Vector3(1.8, 0, 2.3)
				eye.y = 1.6
				var focus := point + Vector3(0, 0.7, 0)
				if wanted == "food_cart_glass":
					eye = point + item.global_basis * Vector3(1.9, 0, -2.4)
					eye.y = 1.6
				if wanted == "planter_tree_street":
					eye = point + Vector3(3.0, 1.6, 5.0)
					focus = point + Vector3(0, 2.0, 0)
					var rin := PersonRig3D.build(village, "rin")
					rin.process_mode = Node.PROCESS_MODE_ALWAYS
					rin.position = point + Vector3(-1.1, 0, 0)
				for frame: int in range(3):
					await get_tree().process_frame
				camera.global_position = eye
				camera.look_at(focus)
				camera.make_current()
				camera.reset_physics_interpolation()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(folder + "/" + wanted + ".png")
				print("DETAIL SHOT ", wanted, " at=", point)
				break
		village.queue_free()
		await get_tree().process_frame
		var sea := (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate() as SeaScene3D
		add_child(sea)
		await get_tree().process_frame
		for frame: int in range(8):
			await get_tree().process_frame
		sea.process_mode = Node.PROCESS_MODE_DISABLED
		camera.global_position = sea.boat.global_position + Vector3(1.5, 1.6, 2.0)
		camera.look_at(sea.boat.global_position + Vector3(0, 0.2, 0))
		camera.make_current()
		var sea_view := SceneRouter.get_node_or_null("FirstPersonView")
		if sea_view:
			sea_view.process_mode = Node.PROCESS_MODE_DISABLED
		camera.make_current()
		camera.reset_physics_interpolation()
		for frame: int in range(4):
			await get_tree().process_frame
			camera.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder + "/thung_boat.png")
		var paddles := 0
		for node: Node in sea.find_children("*", "Node3D", true, false):
			if node.name == "Paddle":
				paddles += 1
		print("SEA SHOT thung_boat live_paddles=", paddles)
	print("STREET REVIEW ", suffix, " houses=", seen.size())
	get_tree().quit(0 if seen.size() == 3 else 1)
