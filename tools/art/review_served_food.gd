extends Node3D

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveSystem.autosave_off = true
	var root := get_tree().root
	root.size = Vector2i(1000, 750)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("333940")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	world.add_child(light)
	var rig := PersonRig3D.build(world, "rin")
	rig.position.x = -0.45
	rig.set_carrying(true)
	var tabletop := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.04, 0.6)
	tabletop.mesh = box
	world.add_child(tabletop)
	tabletop.position = Vector3(0.65, 0.78, 0)
	var serving := Node3D.new()
	world.add_child(serving)
	serving.position = Vector3(0.65, 0.80, 0)
	var camera := Camera3D.new()
	camera.fov = 40
	world.add_child(camera)
	camera.position = Vector3(1.8, 1.7, 2.6)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.make_current()
	DirAccess.make_dir_recursive_absolute("res://build/brief5/serving")
	for id: String in ["dish_plate_fish", "dish_bowl_soup", "beer_tower"]:
		ServedFoodVisual3D.show_kind(rig.plate, id)
		ServedFoodVisual3D.show_kind(serving, id, false, true)
		for i: int in range(3):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/brief5/serving/%s.png" % id)
	print("SERVING REVIEW OK")
	get_tree().quit()
