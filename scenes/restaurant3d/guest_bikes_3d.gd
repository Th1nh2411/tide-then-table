class_name GuestBikes3D
extends RefCounted
## CustomerTraffic3D's motorbikes: parking slots, riding in with the guests on
## board, getting off at the curb (BikeRider3D), getting back on, riding off.

const PARK_Z := 8.65
const LANE_Z := 9.8
const SLOT_XS: Array[float] = [-8.0, -4.0, 0.0, 4.0, 8.0, 12.0]
const EDGE_X := 26.0
## Bikes come and go this far west: deep in the village's west fog (WorldEdgeLoop3D).
const WEST_EDGE_X := -40.0
const SPEED := 5.0

## Slot index -> true while a bike holds it.
var used_slots: Dictionary = {}


## A small soft oval blob under the wheels (the model faces +Z).
static func ground(bike: Node3D) -> void:
	ContactShadow3D.attach(bike, 0.26, 3.2, 0.4)


func free_slot() -> int:
	var free: Array[int] = []
	for i in range(SLOT_XS.size()):
		if not used_slots.has(i):
			free.append(i)
	return -1 if free.is_empty() else free[randi() % free.size()]


## A bike from a street end with the trip's people on it, heading for `slot`.
func ride_in(traffic: CustomerTraffic3D, trip: Dictionary, slot: int) -> void:
	var bike := Node3D.new()  # holder: riders become its children
	bike.name = "GuestBike"
	traffic.add_child(bike)
	RestaurantBatchVisuals.add(bike, "motorbike", Vector3.ZERO)
	ground(bike)
	bike.position = Vector3(WEST_EDGE_X if randf() < 0.5 else EDGE_X, 0, LANE_Z)
	bike.rotation.y = PI * 0.5 if bike.position.x < 0.0 else -PI * 0.5
	trip["bike"] = bike
	trip["route"] = [Vector3(SLOT_XS[slot], 0, LANE_Z), Vector3(SLOT_XS[slot], 0, PARK_Z)] as Array[Vector3]
	trip["phase"] = "riding_in"
	used_slots[slot] = true
	var people := traffic._people(trip)
	for i in people.size():
		BikeRider3D.mount(people[i], bike, i)


## Riding in / out; true when the ride is over.
func tick_ride(trip: Dictionary, delta: float) -> bool:
	var bike: Node3D = trip["bike"]
	var route: Array[Vector3] = trip["route"]
	var before := bike.position
	bike.position = StaffPathing3D.advance(before, route, SPEED * delta)
	var d := bike.position - before
	if d.length_squared() > 1e-6:
		bike.rotation.y = atan2(d.x, d.z)
	if route.size() > 1:
		return false
	if str(trip["phase"]) == "riding_in":
		bike.rotation.y = PI  # parked nose to the shop
		start_transfer(trip, "dismounting")
		return false
	return true


func depart(trip: Dictionary) -> void:
	var x := (trip["bike"] as Node3D).position.x
	var to := EDGE_X if randf() < 0.5 else WEST_EDGE_X
	trip["route"] = [Vector3(x, 0, LANE_Z), Vector3(to, 0, LANE_Z)] as Array[Vector3]
	trip["phase"] = "riding_out"


## Getting off (just parked) or on (walked back) the bike.
func start_transfer(trip: Dictionary, phase: String) -> void:
	trip["walker"] = null
	trip["companion"] = null
	var people: Array = trip["people"]
	for i in people.size():
		var person := people[i] as Node3D
		BikeRider3D.attach(person, trip["bike"])
		trip["from_%d" % i] = person.position
		trip["from_yaw_%d" % i] = person.rotation.y
	trip["clock"] = 0.0
	trip["phase"] = phase


## Steps the get-off / get-on; true once the people stand beside the bike.
func tick_transfer(traffic: CustomerTraffic3D, trip: Dictionary, delta: float) -> bool:
	trip["clock"] = float(trip["clock"]) + delta
	var t := clampf(float(trip["clock"]) / BikeRider3D.SECONDS, 0, 1)
	var people := traffic._people(trip)
	var getting_on := str(trip["phase"]) == "mounting"
	for i in people.size():
		if getting_on:
			BikeRider3D.sample_on(people[i], i, trip["from_%d" % i], float(trip["from_yaw_%d" % i]), t)
		else:
			BikeRider3D.sample_off(people[i], i, t)
	if t < 1.0:
		return false
	if getting_on:
		depart(trip)
		return false
	if trip.get("leaving", false):
		start_transfer(trip, "mounting")  # the table emptied while parking
		return false
	for person in people:
		BikeRider3D.detach(person, traffic)
	return true


func finish(trip: Dictionary) -> void:
	(trip["bike"] as Node3D).queue_free()  # riders go with it
	used_slots.erase(trip["slot"])
