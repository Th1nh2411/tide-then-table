extends Node
## Horror-build restaurant regression: Rin walks, no menu planning or
## renovation, Cô Năm only talks, guests order from the fixed menu, beer
## comes straight from the keg, Bảo cooks the rest, and after the shift the
## street ends are the way out.

func _ready() -> void:
	call_deferred("_run")

func _check(ok: bool, text: String) -> void:
	print(("PASS " if ok else "FAIL ") + text)

func _run() -> void:
	GameState.reset()
	var room = (load("res://scenes/restaurant3d/restaurant_scene_3d.tscn") as PackedScene).instantiate()
	room.auto_open = false
	add_child(room)
	await get_tree().process_frame
	var before_walk: Vector3 = room.player.position
	Input.action_press("turn_right")
	for i: int in range(20):
		await get_tree().physics_frame
	Input.action_release("turn_right")
	_check(room.player.position.distance_to(before_walk) > 0.3, "Rin moves before shift")
	room.player.position = room.BOARD_POSITION + Vector3(0, 0, 1.0)
	room._interact()
	await get_tree().process_frame
	_check(not room.planning_panel.visible and not room.hud.menu_button.visible and not room.hud.renovate_button.visible,
		"no menu planning or renovation")
	room.player.position = room.COUNTER_POSITION + Vector3(0, 0, 1.2)
	room._interact()
	_check(not room.modal_open(), "Cô Năm only talks (no shop opens)")
	room._open_shift()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(room.shift_running and room.hud.close_button.visible, "shift opens with the Đóng sớm button")
	room._spawn_order()
	var table: int = -1
	for i: int in range(room.orders.size()):
		if not room.orders[i].is_empty():
			table = i
	_check(table >= 0 and RestaurantService3D.FIXED_MENU.dishes.has(room.orders[table]["dish"]), "guest orders from the fixed menu")
	var beer: DishData = load("res://data/dishes/bia_con_meo.tres")
	room.orders[table]["dish"] = beer
	room.player.position = room.BEER_POSITION
	room._interact()
	_check(room.carrying_table == table and bool(room.orders[table]["cooked"]), "E at the keg gives a beer tower at once")
	room.player.position = room.TABLES[table] + Vector3(0, 0, 1.2)
	room._interact()
	room._finish_meal(table)
	room._clean_table(table)
	_check(not room.dirty_tables[table], "served, paid and cleaned")
	room._end_shift()
	await get_tree().process_frame
	var ends := room.get_node("StreetEnds") as StreetEnds3D
	_check(room.shift_over and ends.can_leave() and not room.hud.sail_button.visible, "after the shift the street ends are the way out")
	get_tree().quit()
