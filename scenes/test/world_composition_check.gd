extends Node3D
var failures := 0
func check(ok: bool, text_: String) -> void:
	print(("PASS " if ok else "FAIL ")+text_)
	if not ok: failures += 1
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	GameState.reset()
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	room.set_process(false)
	room.set_physics_process(false)
	await get_tree().process_frame
	var camera := room.demo_camera as RestaurantCamera3D
	check(camera!=null and is_equal_approx(camera.size,12.0),"Restaurant camera zooms from 14 to 12")
	var clear := true
	for point: Vector3 in [Vector3(-7,0,2.6),Vector3(-.6,0,-2.6),Vector3(9.6,0,-2.6),Vector3(-19,0,-7.2),Vector3(19,0,7.8)]:
		camera.track(point,20)
		var pixel := camera.unproject_position(point+Vector3.UP*.9)
		var uv := pixel/camera.get_viewport().get_visible_rect().size
		var head := camera.unproject_position(point+Vector3.UP*1.8)/camera.get_viewport().get_visible_rect().size
		clear = clear and not camera.is_position_behind(point) and Rect2(.02,.10,.96,.80).has_point(uv) and Rect2(.02,.16,.96,.70).has_point(head)
		print("camera point ",point," -> ",uv)
	check(clear,"Rin stays framed at tables, both counters and room edges")
	var resting := camera.global_transform
	camera.current = false
	camera._process(1.0)
	check(camera.global_transform.is_equal_approx(resting),"Gameplay camera yields to cutscene cameras")
	camera.current = true
	var grid := FloorGrid3D.get_shared(RestaurantLayout3D.TABLES)
	check(grid.blocked_at(RestaurantLayout3D.BOARD_POSITION) and grid.blocked_at(RestaurantLayout3D.KITCHEN_BOARD_POSITION) and not grid.blocked_at(Vector3(1.5,0,6.9)),"Moved boards update navigation and free the old footprint")
	for id: String in ["guest_1","guest_2","guest_3","guest_rich","guest_regular"]:
		var guest := PersonRig3D.build(self,id)
		guest.sample_seating(1)
		var visual := guest._pilot
		var sk := visual.skeleton
		var hip := visual.to_local(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Hips")).origin))
		var feet_ok := true
		for side: String in ["L","R"]:
			var foot := visual.to_local(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Foot."+side)).origin))
			feet_ok = feet_ok and foot.y > .04 and foot.y < .16 and foot.z > .2
		check(absf(hip.y-.5)<.04 and feet_ok,id+" sits at the actual .442m stool with feet down")
		guest.sample_seating(1,true)
		var standing := visual.to_local(sk.to_global(sk.get_bone_global_pose(sk.find_bone("Hips")).origin))
		check(standing.y>.7 and visual.animation.get_animation("StandUp").loop_mode==Animation.LOOP_NONE,id+" stand-up ends upright without looping")
		guest.queue_free()
	room.queue_free()
	await get_tree().process_frame
	for level in [0,2]:
		GameState.reset()
		GameState.upgrade_levels["boat"] = level
		var sea = load("res://scenes/sea3d/sea_scene_3d.tscn").instantiate()
		sea.trip_end_cutscenes.clear()
		add_child(sea)
		sea.set_physics_process(false)
		var sea_camera := sea.camera as Camera3D
		var start: Vector3 = sea.boat.position
		var foot := sea_camera.unproject_position(start+Vector3.UP*.2)
		var head := sea_camera.unproject_position(start+Vector3.UP*2.4)
		var bounds := sea_camera.get_viewport().get_visible_rect()
		check(is_equal_approx(sea_camera.fov,56) and start.distance_to(sea_camera.position)<11.0 and bounds.has_point(foot) and bounds.has_point(head),"Closer sea camera frames boat level %d and Rin" % level)
		sea.queue_free()
		await get_tree().process_frame
	print("WORLD COMPOSITION CHECK ","PASS" if failures==0 else "FAIL")
	get_tree().quit(1 if failures else 0)
