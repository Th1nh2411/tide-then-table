extends Node3D
var ids: Array[String] = ["bao", "vy", "vy_sau", "co_nam", "ong_tam", "guest_1", "guest_2", "guest_3", "guest_rich", "guest_regular", "staff", "cat"]
func _ready() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("737a80")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e5ddca")
	settings.ambient_light_energy = .65
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35,-35,0)
	sun.light_energy = 1.5
	add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.3
	camera.position = Vector3(0,3.4,12)
	add_child(camera)
	camera.look_at(Vector3(0,3.4,0))
	camera.current = true
	for i in ids.size():
		var actor := PersonRig3D.build(self, ids[i])
		actor.position = Vector3((i%4-1.5)*1.9,(2-i/4)*2.25,0)
		actor.rotation.y = .20
		var label := Label3D.new()
		label.text = ids[i]
		label.font_size = 32
		label.pixel_size = .007
		label.position = actor.position + Vector3(0,1.95,0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	if "--capture-batch" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://build/batch_integration/characters")
		await get_tree().create_timer(.6).timeout
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/characters/front.png")
		for actor: Node in get_children():
			if actor is PersonRig3D: actor.rotation.y = PI/2
		await get_tree().create_timer(.4).timeout
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/characters/side.png")
		for actor: Node in get_children():
			if actor is PersonRig3D: actor.rotation.y = PI
		await get_tree().create_timer(.4).timeout
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/characters/rear.png")
		get_tree().quit()
