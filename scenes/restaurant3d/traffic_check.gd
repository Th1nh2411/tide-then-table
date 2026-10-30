extends Node
## Staff A* around furniture + customer bikes park / guest walks / bike leaves.

func _ready() -> void:
	call_deferred("_run")

func _ok(cond: bool, label: String) -> void:
	print(("PASS " if cond else "FAIL ") + label)

func _run() -> void:
	var tables: Array = load("res://scenes/restaurant3d/restaurant_scene_3d.gd").TABLES
	var grid := FloorGrid3D.get_shared(tables)
	var from := RestaurantLayout3D.TABLES[0]+Vector3(0,0,-1.7)
	var to := RestaurantLayout3D.TABLES[0]+Vector3(0,0,1.7)
	var path := grid.path(from, to)
	var length := 0.0
	var clear := true
	for i in range(path.size() - 1):
		length += path[i].distance_to(path[i + 1])
		for s in range(11):
			if grid.blocked_at(path[i].lerp(path[i + 1], s / 10.0)):
				clear = false
	_ok(path.size() > 2 and clear, "staff path avoids furniture")
	_ok(length > from.distance_to(to) + 0.5, "path detours around the table")
	var node := Node3D.new()
	add_child(node)
	node.position = from
	StaffPathing3D.step(node, tables, to, 100.0)
	_ok(node.position.distance_to(to) < 0.01, "staff reaches target in one big step")
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	add_child(room)
	await get_tree().process_frame
	var traffic: CustomerTraffic3D = null
	for child in room.get_children():
		if child is CustomerTraffic3D:
			traffic = child
	_ok(traffic != null, "restaurant has customer traffic")
	get_tree().paused = false
	room.orders[0] = {"phase": "waiting"}
	room.guests[0].visible = true
	await get_tree().process_frame
	_ok(traffic.trips.size() == 1 and not room.guests[0].visible, "guest arrives by bike, not at table yet")
	var parked := false
	var seated := false
	for f in range(900):
		await get_tree().process_frame
		traffic._process(0.1)
		var phase: String = traffic.trips[0]["phase"] if not traffic.trips.is_empty() else ""
		if phase == "walking_in":
			parked = true
		if phase == "seated":
			seated = true
			break
	traffic._process(0.0)
	_ok(parked and seated and room.guests[0].visible, "bike parks, guest walks to the table")
	room.orders[0] = {}
	var left := false
	for f in range(600):
		traffic._process(0.1)
		if traffic.trips.is_empty():
			left = true
			break
	_ok(left and not room.guests[0].visible, "guest walks back and bike rides off")
	get_tree().quit()
