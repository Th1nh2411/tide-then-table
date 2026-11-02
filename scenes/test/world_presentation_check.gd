extends Node
## Check actual loaded worlds, including dynamic actors and the cast cinematic.
var failures := 0
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: failures += 1

func shadows(root: Node) -> bool:
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for mesh: MeshInstance3D in meshes:
		if mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: return false
	return not meshes.is_empty()

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	await get_tree().process_frame
	var stools: Array[Node] = room.find_children("PilotStool_*", "Node3D", true, false)
	var correct_stools: bool = stools.size() == room.guests.size() * 2
	var correct_collision := true
	for stool: Node3D in stools:
		correct_stools = correct_stools and stool.scale.is_equal_approx(Vector3.ONE * .85) and shadows(stool)
		var matched := false
		for obstacle: Node in room.get_children():
			if not obstacle is StaticBody3D: continue
			var body := obstacle as StaticBody3D
			if body.position.distance_to(stool.position + Vector3.UP*.221) > .001: continue
			var shape := (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
			matched = shape != null and shape.size.is_equal_approx(Vector3(.4675,.442,.4675))
		correct_collision = correct_collision and matched
	check(correct_stools and correct_collision, "Low stools and matching collision: .47m footprint, .44m seat")
	check(room.body.scale.is_equal_approx(Vector3.ONE), "Restaurant actor scale preserved; only person/stool proportion changes")
	var lamps: Array[Node] = room.find_children("WarmShopLight*", "SpotLight3D", true, false)
	var lit: bool = lamps.size() == 6
	for lamp: SpotLight3D in lamps:
		lit = lit and lamp.shadow_enabled and (-lamp.global_basis.z).dot(Vector3.DOWN) > .99
	check(lit, "Six warm downward shop lights cast real shadows")
	check((room.get_node("StreetKeyLight") as DirectionalLight3D).shadow_enabled, "Street key casts shadows across the whole restaurant")
	for id: String in ["rin","bao","vy","vy_sau","co_nam","ong_tam","guest_1","guest_2","guest_3","guest_rich","guest_regular","staff","cat"]:
		var actor := PersonRig3D.build(room,id)
		check(shadows(actor), id + " loaded character meshes cast shadows")
		if id == "guest_1":
			actor.set_variant("guest_rich")
			check(shadows(actor), "Dynamic customer appearance keeps shadow casting")
		actor.queue_free()
	for node: Node in room.get_children():
		if node is Node3D and node.name.begins_with("Batch_"): check(shadows(node), "Prop shadows: " + node.name)
	room.queue_free()
	await get_tree().process_frame
	GameState.reset()
	var sea = load("res://scenes/sea3d/sea_scene_3d.tscn").instantiate()
	sea.trip_end_cutscenes.clear()
	add_child(sea)
	await get_tree().process_frame
	var rider := sea.boat_visual.get_node("RinOnBoat") as Node3D
	var hull := sea.boat_visual.get_node("HunyuanThungHull") as Node3D
	check(rider.scale.is_equal_approx(Vector3.ONE*.85) and hull.scale.is_equal_approx(Vector3(1,.75,1)), "Sea rider and hull scale remain unchanged")
	check(shadows(rider) and shadows(hull) and sea.boat_lamp.shadow_enabled, "Boat, Rin and boat lamp support real shadows")
	sea.cinematic._target = sea.boat.position + Vector3.FORWARD*3
	sea.cinematic._build_props()
	check(sea.cinematic._rig.scale.is_equal_approx(rider.scale), "Cast cinematic keeps the same sea actor scale")
	sea.cinematic._clear_props()
	sea.queue_free()
	await get_tree().process_frame
	print("WORLD PRESENTATION CHECK ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)
