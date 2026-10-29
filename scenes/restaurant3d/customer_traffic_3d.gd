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

## One trip: bike + walker. Includes sitting down and standing up at the real stool.
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
	if phase in ["seated","seating"]:
		var walker: Node3D = trip["walker"]
		walker.visible = true
		var centre: Vector3 = (host.get("TABLES") as Array)[table]
		var actor := walker.get_node("WalkerActor") as PersonRig3D
		var progress := 1.0 if phase=="seated" else clampf((float(trip.get("seat_clock",0.0))-RestaurantSeating3D.APPROACH_SECONDS)/RestaurantSeating3D.SIT_SECONDS,0,1)
		if phase=="seated":
			walker.position = RestaurantSeating3D.seat(table,centre)
			walker.rotation.y = RestaurantSeating3D.facing(table)
		actor.sample_seating(progress)
		trip["stand_from"] = walker.position
		trip["stand_progress"] = progress
		trip["seat_clock"] = 0.0
		trip["phase"] = "standing"
	elif phase=="walking_in":
		var walker: Node3D = trip["walker"]
		trip["route"] = _walk_route(walker.position,_park_cell(trip))
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
		StaffPathing3D.follow(walker, route, WALK_SPEED, delta)
		if route.size() <= 1:
			if phase == "walking_in":
				trip["phase"] = "seating"
				trip["seat_clock"] = 0.0
				trip["seat_from"] = walker.position
				trip["seat_angle"] = walker.rotation.y
			else:
				walker.queue_free()
				trip["walker"] = null
				_depart(trip)


	elif phase=="seating":
		_tick_seating(trip,delta)
	elif phase=="standing":
		_tick_standing(trip,delta)

func _tick_seating(trip: Dictionary, delta: float) -> void:
	var walker: Node3D = trip["walker"]
	var actor := walker.get_node("WalkerActor") as PersonRig3D
	var table: int = trip["table"]
	var centre: Vector3 = (host.get("TABLES") as Array)[table]
	var front := RestaurantSeating3D.front(table,centre)
	trip["seat_clock"] = float(trip["seat_clock"])+delta
	var clock: float = trip["seat_clock"]
	if clock < RestaurantSeating3D.APPROACH_SECONDS:
		var before := walker.global_position
		var from: Vector3 = trip["seat_from"]
		walker.position = from.lerp(front,smoothstep(0,1,clock/RestaurantSeating3D.APPROACH_SECONDS))
		actor.drive_ground_motion(walker.global_position-before,delta,false)
		return
	var t := clampf((clock-RestaurantSeating3D.APPROACH_SECONDS)/RestaurantSeating3D.SIT_SECONDS,0,1)
	walker.position = front.lerp(RestaurantSeating3D.seat(table,centre),smoothstep(0,1,t))
	walker.rotation.y = lerp_angle(float(trip["seat_angle"]),RestaurantSeating3D.facing(table),smoothstep(0,1,minf(t*1.8,1)))
	actor.sample_seating(t)
	if t >= 1:
		walker.visible = false
		var guest := (host.get("guests") as Array)[table] as PersonRig3D
		guest.position = RestaurantSeating3D.seat(table,centre)
		guest.rotation.y = RestaurantSeating3D.facing(table)
		guest.set_seated(true)
		trip["phase"] = "seated"

func _tick_standing(trip: Dictionary, delta: float) -> void:
	var walker: Node3D = trip["walker"]
	var actor := walker.get_node("WalkerActor") as PersonRig3D
	var table: int = trip["table"]
	var centre: Vector3 = (host.get("TABLES") as Array)[table]
	trip["seat_clock"] = float(trip["seat_clock"])+delta
	var t := clampf(float(trip["seat_clock"])/RestaurantSeating3D.STAND_SECONDS,0,1)
	var from: Vector3 = trip["stand_from"]
	walker.position = from.lerp(RestaurantSeating3D.front(table,centre),smoothstep(0,1,t))
	if float(trip["stand_progress"])>=.999: actor.sample_seating(t,true)
	else: actor.sample_seating(float(trip["stand_progress"])*(1.0-t))
	if t >= 1:
		actor.set_seated(false)
		var approach := RestaurantSeating3D.approach(table,centre)
		var route: Array[Vector3] = [walker.position,approach]
		var outside := _walk_route(approach,_park_cell(trip))
		for i in range(1,outside.size()): route.append(outside[i])
		trip["route"] = route
		trip["phase"] = "walking_out"


func _start_walk_in(trip: Dictionary) -> void:
	var bike: Node3D = trip["bike"]
	bike.rotation.y = PI  # nose to the road
	var walker := _make_walker()
	add_child(walker)
	var seated_guest: Node3D = (host.get("guests") as Array)[int(trip["table"])]
	if seated_guest.has_method("get_variant"):
		walker.get_node("WalkerActor").call("set_variant", seated_guest.call("get_variant"))
	walker.position = _park_cell(trip)
	var table: int = trip["table"]
	var seat := RestaurantSeating3D.approach(table,(host.get("TABLES") as Array)[table])
	trip["walker"] = walker
	trip["route"] = _walk_route(walker.position, seat)
	var route: Array[Vector3] = trip["route"]
	if route.size() > 1:
		var direction := route[1]-walker.position
		walker.rotation.y = atan2(direction.x,direction.z)
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


func _make_bike() -> Node3D:
	return RestaurantBatchVisuals.add(self, "motorbike", Vector3.ZERO)


func _make_walker() -> Node3D:
	var person := Node3D.new()
	var actor := PersonRig3D.build(person, "guest")
	actor.name = "WalkerActor"
	return person
