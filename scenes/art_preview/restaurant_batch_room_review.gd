extends Node3D
## Visual review of the live restaurant, including all three kitchen/fridge tiers.
func _ready() -> void:
	GameState.reset()
	GameState.set_flag("met_co_nam")
	var packed: PackedScene = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn")
	var room: Node3D = packed.instantiate()
	room.arrival_cutscenes.clear()
	add_child(room)
	await get_tree().process_frame
	get_tree().paused = false
	room.set_process(false)
	room.set_physics_process(false)
	var camera: Camera3D = room.get("demo_camera")
	for level in range(3):
		GameState.upgrade_levels["kitchen"] = level
		GameState.upgrade_levels["fridge"] = level
		camera.size = 13.0
		camera.position = Vector3(5,10,12)
		camera.look_at(Vector3(4,0,-3))
		await get_tree().create_timer(.2).timeout
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/batch_integration/restaurant/room_tier%d.png" % level)
	camera.size = 9
	camera.position = Vector3(12,7,7)
	camera.look_at(Vector3(10,0,-4))
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/batch_integration/restaurant/counter_room.png")
	camera.position = Vector3(-5,7,5)
	camera.look_at(Vector3(2,0,-4))
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/batch_integration/restaurant/kitchen_reverse.png")
	print("PASS live restaurant three tiers and reverse view captured")
	get_tree().quit()
