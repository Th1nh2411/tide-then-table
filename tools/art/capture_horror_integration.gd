extends Node3D

var camera := Camera3D.new()


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	SceneRouter.set_psx_look(false)
	var view := SceneRouter.get_node_or_null("FirstPersonView")
	if view:
		view.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(camera)
	camera.fov = 70
	camera.near = 0.03
	camera.cull_mask = 0xFFFFF & ~FirstPersonView3D.HIDDEN_LAYER
	var village := (load(VillageLayout3D.SCENE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await get_tree().process_frame
	village.hud._process(0.0)
	village.process_mode = Node.PROCESS_MODE_DISABLED
	village.player.visible = false
	village.lighting.set_inside(true)
	await _shot("room", Vector3(62.0, 1.6, 5.6), Vector3(60, 0.85, 7.7))
	village.lighting.set_inside(false)
	await _shot("lane_morning", Vector3(39.0, 1.6, 4.5), Vector3(25, 1.8, 0.5))
	await _shot("waterfront", Vector3(66.0, 1.6, 0.6), Vector3(62.0, 1.3, 5.5))
	village.lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	await _shot("lane_night", Vector3(39.0, 1.6, 4.5), Vector3(25, 1.8, 0.5))
	village.queue_free()
	await get_tree().process_frame
	var sea := (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	await get_tree().process_frame
	if view:
		view.call("_attach", sea)
	sea.hud_view.refresh(sea)
	sea.process_mode = Node.PROCESS_MODE_DISABLED
	camera.global_position = sea.boat.global_position + Vector3(0, 1.4, 0)
	camera.look_at(camera.global_position + Vector3(0, -0.25, -1))
	camera.make_current()
	sea.boat_lamp.global_basis = camera.global_basis
	sea.rod.rod.tension = 0.7
	sea.rod.rod._process(0.0)
	sea.rod.rod.show_fish(load("res://data/fish/ca_thu.tres"), 1.0)
	await _save("fish_in_hand")
	sea.rod.rod.hide_fish()
	sea.rod.rod.place_bobber(sea.boat.global_position + Vector3(0, 0.1, -6))
	sea.rod.rod._process(0.0)
	await _save("rod_and_bobber")
	sea.queue_free()
	await get_tree().process_frame
	print("GAMEPLAY CAPTURES COMPLETE")
	get_tree().quit()


func _shot(id: String, eye: Vector3, target: Vector3) -> void:
	camera.global_position = eye
	camera.look_at(target)
	camera.make_current()
	await _save(id)


func _save(id: String) -> void:
	for i in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/horror_integration/%s.png" % id)
