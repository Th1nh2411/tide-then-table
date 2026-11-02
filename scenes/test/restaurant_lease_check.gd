extends Node
var failures := 0
func check(ok: bool, text_: String) -> void:
	print(("PASS " if ok else "FAIL ")+text_)
	if not ok: failures += 1
func _ready() -> void:
	call_deferred("_run")
func _room() -> RestaurantScene3D:
	var room := load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate() as RestaurantScene3D
	room.arrival_cutscenes.clear()
	add_child(room)
	room.set_process(false)
	room.set_physics_process(false)
	return room
func _renovation(room: RestaurantScene3D) -> RenovationPreview3D:
	var r := RenovationPreview3D.new()
	room.add_child(r)
	var upgrades: Array[UpgradeData] = [room.seats_upgrade,room.decor_upgrade,room.kitchen_upgrade,room.fridge_upgrade]
	var positions: Array[Vector3] = []
	positions.assign(RestaurantLayout3D.TABLES)
	r.setup(room,positions,upgrades,null)
	r.open()
	return r
func _run() -> void:
	GameState.reset()
	GameState.money = 5000
	var room := _room()
	await get_tree().process_frame
	var lane := Vector3(-5.5,0,1.8)
	check(room.guests.size()==4 and RestaurantLayout3D.TABLES[0].z>RestaurantLayout3D.GRILL_POSITION.z+2,"Initial four tables sit directly in front of the food cart")
	check(not FloorGrid3D.get_shared(room.TABLES).blocked_at(lane) and room.get_node_or_null("RestaurantLease")==null,"Unrented bay is open public pavement (no fence)")
	var paired := true
	for i in room.guests.size():
		var guest := room.guests[i] as PersonRig3D
		var partner := guest.get_meta("seating_partner") as PersonRig3D
		var delta := partner.global_position-guest.global_position
		paired = paired and absf(delta.x)>1.8 and absf(delta.z)<.01 and guest.global_basis.z.dot(partner.global_basis.z)<-.99
	check(paired,"Two guests sit opposite each other across the short width of every table")
	var r := _renovation(room)
	r.set_level(room.seats_upgrade,1)
	check(r.ghosts.get_child_count()>0 and GameState.get_upgrade_level("seats")==0,"Preview shows new floor/tables without buying the bay")
	r.cancel()
	check(GameState.money==5000 and GameState.get_upgrade_level("seats")==0,"Cancel leaves the lease and money unchanged")
	r.open();r.set_level(room.seats_upgrade,1)
	var cost := r.total_cost()
	check(r.apply() and cost==450 and GameState.money==5000-cost,"First lease upgrade charges the existing 450k once")
	check(room.guests.size()==6 and room.orders.size()==6 and room.table_plates.size()==6,"Purchase opens all six table slots immediately")
	check(FloorGrid3D.get_shared(room.TABLES).blocked_at(Vector3(-4,0,0)),"Purchase rebuilds navigation around the new tables")
	var collision := false
	for node in room.find_children("*","StaticBody3D",true,false):
		if (node as Node3D).global_position.distance_to(Vector3(-4,.8,0))<.01: collision = true
	check(collision,"Confirmed added tables already have matching physical collision")
	room.queue_free()
	await get_tree().process_frame
	room = _room()
	check(room.guests.size()==6,"Next shift loads six usable tables on the leased area")
	r = _renovation(room)
	r.set_level(room.seats_upgrade,2)
	check(r.total_cost()==1200 and r.apply(),"Second lease uses the existing 1200k upgrade")
	check(not FloorGrid3D.get_shared(room.TABLES).blocked_at(Vector3(-8.7,0,1.8)),"Second bay is reachable after purchase")
	room.queue_free()
	await get_tree().process_frame
	room = _room()
	check(room.guests.size()==8,"Reload preserves the eight-table lease layout")
	room.queue_free()
	await get_tree().process_frame
	print("RESTAURANT LEASE CHECK ","PASS" if failures==0 else "FAIL")
	get_tree().quit(1 if failures else 0)
