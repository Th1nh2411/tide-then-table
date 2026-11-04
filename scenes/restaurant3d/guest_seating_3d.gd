class_name GuestSeating3D
extends RefCounted
## CustomerTraffic3D's sitting down / standing up at the real stool: walkers
## step to the stool, play the sit clip, then hand over to the host's seated
## guest models; leaving plays it backwards and routes them out.


func _centre(traffic: CustomerTraffic3D, table: int) -> Vector3:
	return (traffic.host.get("TABLES") as Array)[table]


## Walked up to the table: start sitting down.
func begin(trip: Dictionary) -> void:
	trip["phase"] = "seating"
	trip["seat_clock"] = 0.0
	var people: Array = trip["people"]
	for i in people.size():
		var person := people[i] as Node3D
		trip["seat_from_%d" % i] = person.position
		trip["seat_angle_%d" % i] = person.rotation.y


## The table emptied while seated / sitting down: stand up (or just turn back).
func stand(traffic: CustomerTraffic3D, trip: Dictionary) -> void:
	var table: int = trip["table"]
	var centre := _centre(traffic, table)
	var phase: String = trip["phase"]
	var progress := 1.0 if phase == "seated" else clampf((float(trip.get("seat_clock", 0)) - RestaurantSeating3D.APPROACH_SECONDS) / RestaurantSeating3D.SIT_SECONDS, 0, 1)
	var people := traffic._people(trip)
	for i in people.size():
		var walker := people[i]
		var actor := BikeRider3D.actor(walker)
		walker.visible = true
		if phase == "seating" and progress <= 0:
			actor.set_seated(false)
			trip[traffic._route_key(i)] = traffic._exit_route(trip, i, walker.position)
			continue
		if phase == "seated":
			walker.position = RestaurantSeating3D.seat(table, centre, i == 1)
			walker.rotation.y = RestaurantSeating3D.facing(table, i == 1)
		actor.sample_seating(progress)
		trip["stand_from_%d" % i] = walker.position
	trip["stand_progress"] = progress
	trip["seat_clock"] = 0.0
	trip["phase"] = "walking_out" if phase == "seating" and progress <= 0 else "standing"


func tick_sit(traffic: CustomerTraffic3D, trip: Dictionary, delta: float) -> void:
	var table: int = trip["table"]
	var centre := _centre(traffic, table)
	trip["seat_clock"] = float(trip["seat_clock"]) + delta
	var clock: float = trip["seat_clock"]
	var t := clampf((clock - RestaurantSeating3D.APPROACH_SECONDS) / RestaurantSeating3D.SIT_SECONDS, 0, 1)
	var people := traffic._people(trip)
	for i in people.size():
		var walker := people[i]
		var actor := BikeRider3D.actor(walker)
		var front := RestaurantSeating3D.front(table, centre, i == 1)
		if clock < RestaurantSeating3D.APPROACH_SECONDS:
			var before := walker.global_position
			var from: Vector3 = trip["seat_from_%d" % i]
			walker.position = from.lerp(front, smoothstep(0, 1, clock / RestaurantSeating3D.APPROACH_SECONDS))
			var moved := walker.global_position - before
			if moved.length_squared() > .000001:
				walker.rotation.y = lerp_angle(walker.rotation.y, atan2(moved.x, moved.z), 1.0 - exp(-14 * delta))
			trip["seat_angle_%d" % i] = walker.rotation.y
			actor.drive_ground_motion(moved, delta, false)
		else:
			walker.position = front.lerp(RestaurantSeating3D.seat(table, centre, i == 1), smoothstep(0, 1, t))
			walker.rotation.y = lerp_angle(float(trip["seat_angle_%d" % i]), RestaurantSeating3D.facing(table, i == 1), smoothstep(0, 1, minf(t * 1.8, 1)))
			actor.sample_seating(t)
	if t >= 1:
		for person in people:
			person.visible = false
		var guest := (traffic.host.get("guests") as Array)[table] as PersonRig3D
		guest.set_seated(true)
		guest.visible = true
		trip["phase"] = "seated"


func tick_stand(traffic: CustomerTraffic3D, trip: Dictionary, delta: float) -> void:
	var table: int = trip["table"]
	var centre := _centre(traffic, table)
	trip["seat_clock"] = float(trip["seat_clock"]) + delta
	var t := clampf(float(trip["seat_clock"]) / RestaurantSeating3D.STAND_SECONDS, 0, 1)
	var people := traffic._people(trip)
	for i in people.size():
		var walker := people[i]
		var actor := BikeRider3D.actor(walker)
		var from: Vector3 = trip["stand_from_%d" % i]
		walker.position = from.lerp(RestaurantSeating3D.front(table, centre, i == 1), smoothstep(0, 1, t))
		if float(trip["stand_progress"]) >= .999:
			actor.sample_seating(t, true)
		else:
			actor.sample_seating(float(trip["stand_progress"]) * (1.0 - t))
		if t >= 1:
			actor.set_seated(false)
			trip[traffic._route_key(i)] = traffic._exit_route(trip, i, walker.position)
	if t >= 1:
		trip["phase"] = "walking_out"
