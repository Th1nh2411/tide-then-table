class_name CustomerTraffic3D
extends Node3D
## Guests arrive by motorbike: the bike rides along the road, parks by the curb,
## the guest walks (A*) to the table; when the table empties the guest walks back
## and the bike rides off. Reads the host's `orders` / `guests` / `TABLES` only.

const PARK_Z := 8.65
const LANE_Z := 9.8
const SLOT_XS: Array[float] = [-8.0, -4.0, 0.0, 4.0, 8.0, 12.0]
const EDGE_X := 26.0
const BIKE_SPEED := 5.0
const WALK_SPEED := 2.2
const SEAT_OFFSET := Vector3(0, 0, 1.15)

@export var host: Node3D

## One trip: bike + walker. phase: riding_in, walking_in, seated, walking_out, riding_out.
var trips: Array[Dictionary] = []
var _by_table: Dictionary = {}
var _used_slots: Dictionary = {}


func _process(delta: float) -> void:
	if host == null:
		return
	var orders: Array = host.get("orders")
	var guests: Array = host.get("guests")
	for i in range(orders.size()):
		var occupied: bool = not (orders[i] as Dictionary).is_empty()
		if occupied and not _by_table.has(i):
			_begin(i)
		elif not occupied and _by_table.has(i):
			_leave(i)
		var seated: bool = _by_table.has(i) and str(_by_table[i]["phase"]) == "seated"
		(guests[i] as Node3D).visible = occupied and (seated or not _by_table.has(i))
	for trip in trips.duplicate():
		_tick(trip, delta)


func _begin(table: int) -> void:
	var slot := _free_slot()
	if slot < 0:
		_by_table[table] = {"phase": "seated", "walker": null, "slot": -1}  # parking full: appears seated
		return
	var from_left := randf() < 0.5
	var x: float = SLOT_XS[slot]
	var bike := _make_bike()
	bike.position = Vector3(-EDGE_X if from_left else EDGE_X, 0, LANE_Z)
	var trip := {"table": table, "slot": slot, "bike": bike, "walker": null, "phase": "riding_in",
		"route": [Vector3(x, 0, LANE_Z), Vector3(x, 0, PARK_Z)] as Array[Vector3]}
	_used_slots[slot] = true
	_by_table[table] = trip
	trips.append(trip)


func _leave(table: int) -> void:
	var trip: Dictionary = _by_table[table]
	_by_table.erase(table)
	var phase: String = trip["phase"]
	if trip["walker"] == null and phase == "seated":
		return
	if phase == "seated" or phase == "walking_in":
		var walker: Node3D = trip["walker"]
		walker.visible = true
		var seat: Vector3 = (host.get("TABLES") as Array)[table] + SEAT_OFFSET
		walker.position = walker.position if phase == "walking_in" else seat
		trip["walker"] = walker
		trip["route"] = _walk_route(walker.position, _park_cell(trip))
		trip["phase"] = "walking_out"
	elif phase == "riding_in":
		_depart(trip)


func _tick(trip: Dictionary, delta: float) -> void:
	var phase: String = trip["phase"]
	var bike: Node3D = trip["bike"]
	var route: Array[Vector3] = trip["route"]
	if phase == "riding_in" or phase == "riding_out":
		bike.position = _follow(bike, route, BIKE_SPEED * delta, true)
		if route.size() <= 1:
			if phase == "riding_in":
				_start_walk_in(trip)
			else:
				_finish(trip)
	elif phase == "walking_in" or phase == "walking_out":
		var walker: Node3D = trip["walker"]
		walker.position = _follow(walker, route, WALK_SPEED * delta, true)
		if route.size() <= 1:
			if phase == "walking_in":
				walker.visible = false
				trip["phase"] = "seated"
			else:
				walker.queue_free()
				trip["walker"] = null
				_depart(trip)


func _start_walk_in(trip: Dictionary) -> void:
	var bike: Node3D = trip["bike"]
	bike.rotation.y = PI  # nose to the road
	var walker := _make_walker()
	add_child(walker)
	walker.position = _park_cell(trip)
	var seat: Vector3 = (host.get("TABLES") as Array)[int(trip["table"])] + SEAT_OFFSET
	trip["walker"] = walker
	trip["route"] = _walk_route(walker.position, seat)
	trip["phase"] = "walking_in"


func _depart(trip: Dictionary) -> void:
	var bike: Node3D = trip["bike"]
	var x := bike.position.x
	var right := randf() < 0.5
	trip["route"] = [Vector3(x, 0, LANE_Z), Vector3(EDGE_X if right else -EDGE_X, 0, LANE_Z)] as Array[Vector3]
	trip["phase"] = "riding_out"


func _finish(trip: Dictionary) -> void:
	(trip["bike"] as Node3D).queue_free()
	_used_slots.erase(trip["slot"])
	trips.erase(trip)


func _walk_route(from: Vector3, to: Vector3) -> Array[Vector3]:
	return FloorGrid3D.get_shared(host.get("TABLES")).path(from, to)


func _park_cell(trip: Dictionary) -> Vector3:
	return Vector3(SLOT_XS[int(trip["slot"])], 0, PARK_Z - 0.55)


func _free_slot() -> int:
	var free: Array[int] = []
	for i in range(SLOT_XS.size()):
		if not _used_slots.has(i):
			free.append(i)
	return -1 if free.is_empty() else free[randi() % free.size()]


## Moves along route (consumed in place), turning to face travel.
func _follow(node: Node3D, route: Array[Vector3], distance: float, face: bool) -> Vector3:
	var before := node.position
	var pos := StaffPathing3D.advance(before, route, distance)
	if face and pos.distance_squared_to(before) > 1e-6:
		var d := pos - before
		node.rotation.y = atan2(d.x, d.z)
	return pos


func _box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	mesh.material_override = material
	mesh.position = pos
	parent.add_child(mesh)


func _make_bike() -> Node3D:
	var bike := Node3D.new()
	add_child(bike)
	var color: String = ["a53030", "3c5e8b", "e7d5b3", "394a50", "de9e41"].pick_random()
	_box(bike, Vector3(0, 0.45, 0), Vector3(0.38, 0.3, 1.2), color)
	_box(bike, Vector3(0, 0.7, -0.15), Vector3(0.34, 0.1, 0.6), "202e37")
	_box(bike, Vector3(0, 0.95, 0.5), Vector3(0.6, 0.06, 0.08), "202e37")
	for z in [-0.5, 0.5]:
		_box(bike, Vector3(0, 0.2, z), Vector3(0.14, 0.4, 0.4), "202e37")
	return bike


func _make_walker() -> Node3D:
	var person := Node3D.new()
	_box(person, Vector3(0, 1.05, 0), Vector3(0.46, 0.65, 0.33), ["468232", "7a4841", "3c5e8b"].pick_random())
	_box(person, Vector3(0, 1.72, 0), Vector3(0.39, 0.42, 0.37), "ad7757")
	_box(person, Vector3(0, 1.97, 0), Vector3(0.48, 0.14, 0.44), "394a50")
	for side in [-0.12, 0.12]:
		_box(person, Vector3(side, 0.35, 0), Vector3(0.16, 0.7, 0.2), "202e37")
	return person
