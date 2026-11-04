extends Node
## Staff A* around furniture + customer traffic: guests ride in on the bike
## (driver + pillion), get off at the curb, walk to the table, walk back, get
## on and ride off; walk-ins come and go on foot along the pavement.

class FakeParty:
	var guests := 2

var room: Node3D
var traffic: CustomerTraffic3D


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
	GameState.reset()
	room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	await get_tree().process_frame
	for child in room.get_children():
		if child is CustomerTraffic3D:
			traffic = child
	_ok(traffic != null, "restaurant has customer traffic")
	traffic.set_process(false)
	get_tree().paused = false
	_bike_trip()
	_walk_ins()
	_mixed()
	_omen_bike()
	get_tree().quit()


## One party of two by bike, followed phase by phase.
func _bike_trip() -> void:
	traffic.walk_in_share = 0.0
	room.orders[0] = {"phase": "waiting"}
	room.guests[0].visible = true
	traffic._process(0.0)
	_ok(traffic.trips.size() == 1 and not room.guests[0].visible, "guest arrives by bike, not at table yet")
	var trip: Dictionary = traffic.trips[0]
	var bike: Node3D = trip["bike"]
	var people := traffic._people(trip)
	var seated_on := people.size() == 2
	for p in people:
		seated_on = seated_on and p.get_parent() == bike and p.position.y > 0.2 and p.visible
	_ok(seated_on, "the guest rides the bike, the partner sits pillion")
	var rode := true
	var curb := false
	var seated := false
	for f in range(900):
		var phase: String = trip["phase"]
		if phase == "riding_in":
			rode = rode and _on_bike(trip)
		if phase == "walking_in" and not curb:
			var p0 := traffic._people(trip)[0]
			curb = p0.get_parent() == traffic and absf(p0.position.z - GuestBikes3D.PARK_Z) < 0.9 and absf(p0.position.y) < 0.01
		if phase == "seated":
			seated = true
			break
		traffic._process(0.1)
	_ok(rode, "nobody falls off while riding in")
	_ok(curb, "they get off at the curb, standing on the ground")
	_ok(seated and room.guests[0].visible, "bike parks, guests walk to the table")
	room.orders[0] = {}
	var remounted := false
	var rode_out := true
	var left := false
	for f in range(900):
		traffic._process(0.1)
		if traffic.trips.is_empty():
			left = true
			break
		var phase: String = trip["phase"]
		if phase == "mounting":
			remounted = true
		if phase == "riding_out":
			rode_out = rode_out and _on_bike(trip)
	_ok(remounted and rode_out, "they walk back, get on and ride off together")
	_ok(left and not room.guests[0].visible and traffic._used_slots.is_empty(), "the bike leaves and frees its slot")


## True when every person of the trip is seated on its bike.
func _on_bike(trip: Dictionary) -> bool:
	var people := traffic._people(trip)
	if people.is_empty():
		return false
	for p in people:
		if p.get_parent() != trip["bike"] or p.position.y < 0.2 or not p.visible:
			return false
	return true


## Four tables of walk-ins (one alone): street ends, pavement, table, out again.
func _walk_ins() -> void:
	traffic.walk_in_share = 1.0
	var starts_ok := true
	var entrances: Dictionary = {}
	for t in 4:
		var party := FakeParty.new()
		party.guests = 1 if t == 3 else 2
		room.orders[t] = {"phase": "waiting", "party": party}
		traffic._process(0.0)
		var trip: Dictionary = traffic._by_table[t]
		var p0 := traffic._people(trip)[0]
		starts_ok = starts_ok and str(trip["mode"]) == "foot" and not WalkInGuests3D.in_street(p0.position)
		starts_ok = starts_ok and traffic._people(trip).size() == party.guests
		entrances[trip["entrance"]] = true
	_ok(starts_ok, "walk-ins appear outside the street, solo party walks alone")
	var off_road := true
	var side_by_side := true
	var all_seated := false
	for f in range(1200):
		traffic._process(0.1)
		var seated := 0
		for trip in traffic.trips:
			off_road = off_road and _off_road(trip)
			var people := traffic._people(trip)
			if str(trip["phase"]) == "walking_in" and people.size() == 2 and not WalkInGuests3D.in_street(people[0].position):
				side_by_side = side_by_side and people[0].position.distance_to(people[1].position) < 1.2
			if str(trip["phase"]) == "seated":
				seated += 1
		if seated == 4:
			all_seated = true
			break
	_ok(off_road, "walk-ins keep to the pavement / road edge, never the riding lane")
	_ok(side_by_side, "couples walk side by side")
	_ok(all_seated, "every walk-in party reaches its table")
	var solo_ok: bool = not (room.guests[3].get_meta("seating_partner") as Node3D).visible and (room.guests[0].get_meta("seating_partner") as Node3D).visible
	_ok(solo_ok, "a solo party leaves the partner stool empty")
	for t in 4:
		room.orders[t] = {}
	var gone := false
	for f in range(1200):
		traffic._process(0.1)
		for trip in traffic.trips:
			off_road = off_road and _off_road(trip)
		if traffic.trips.is_empty():
			gone = true
			break
	_ok(gone and off_road, "walk-ins leave on foot the way they came")


## Walkers outside the bend stay off the asphalt (z > 8.3 is road).
func _off_road(trip: Dictionary) -> bool:
	if str(trip["mode"]) != "foot":
		return true
	for p in traffic._people(trip):
		if p.position.z > 8.35 and p.position.x < 21.5:
			return false
	return true


## Many parties, default share: every bike carries riders, all get seated.
func _mixed() -> void:
	traffic.walk_in_share = WalkInGuests3D.SHARE
	seed(7)
	var walked := 0
	var total := 0
	var riders_ok := true
	var all_reached := true
	for round_ in 6:
		for t in 4:
			room.orders[t] = {"phase": "waiting"}
		traffic._process(0.0)
		var reached: Dictionary = {}
		for trip in traffic.trips:
			total += 1
			walked += 1 if str(trip["mode"]) == "foot" else 0
		for f in range(1200):
			traffic._process(0.1)
			for trip in traffic.trips:
				if str(trip["phase"]) in ["riding_in", "riding_out"]:
					riders_ok = riders_ok and _on_bike(trip)
				if str(trip["phase"]) == "seated":
					reached[trip["table"]] = true
			if reached.size() == 4:
				break
		all_reached = all_reached and reached.size() == 4
		for t in 4:
			room.orders[t] = {}
		for f in range(1200):
			traffic._process(0.1)
			for trip in traffic.trips:
				if str(trip["phase"]) in ["riding_in", "riding_out"]:
					riders_ok = riders_ok and _on_bike(trip)
			if traffic.trips.is_empty():
				break
	print("  walk-ins %d / %d parties" % [walked, total])
	_ok(riders_ok, "every riding bike has its riders on it")
	_ok(walked > 0 and walked < total, "some parties walk, some ride")
	_ok(all_reached and traffic.trips.is_empty() and traffic._used_slots.is_empty(), "all parties reach their table and leave")


## The omen's parked bike is a prop: nobody on it.
func _omen_bike() -> void:
	var bike := room.find_child("ParkedBike", true, false) as Node3D
	_ok(bike != null and bike.find_children("*", "PersonRig3D", true, false).is_empty(), "the parked omen bike stays riderless")
