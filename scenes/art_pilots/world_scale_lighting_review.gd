extends Node
## Deterministic gameplay-camera review. Run with --no-autosave --world-review-tag=before/after.
var tag := "after"
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--world-review-tag="): tag = arg.trim_prefix("--world-review-tag=")
	call_deferred("_run")

func _capture(label: String) -> void:
	print("CAPTURE start ",label)
	for i in 4: await get_tree().process_frame
	await get_tree().create_timer(.1).timeout
	get_viewport().get_texture().get_image().save_png("res://build/world_scale_lighting/%s_%s.png" % [tag,label])

func _run() -> void:
	GameState.reset()
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	room.set_process(false)
	room.set_physics_process(false)
	room.planning_panel.hide()
	for guest in room.guests: guest.visible = true
	var vy := PersonRig3D.build(room,"vy")
	vy.position = Vector3(-2.5,0,1.0)
	await _capture("restaurant")
	var shadow_lights: Array[Light3D] = []
	for node in room.find_children("*", "Light3D", true, false):
		if node.shadow_enabled:
			shadow_lights.append(node)
			node.shadow_enabled = false
	await _capture("restaurant_no_shadows")
	for light in shadow_lights: light.shadow_enabled = true
	room.demo_camera.position = Vector3(-3,6,8)
	room.demo_camera.look_at(Vector3(-4,0.8,-2))
	room.demo_camera.size = 7.0
	await _capture("tables")
	room.queue_free()
	await get_tree().process_frame
	GameState.reset()
	var sea = load("res://scenes/sea3d/sea_scene_3d.tscn").instantiate()
	sea.trip_end_cutscenes.clear()
	add_child(sea)
	sea.set_process(false)
	sea.set_physics_process(false)
	await _capture("sea")
	sea.camera.position = sea.boat.position + Vector3(3,3,4)
	sea.camera.look_at(sea.boat.position + Vector3.UP*.8)
	await _capture("boat")
	print("PASS gameplay world review captured: ",tag)
	sea.queue_free()
	await get_tree().process_frame
	get_tree().quit()
