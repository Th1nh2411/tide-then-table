extends Node
## Capture real gameplay cameras at dining, kitchen, counter and both boat sizes.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")
func _capture(name_: String) -> void:
	await get_tree().create_timer(.25).timeout
	get_viewport().get_texture().get_image().save_png("res://build/world_composition/%s.png" % name_)
func _run() -> void:
	GameState.reset()
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	room.set_process(false)
	room.set_physics_process(false)
	room.planning_panel.hide()
	for child in room.get_children():
		if child is CustomerTraffic3D: child.set_process(false)
	for guest: PersonRig3D in room.guests:
		guest.visible = true
		guest.sample_seating(1)
		guest.set_seated(true)
	var camera := room.demo_camera as RestaurantCamera3D
	camera.track(room.player.position,10)
	await _capture("restaurant_spawn")
	for entry: Array in [["restaurant_dining",Vector3(2.5,0,2.0)],["restaurant_kitchen",Vector3(-.6,0,-2.6)],["restaurant_counter",Vector3(9.6,0,-2.6)]]:
		room.player.position = entry[1]
		camera.track(room.player.position,10)
		await _capture(entry[0])
	camera.set_process(false)
	camera.size = 5.5
	camera.position = Vector3(7,3.2,5)
	camera.look_at(Vector3(2.5,.8,1.4))
	await _capture("seating_close")
	room.queue_free()
	await get_tree().process_frame
	for level in [0,2]:
		GameState.reset()
		GameState.upgrade_levels["boat"] = level
		var sea = load("res://scenes/sea3d/sea_scene_3d.tscn").instantiate()
		sea.trip_end_cutscenes.clear()
		add_child(sea)
		sea.set_process(false)
		sea.set_physics_process(false)
		await _capture("sea_%d" % level)
		sea.queue_free()
		await get_tree().process_frame
	print("PASS world composition captured")
	get_tree().quit()
