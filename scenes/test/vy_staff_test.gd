extends Node
## Vy, Bảo's friend, works every shift (VyStaff3D): absent before the shift
## and at night, walks in when it opens, carries a ready plate to its table,
## wipes a dirty table, never takes the plate Rin took (or the other way
## round), talks by day from data (VyTalk3D). Run with F6.

const RESTAURANT := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const VILLAGE := "res://scenes/village3d/village_scene_3d.tscn"
const STEP := 0.1

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	var room := (load(RESTAURANT) as PackedScene).instantiate() as RestaurantScene3D
	room.auto_open = false
	add_child(room)
	await get_tree().process_frame
	var vy: VyStaff3D = room.vy
	_check("before the shift Vy is not on the street", vy != null and not vy.present())
	room._open_shift()
	room.player.position = Vector3(15, 0, 4)  # out of her way
	_check("she walks in and settles", _run_until(vy, func() -> bool: return vy.state == "idle") and vy.present())
	_check("she is solid (person blocker on)", vy.rig.has_node("PersonBlocker"))
	# A ready plate: she takes it to its table.
	_seat(room, 2, true)
	_check("she carries the ready plate to its table",
		_run_until(vy, func() -> bool: return str(room.orders[2].get("phase", "")) == "eating"))
	_check("the plate never showed as Rin's", room.carrying_table == -1)
	# Two ready plates: whichever she claims, Rin gets the other one.
	_seat(room, 0, true)
	_seat(room, 1, true)
	_run_until(vy, func() -> bool: return bool(room.orders[0].get("staff", false)) or bool(room.orders[1].get("staff", false)))
	var hers := 0 if bool(room.orders[0].get("staff", false)) else 1
	room.player.position = RestaurantLayout3D.PASS_POSITION + Vector3(0.3, 0, 0.8)
	room._interact()
	_check("Rin takes the other plate, not hers", room.carrying_table == 1 - hers)
	room._sync_food_visuals()
	_check("her plate is off the bench", not room.ready_plates[hers].visible)
	room._interact()
	_check("with only her plate left Rin gets nothing", room.carrying_table == 1 - hers and not room._pickup_ready())
	room.player.position = Vector3(15, 0, 4)
	_check("she delivers hers", _run_until(vy, func() -> bool: return str(room.orders[hers].get("phase", "")) == "eating"))
	_check("Rin still holds his", room.carrying_table == 1 - hers and not bool(room.orders[1 - hers].get("staff", false)))
	# Rin's plate is never hers: tick a while, she does not touch it.
	_run_until(vy, func() -> bool: return bool(room.orders[1 - hers].get("staff", false)), 60)
	_check("she never claims Rin's plate", not bool(room.orders[1 - hers].get("staff", false)))
	# A dirty table: she wipes it.
	room.carrying_table = -1
	room.orders[1 - hers] = {}
	room.dirty_tables[3] = true
	_check("she wipes a dirty table", _run_until(vy, func() -> bool: return not room.dirty_tables[3]))
	_talk(room, vy)
	room._end_shift()
	_check("after the shift she walks off", _run_until(vy, func() -> bool: return not vy.present()))
	room.queue_free()
	await get_tree().process_frame
	await _village()
	GameState.reset()
	print("VY STAFF TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


## Talk: E facing her gives a line from data; same day + count = same line.
func _talk(room: RestaurantScene3D, vy: VyStaff3D) -> void:
	room.player.position = vy.rig.position + Vector3(0, 0, 1.0)
	room.demo_camera.global_position = room.player.position + Vector3(0, 1.55, 0)
	room.demo_camera.look_at(vy.rig.position + Vector3(0, 1.4, 0))
	_check("Rin can talk to her when he looks at her", vy.talk.can_talk(room.player.position, room.demo_camera))
	var first := VyTalk3D.line_for(1, 0)
	_check("lines come from data, said by Vy", first.begins_with("Vy: ") and first.contains("Bảo"))
	_check("same day, same line", VyTalk3D.line_for(3, 1) == VyTalk3D.line_for(3, 1) and VyTalk3D.line_for(3, 0) != VyTalk3D.line_for(4, 0))
	_check("late days start with an uneasy line", VyTalk3D.line_for(VyTalk3D.LATE_DAY, 0) == VyTalk3D.LATE.line(0))
	vy.talk.talks = 0
	room._interact()
	_check("E on her speaks the day's line", vy.talk.talks == 1)
	room.demo_camera.look_at(vy.rig.position + Vector3(0, 1.4, 4.0))
	_check("looking away: no talk", not vy.talk.can_talk(room.player.position, room.demo_camera))


## The village map: absent at dawn, there once Rin walks into the street, absent at night.
func _village() -> void:
	GameState.reset()
	var village := (load(VILLAGE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await get_tree().process_frame
	village.waking = false
	_check("dawn: Vy is not in the village", not village.vy.present())
	village.player.position = Vector3(10, 0, 4)
	await get_tree().process_frame
	await get_tree().process_frame
	_check("Rin reaches the street: the shift opens and Vy comes", village.shift_running and village.vy.present())
	village.queue_free()
	await get_tree().process_frame
	GameState.set_flag(VillageDay3D.NIGHT_FLAG)
	village = (load(VILLAGE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await get_tree().process_frame
	await get_tree().process_frame
	_check("night (back from the sea): Vy is gone", not village.vy.present())
	village.queue_free()
	await get_tree().process_frame


## Guests at `table` with a cooked dish waiting.
func _seat(room: RestaurantScene3D, table: int, cooked: bool) -> void:
	var dish: DishData = RestaurantService3D.FIXED_MENU.dishes[0]
	room.orders[table] = {"dish": dish, "patience": 999.0, "initial_patience": 999.0,
		"cooked": cooked, "party": PartyOrders3D.start(room.tuning, RestaurantService3D.FIXED_MENU.dishes)}
	room.dirty_tables[table] = false


func _run_until(vy: VyStaff3D, done: Callable, steps := 900) -> bool:
	for i in range(steps):
		vy.tick(STEP)
		if done.call():
			return true
	return false


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
