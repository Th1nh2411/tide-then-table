extends Node
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
	var traffic: CustomerTraffic3D
	for child in room.get_children():
		if child is CustomerTraffic3D: traffic = child
	traffic.set_process(false)
	traffic.walk_in_share = 0.0  # parking release is checked below
	await get_tree().process_frame
	room.orders[0] = {"phase":"waiting"}
	traffic._process(.016)
	var saw_sit := false
	for frame in 1400:
		traffic._process(.05)
		if traffic.trips.is_empty(): break
		var phase: String = traffic.trips[0]["phase"]
		if phase=="seating": saw_sit = true
		if phase=="seated": break
	var trip: Dictionary = traffic.trips[0]
	check(traffic._people(trip).size()==2 and not (trip["companion"] as Node3D).visible,"Both arriving guests complete sitting before the table model is shown")
	var guest := room.guests[0] as PersonRig3D
	check(saw_sit and trip["phase"]=="seated" and guest._seated and guest.visible,"Arrival includes sit-down before seated guest becomes visible")
	check(guest.position.is_equal_approx(RestaurantSeating3D.seat(0,RestaurantLayout3D.TABLES[0])) and is_equal_approx(guest.rotation.y,RestaurantSeating3D.facing(0)),"Guest occupies and faces the real stool/table")
	room.orders[0] = {}
	traffic._process(.05)
	check(trip["phase"]=="standing" and not guest.visible and (trip["walker"] as Node3D).visible,"Guest stands up without a duplicate seated model")
	for frame in 1400:
		traffic._process(.05)
		if traffic.trips.is_empty(): break
	check(traffic.trips.is_empty() and traffic._used_slots.is_empty(),"Stand-up, walk-out and motorbike departure release parking")
	# Cancellation during sit-down must reverse from the current pose and still clean up.
	room.orders[1] = {"phase":"waiting"}
	traffic._process(.016)
	for frame in 1400:
		traffic._process(.05)
		if traffic.trips[0]["phase"]=="seating" and float(traffic.trips[0].get("seat_clock",0))>.65: break
	room.orders[1] = {}
	traffic._process(.05)
	for frame in 1400:
		traffic._process(.05)
		if traffic.trips.is_empty(): break
	check(traffic.trips.is_empty() and traffic._used_slots.is_empty() and not room.guests[1].visible,"Cancelling during sit-down leaves no visible duplicate or occupied slot")
	room.orders[2] = {"phase":"waiting"}
	traffic._process(.016)
	for frame in 1400:
		traffic._process(.05)
		if traffic.trips[0]["phase"]=="seating" and float(traffic.trips[0].get("seat_clock",0))>.05: break
	room.orders[2] = {}
	traffic._process(.01)
	check(traffic.trips[0]["phase"]=="walking_out","Cancellation before bending down turns back directly instead of stepping toward the chair")
	for frame in 1400:
		traffic._process(.05)
		if traffic.trips.is_empty(): break
	check(traffic.trips.is_empty() and traffic._used_slots.is_empty(),"Early approach cancellation also releases parking")
	room.queue_free()
	await get_tree().process_frame
	print("RESTAURANT SEATING CHECK ","PASS" if failures==0 else "FAIL")
	get_tree().quit(1 if failures else 0)
