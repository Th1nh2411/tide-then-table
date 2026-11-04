class_name CustomerTraffic3D
extends Node3D
## Guests come by motorbike (GuestBikes3D: the guest rides, the partner sits
## pillion, BikeRider3D) or on foot (WalkInGuests3D, from the street ends along
## the pavement). Bike guests get off at the curb; everyone walks (A*) to the
## table and sits (GuestSeating3D); when it empties they stand, walk back and
## ride / walk off. Reads the host's `orders` / `guests` / `TABLES` only.

## Riding lane (kept for RestaurantOmens3D's parked bike).
const LANE_Z := GuestBikes3D.LANE_Z
## Guests stroll at about their Walk clip pace (~1.0 m/s).
const WALK_SPEED := 1.1

@export var host: Node3D
## Chance a party walks instead of riding (tests pin it to 0 / 1).
@export var walk_in_share: float = WalkInGuests3D.SHARE

## One trip: mode "bike" / "foot", its people, phase, routes. Includes sitting
## down and standing up at the real stool. "walker" / "companion" are set
## only while they are on foot.
var trips: Array[Dictionary] = []
var bikes := GuestBikes3D.new()
var _by_table: Dictionary = {}
var _used_slots: Dictionary = bikes.used_slots
var _seating := GuestSeating3D.new()


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
	var slot := -1 if randf() < walk_in_share else bikes.free_slot()
	var guest := (host.get("guests") as Array)[table] as PersonRig3D
	var partner := guest.get_meta("seating_partner", null) as PersonRig3D
	var count := _party_size(table)
	if partner:
		partner.visible = count == 2
	var trip := {"table": table, "slot": slot, "mode": "bike" if slot >= 0 else "foot",
		"people": [] as Array[Node3D], "speed": WALK_SPEED}
	for i in count:
		var person := Node3D.new()
		PersonRig3D.build(person, "guest").name = "WalkerActor"
		add_child(person)
		BikeRider3D.actor(person).set_variant(guest.get_variant() if i == 0 or partner == null else partner.get_variant())
		(trip["people"] as Array[Node3D]).append(person)
	if slot >= 0:
		bikes.ride_in(self, trip, slot)
	else:
		_walk_in(trip)
	_by_table[table] = trip
	trips.append(trip)


func _walk_in(trip: Dictionary) -> void:
	var which := WalkInGuests3D.pick_entrance(randf())
	trip["entrance"] = which
	trip["speed"] = WalkInGuests3D.SPEED
	var people := _people(trip)
	for i in people.size():
		var route := WalkInGuests3D.route_in(which, i, _grid(), _approach(trip, i))
		people[i].position = route[0]
		var d := route[1] - route[0]
		people[i].rotation.y = atan2(d.x, d.z)
		trip[_route_key(i)] = route
	_on_foot(trip)
	trip["phase"] = "walking_in"


func _people(trip: Dictionary) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for person: Variant in trip["people"]:
		if is_instance_valid(person):
			result.append(person as Node3D)
	return result


func _route_key(index: int) -> String:
	return "route" if index == 0 else "companion_route"


## Sets the "walker" / "companion" keys other systems read (UncannyShift3D).
func _on_foot(trip: Dictionary) -> void:
	var people := _people(trip)
	trip["walker"] = people[0] if people.size() > 0 else null
	trip["companion"] = people[1] if people.size() > 1 else null


## From `from` to the way out: the bike's step-off spot or the street end.
func _route_out(trip: Dictionary, index: int, from: Vector3) -> Array[Vector3]:
	if str(trip["mode"]) == "foot":
		return WalkInGuests3D.route_out(int(trip["entrance"]), index, _grid(), from)
	return _grid().path(from, BikeRider3D.step_point(trip["bike"], _people(trip)[index], index))


func _exit_route(trip: Dictionary, index: int, from: Vector3) -> Array[Vector3]:
	var route: Array[Vector3] = [from, _approach(trip, index)]
	var outside := _route_out(trip, index, route[1])
	for i in range(1, outside.size()):
		route.append(outside[i])
	return route


func _leave(table: int) -> void:
	var trip: Dictionary = _by_table[table]
	_by_table.erase(table)
	var phase: String = trip["phase"]
	trip["leaving"] = true
	if phase in ["seated", "seating"]:
		_seating.stand(self, trip)
	elif phase == "walking_in":
		var people := _people(trip)
		for i in people.size():
			trip[_route_key(i)] = _route_out(trip, i, people[i].position)
		trip["phase"] = "walking_out"
	elif phase == "riding_in":
		bikes.depart(trip)


func _tick(trip: Dictionary, delta: float) -> void:
	var phase: String = trip["phase"]
	if phase in ["riding_in", "riding_out"]:
		if bikes.tick_ride(trip, delta):
			_finish(trip)
	elif phase in ["dismounting", "mounting"]:
		if bikes.tick_transfer(self, trip, delta):
			_walk_from_bike(trip)
	elif phase in ["walking_in", "walking_out"]:
		var people := _people(trip)
		var arrived := true
		for i in people.size():
			var route: Array[Vector3] = trip[_route_key(i)]
			StaffPathing3D.follow(people[i], route, float(trip["speed"]), delta)
			arrived = arrived and route.size() <= 1
		if arrived:
			if phase == "walking_in":
				_seating.begin(trip)
			elif str(trip["mode"]) == "bike":
				bikes.start_transfer(trip, "mounting")
			else:
				_finish(trip)
	elif phase == "seating":
		_seating.tick_sit(self, trip, delta)
	elif phase == "standing":
		_seating.tick_stand(self, trip, delta)


## Off the bike: on to the table.
func _walk_from_bike(trip: Dictionary) -> void:
	var people := _people(trip)
	for i in people.size():
		var route := _grid().path(people[i].position, _approach(trip, i))
		if route.size() > 1:
			var d := route[1] - route[0]
			people[i].rotation.y = atan2(d.x, d.z)
		trip[_route_key(i)] = route
	_on_foot(trip)
	trip["phase"] = "walking_in"


func _finish(trip: Dictionary) -> void:
	for person in _people(trip):
		person.queue_free()
	trip["walker"] = null
	trip["companion"] = null
	if trip.has("bike"):
		bikes.finish(trip)
	trips.erase(trip)


## 1 or 2 from the order's party (PartyOrders3D); 2 when there is none.
func _party_size(table: int) -> int:
	var party: Variant = ((host.get("orders") as Array)[table] as Dictionary).get("party")
	return clampi(int((party as Object).get("guests")), 1, 2) if party is Object else 2


func _approach(trip: Dictionary, index: int) -> Vector3:
	var table: int = trip["table"]
	return RestaurantSeating3D.approach(table, (host.get("TABLES") as Array)[table], index == 1)


func _grid() -> FloorGrid3D:
	return FloorGrid3D.get_shared(host.get("TABLES"))
