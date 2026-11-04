extends Node3D
## The world's edges (PLAN §10 "Hoàn thiện thế giới"): the fog loop at both
## ends of the village keeps Rin's heading and puts him on ground, never fires
## on the normal routes, the fall safety net, the sea's edge pushing back,
## real blockers (not only invisible walls) at the visible village edges, and
## the dead-end alley's gate (shut, ajar on mùng 13-14, its fog turning Rin
## back out to the same gate), the pier starting on the sand and the beach's
## slope (Rin walks sand -> pier -> thúng, and stops above the waterline).

var failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	var village := (load(VillageLayout3D.SCENE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var loop := village.get_node("WorldEdgeLoop") as WorldEdgeLoop3D
	_check(loop != null, "the village has its fog loop")
	_loop_checks(village, loop)
	_route_checks(loop)
	await _gate_checks(village, loop)
	await _fall_checks(village)
	_edge_checks(village)
	await _pier_beach_checks(village)
	village.queue_free()
	await get_tree().process_frame
	await _sea_checks()
	print("WORLD EDGES TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _loop_checks(village: VillageScene3D, loop: WorldEdgeLoop3D) -> void:
	var player := village.player
	var before := WorldEdgeLoop3D.tries()
	# Walking west out of the street, 25 m into the fog.
	player.global_position = Vector3(WorldEdgeLoop3D.WEST_MOUTH - loop.loop_depth - 0.2, 0, 5.0)
	player.rotation.y = -PI * 0.5
	player.velocity = Vector3(-1.2, 0, 0.1)
	loop._process(0.0)
	var p := player.global_position
	var at := loop.depth_at(p)
	_check(at.y > 0.0 and at.x < loop.loop_depth, "west fog comes out on the east shore path, still in the fog")
	_check(is_equal_approx(player.rotation.y, -PI * 0.5) and player.velocity.is_equal_approx(Vector3(-1.2, 0, 0.1)), "heading and speed are kept through the loop")
	_check(absf((p.z - VillageEdges3D.EAST_Z.x) - (5.0 - StreetFacades3D.WEST_Z.x)) < 0.01, "his place across the path is kept")
	_check(_ground_under(p), "he lands on ground")
	_check(_capsule_free(p, player), "he lands clear of walls and props")
	_check(WorldEdgeLoop3D.tries() == before + 1, "the try is counted")
	# And back the other way.
	player.global_position = Vector3(WorldEdgeLoop3D.EAST_MOUTH + loop.loop_depth + 0.3, 0, 3.0)
	loop._process(0.0)
	p = player.global_position
	at = loop.depth_at(p)
	_check(at.y < 0.0 and at.x < loop.loop_depth and _ground_under(p) and _capsule_free(p, player), "east fog comes out on the west pavement, on ground")
	loop._process(0.0)
	_check(loop._signs.has_sign(), "from the second try a wrong thing waits in the fog")
	player.global_position = Vector3(0, 0, 2.0)
	loop._process(0.0)
	_check(not loop._signs.has_sign(), "it is gone once he is out of the fog")
	_check(village.lighting.haze_density > 0.0 and (village.get_node("RestaurantEnvironment") as WorldEnvironment).environment.fog_density < 0.1, "the fog is back to normal outside")


## The everyday routes never reach the fog paths.
func _route_checks(loop: WorldEdgeLoop3D) -> void:
	var routes: Array[Vector3] = []
	for x in range(-19, 20, 2):
		for z in range(-7, 9, 3):
			routes.append(Vector3(x, 0, z))  # the street
	for x in range(20, 48, 3):
		routes.append(Vector3(x, 0, VillageLayout3D.LANE_Z))  # the lane
	for x in range(47, 81, 3):
		for z in range(-2, 10, 3):
			routes.append(Vector3(x, 0, z))  # the waterfront
	routes.append(VillageLayout3D.pier_start())
	routes.append(VillageLayout3D.morning_start())
	var fired := false
	for p in routes:
		if loop.depth_at(p).y != 0.0:
			fired = true
	_check(not fired, "street, lane, waterfront, pier and room never count as fog")
	_check(loop.depth_at(Vector3(-25.0, 0, 5.0)).x < loop.haze_from + 1.5, "the first metres of the west pavement are still clear")


func _gate_checks(village: VillageScene3D, loop: WorldEdgeLoop3D) -> void:
	var gate := loop.gate
	_check(gate != null and not gate.is_open, "the alley gate is there, chained shut on mùng 9")
	var X := VillageGateAlley3D.X
	var at_gate := Vector3((X.x + X.y) * 0.5, 0, VillageGateAlley3D.GATE_Z)
	var player := village.player
	_check(not _capsule_free(at_gate, player) and gate.depth_at(at_gate + Vector3(0, 0, 3)) < 0.0, "shut: it blocks the way and its fog is not a loop")
	var open_days: Array[int] = []
	for day in range(1, LoopCalendar.NIGHTS + 1):
		if day in gate.open_days:
			open_days.append(day)
	var want: Array[int] = [5, 6]
	_check(open_days == want, "ajar only on mùng 13-14 (shut again on rằm)")
	gate.set_open(true)
	await get_tree().physics_frame
	_check(_capsule_free(at_gate + Vector3(0.4, 0, 0.0), player), "ajar: Rin fits through")
	var tries := WorldEdgeLoop3D.gate_tries()
	var deep := at_gate + Vector3(0.3, 0, gate.loop_depth + 0.2)
	player.global_position = deep
	player.rotation.y = 0.0
	player.velocity = Vector3(0.1, 0, 1.2)
	loop._process(0.0)
	var p := player.global_position
	_check(gate.depth_at(p) > 0.0 and gate.depth_at(p) < gate.loop_depth, "deep in its fog he is still in the fog")
	_check(is_equal_approx(player.rotation.y, PI) and player.velocity.is_equal_approx(Vector3(-0.1, 0, -1.2)), "turned round: walking back towards the gate")
	_check(absf((p.x - at_gate.x) + (deep.x - at_gate.x)) < 0.01, "his side of the corridor is mirrored with him")
	_check(_ground_under(p) and _capsule_free(p, player), "on ground, clear of the walls")
	_check(WorldEdgeLoop3D.gate_tries() == tries + 1, "the gate's tries are counted")
	player.global_position = deep
	loop._process(0.0)
	_check(loop._gate_signs.has_sign(), "second time: a wrong thing in the gate's fog")
	player.global_position = Vector3(30.0, 0, VillageLayout3D.LANE_Z)
	loop._process(0.0)
	_check(not loop._gate_signs.has_sign() and (village.get_node("RestaurantEnvironment") as WorldEnvironment).environment.fog_density < 0.1, "gone back in the lane, fog normal")
	var lane_hits := 0
	for x in range(20, 48):
		for z: float in [VillageLayout3D.LANE_Z, 1.2, 5.8, 9.0, 14.0]:
			if gate.depth_at(Vector3(x, 0, z)) >= 0.0:
				lane_hits += 1
	_check(lane_hits == 0, "the lane and the alley itself never count as the gate's fog")
	gate.set_open(false)


func _fall_checks(village: VillageScene3D) -> void:
	var net := village.get_node("FallSafety") as FallSafety3D
	_check(net != null, "the village has a fall safety net")
	village.player.global_position = Vector3(55.0, 0, 3.0)
	net.check()
	village.player.global_position = Vector3(55.0, -6.0, 3.0)
	_check(net.check() and village.player.global_position.is_equal_approx(Vector3(55.0, 0, 3.0)), "falling below -5 puts him back where he last stood")
	_check(net._black.modulate.a > 0.9, "the screen is black for the move")
	for i in 60:
		await get_tree().process_frame
	_check(net._black.modulate.a < 0.05, "and clears after half a second")


## Visible edges have something real standing on them.
func _edge_checks(village: VillageScene3D) -> void:
	var fences := 0
	var houses := village.find_children("EdgeHouses", "Node3D", true, false).size()
	for node in village.find_children("*bamboo_fence*", "Node3D", true, false):
		var p := (node as Node3D).global_position
		if absf(p.x - VillageLayout3D.GROUND_X.x) < 0.5 or absf(p.z - VillageLayout3D.GROUND_Z.y) < 0.5:
			fences += 1
	_check(fences >= 6, "fences stand on the waterfront's west and south edges")
	_check(houses == 1, "houses line the east shore path")
	_check(village.find_children("StreetFacades", "Node3D", true, false).size() == 1 and village.find_children("OppositeRow", "Node3D", true, false).size() == 1, "house rows close both street ends and the far side of the road")
	_check(village.find_children("Ground", "Node3D", true, false).size() >= 1, "one big ground lies under the village")


## The pier starts on the dry sand, Rin walks it out to the thúng on solid
## planks, and down the beach only to just above the water.
func _pier_beach_checks(village: VillageScene3D) -> void:
	var player := village.player
	village.set_physics_process(false)
	var w := VillageLayout3D.WATERFRONT
	var pier_x := w.x + WaterfrontBuilder3D.THUNG.x
	_check(WaterfrontBuilder3D.PIER_START_Z > ShoreBeach3D.TOP_Z + 0.5, "the pier's shore end lies on the dry sand")
	var holes := 0
	var z := VillageLayout3D.GROUND_Z.x + 1.5
	while z > VillageLayout3D.PIER_END_Z + 0.3:
		if not _ground_under(Vector3(pier_x, 0, z)):
			holes += 1
		z -= 0.25
	_check(holes == 0, "ground or planks under every step from the sand to the pier end")
	var walk := await _walk(village, Vector3(pier_x, 0, VillageLayout3D.GROUND_Z.x + 3.0), Vector3(0, 0, -3.0), 8.0)
	var thung := VillageSpots3D.thung_point()
	_check(walk[0] and absf(player.global_position.y) < 0.05, "sand -> pier -> pier end without falling or climbing")
	_check(player.global_position.distance_to(thung) < VillageSpots3D.THUNG_REACH and VillageLayout3D.on_pier(player.global_position), "he ends by the thúng, on the pier")
	var beach_x := 60.0
	walk = await _walk(village, Vector3(beach_x, 0, VillageLayout3D.GROUND_Z.x + 1.0), Vector3(0, 0, -3.0), 4.0)
	var p := player.global_position
	var water_z := w.z + ShoreBeach3D.z_at_height(beach_x - w.x, WaterfrontBuilder3D.WATER_Y)
	_check(walk[0] and p.z < VillageLayout3D.GROUND_Z.x - 1.0, "Rin walks a little way down the beach")
	_check(p.z > water_z and p.y > WaterfrontBuilder3D.WATER_Y and p.y < -0.1, "and stops on the slope above the waterline, feet on the sand")
	walk = await _walk(village, Vector3(VillageLayout3D.PIER_X.x - 2.0, 0, VillageLayout3D.GROUND_Z.x - 1.2), Vector3(3.0, 0, 0), 2.0)
	_check(player.global_position.x < VillageLayout3D.PIER_X.x, "the pier's side stops him on the beach")
	village.set_physics_process(true)


## Walks Rin at `velocity` for `seconds` (no gravity, the beach keeps his
## feet); [never fell, lowest y].
func _walk(village: VillageScene3D, from: Vector3, velocity: Vector3, seconds: float) -> Array:
	var player := village.player
	player.global_position = from
	await get_tree().physics_frame
	var net := village.get_node("FallSafety") as FallSafety3D
	var rescues := net.rescues
	var low := 0.0
	for i in int(seconds * 60.0):
		player.velocity = velocity
		player.move_and_slide()
		village.follow_ground()
		low = minf(low, player.global_position.y)
		await get_tree().physics_frame
	return [net.rescues == rescues and low > -0.5, low]


func _sea_checks() -> void:
	var half := SeaLayout3D.size_world() * 0.5
	var reach := SeaLayout3D.reach_z(0.32)
	_check(SeaEdge3D.amount(Vector3(0, 0, reach + SeaEdge3D.MARGIN + 1.0), reach, half) == 0.0, "open water is not the edge")
	_check(SeaEdge3D.amount(Vector3(0, 0, reach), reach, half) == 1.0 and SeaEdge3D.amount(Vector3(half.x - 1.0, 0, 30.0), reach, half) > 0.8, "the reach and the map sides are")
	var sea := (load(VillageDay3D.SEA) as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	await get_tree().physics_frame
	sea.boat.position = Vector3(sea.START.x, 0, reach + 0.5)
	sea.boat.rotation.y = 0.0  # bow to the open sea
	for i in 90:
		sea.boat.velocity = Vector3(0, 0, -0.5)
		SeaEdge3D.step(sea, 1.0 / 60.0)
		sea.boat.rotation.y += sea.yaw_velocity / 60.0
	_check(sea.edge_amount > 0.9, "the boat feels the edge")
	var light := SeaEdge3D.home_light(sea) - sea.boat.position
	_check(absf(angle_difference(sea.boat.rotation.y, atan2(-light.x, -light.z))) < 1.2, "the bow swings round towards the lighthouse")
	sea.boat.velocity = Vector3.ZERO
	SeaEdge3D.step(sea, 0.5)
	_check(sea.boat.velocity.z > 0.0, "the current pushes back towards the dock")
	_check(sea.has_node("FallSafety"), "the sea has the fall safety net too")
	sea.queue_free()
	await get_tree().process_frame


func _ground_under(p: Vector3) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 1.0)
	return not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func _capsule_free(p: Vector3, player: CharacterBody3D) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.4
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.85)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 4).is_empty()


func _check(ok: bool, words: String) -> void:
	print(("PASS " if ok else "FAIL ") + words)
	if not ok:
		failures += 1
