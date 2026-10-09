extends Node
## Throwaway: plays the first 3 days through the real scene flow and saves
## screenshots (scratchpad). Lives on the root so scene changes keep it.

const OUT := "/private/tmp/claude-501/-Users-nguyenthinh-WorkSpace-tide-then-table/324b2a73-e82b-4399-b661-0d57ba1fb56b/scratchpad/play/"

var _n: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OUT)
	_run()


func _run() -> void:
	await _wait(1.0)
	await _shot("menu")
	(get_tree().current_scene.get("_new_game_button") as Button).pressed.emit()
	await _wait(2.0)
	await _shot("intro_a")
	await _through_cutscene("intro")
	for day in 3:
		await _until_scene("sea_scene")
		await _wait(1.5)
		await _shot("d%d_sea_start" % (day + 1))
		await _fish(3, day)
		await _shot("d%d_sea_after_fishing" % (day + 1))
		var sea := get_tree().current_scene
		sea.call("_end_sea_day", false)
		await _wait(2.0)
		if get_tree().paused:
			await _shot("d%d_trip_end_cutscene" % (day + 1))
			await _through_cutscene("d%d_trip_end" % (day + 1))
		await _until_scene("rest_scene")
		await _wait(1.0)
		await _shot("d%d_rest" % (day + 1))
		(get_tree().current_scene.get("_wake_button") as Button).pressed.emit()
		await _until_scene("restaurant_scene")
		await _wait(1.5)
		if get_tree().paused:
			await _shot("d%d_arrival_cutscene" % (day + 1))
			await _through_cutscene("d%d_arrival" % (day + 1))
		await _wait(0.5)
		await _shot("d%d_restaurant_arrive" % (day + 1))
		await _restaurant_day(day + 1)
	await _shot("end")
	get_tree().quit()


func _restaurant_day(day: int) -> void:
	var rest := get_tree().current_scene
	var panel: Control = rest.get("_menu_panel")
	panel.show()
	await _wait(0.4)
	(panel.get_node("%AutoButton") as Button).pressed.emit()
	await _wait(0.4)
	await _shot("d%d_menu_panel" % day)
	(panel.get_node("%OpenButton") as Button).pressed.emit()
	await _wait(0.5)
	var t := 0.0
	var shots := 0
	while t < 45.0:
		await _waiter_step(rest)
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 12.0 + shots * 14.0 and shots < 3:
			await _shot("d%d_service_%d" % [day, shots])
			shots += 1
	rest.call("_end_shift", "Hết giờ bán!")
	var guard := 0.0
	while not bool(rest.get("_shift_over")) and guard < 40.0:
		await _waiter_step(rest)
		await get_tree().process_frame
		guard += get_process_delta_time()
	await _wait(0.5)
	await _shot("d%d_summary" % day)
	(rest.get_node("%NextDayButton") as Button).pressed.emit()
	await _wait(1.0)
	if get_tree().paused:
		await _through_cutscene("d%d_after_shift" % day)
	await _shot("d%d_evening" % day)
	if day == 3:
		var phone := rest.get_node("PhoneApp") as PhoneApp
		phone.open()
		phone._show_tab(PhoneApp.STAFF_TAB)
		await _wait(0.3)
		await _shot("d3_phone_staff")
		phone._show_tab(0)
		await _wait(0.3)
		await _shot("d3_phone_storage")
		phone.close()
		return
	(rest.get("_sail_button") as Button).pressed.emit()


# --- sea ------------------------------------------------------------------

func _fish(count: int, day: int) -> void:
	var sea := get_tree().current_scene
	var fishing := sea.get_node("FishingController") as FishingController
	var boat := sea.get_node("Boat") as Boat
	var caught := 0
	for child in fishing.spawner.get_children():
		var spot := child as FishingSpot
		if spot == null or spot.casts_left <= 0 or caught >= count:
			continue
		boat.global_position = spot.global_position
		boat.speed = 0.0
		await _wait(0.6)
		if caught == 0 and day == 0:
			await _shot("d1_sea_at_spot")
		fishing.spawner.fishing_requested.emit(spot)
		await _wait(0.8)
		if caught == 0:
			await _shot("d%d_minigame" % (day + 1))
		while fishing.minigame.is_running():
			var game: MinigameBase = fishing.minigame.get("_game")
			if game:
				game._finish(true, true)
			await _wait(0.3)
		caught += 1
		await _wait(0.5)


# --- restaurant waiter bot (same rules as the balance sim) -----------------

var _busy: bool = false


func _waiter_step(rest: Node) -> void:
	if _busy or get_tree().paused:
		return
	_busy = true
	var cm: CustomerManager = rest.get("_customers")
	var room: StreetRoom = rest.get("_room")
	var rin: RinChef = rest.get("_rin")
	var kitchen: KitchenStation = rest.get("_kitchen")
	var stall: MarketStall = rest.get("_stall")
	var overlay: CookingOverlay = rest.get_node("CookingOverlay")
	if rin.carried:
		var seat := -1
		for order in cm.waiting:
			if order.dish == rin.carried.dish and order.visit == rin.carried.visit:
				seat = order.seat
				break
		if seat < 0:
			await _act(rin, room, kitchen, room.grid.cells_of("B")[0])
		else:
			await _act(rin, room, kitchen, room.tables[seat]["table"], room.table_stand_cell(seat, rin.cell()))
	elif not cm.shelf.next_delivery(cm.waiting).is_empty():
		var plate: DishShelf.Plate = cm.shelf.next_delivery(cm.waiting)["plate"]
		await _act(rin, room, kitchen, room.pass_cells()[cm.shelf.slots.find(plate)])
	elif kitchen.next_order(false):
		await _act(rin, room, kitchen, room.grill_cell())
		await _minigame(kitchen, overlay)
	elif kitchen.next_order(true):
		var dish := kitchen.next_order(true).dish
		if stall.stock.portions(dish) == 0:
			await _shop(rin, room, stall, dish)
		await _act(rin, room, kitchen, room.grid.cells_of("U")[0])
		await _minigame(kitchen, overlay)
	else:
		var short: DishData = null
		for order in cm.waiting:
			if order.dish.is_market_dish() and not order.dish.instant_serve and stall.stock.portions(order.dish) == 0:
				short = order.dish
		if short:
			await _shop(rin, room, stall, short)
		elif not room.dining.dirty_seats().is_empty():
			var seat: int = room.dining.dirty_seats()[0]
			await _act(rin, room, kitchen, room.tables[seat]["table"], room.table_stand_cell(seat, rin.cell()))
			while kitchen.busy:
				await get_tree().process_frame
	_busy = false


func _act(rin: RinChef, room: StreetRoom, kitchen: KitchenStation, cell: Vector2i, stand: Vector2i = Vector2i(-1, -1)) -> void:
	if stand.x < 0:
		stand = room.grid.stand_cell(cell, rin.cell())
	await rin.walk_and_wait(room.grid.path(rin.cell(), stand))
	kitchen.interact(cell)


func _shop(rin: RinChef, room: StreetRoom, stall: MarketStall, dish: DishData) -> void:
	await rin.walk_and_wait(room.grid.path(rin.cell(), Vector2i(32, 7)))
	stall.buy(dish, GameState.money >= dish.buy_cost(true) + 200)
	var fridge: Vector2i = room.grid.cells_of("F")[0]
	await rin.walk_and_wait(room.grid.path(rin.cell(), room.grid.stand_cell(fridge, rin.cell())))
	stall.store_at(fridge)


func _minigame(kitchen: KitchenStation, overlay: CookingOverlay) -> void:
	while kitchen.busy and not overlay.is_running():
		await get_tree().process_frame
	await _wait(2.5)
	var game: CookingGameBase = overlay.get("_game")
	if game:
		game._finish(CookingGameBase.Result.PERFECT if _rng.randf() < 0.4 else CookingGameBase.Result.OK)
	while kitchen.busy:
		await get_tree().process_frame


# --- helpers ----------------------------------------------------------------

func _through_cutscene(label: String) -> void:
	var t := 0.0
	var shot := false
	while get_tree().paused and t < 60.0:
		await _wait(0.6)
		t += 0.6
		if not shot and t > 6.0:
			shot = true
			await _shot(label + "_mid")
		for pressed: bool in [true, false]:
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = pressed
			Input.parse_input_event(ev)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_1
		key.pressed = true
		Input.parse_input_event(key)
	await _wait(0.8)


func _until_scene(name: String) -> void:
	var t := 0.0
	while (get_tree().current_scene == null or not get_tree().current_scene.scene_file_path.contains(name)) and t < 30.0:
		await _wait(0.2)
		t += 0.2
	await _wait(0.6)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(OUT + "%02d_%s.png" % [_n, label])
	print("SHOT %02d %s day=%d money=%d" % [_n, label, GameState.day, GameState.money])


func _button(text: String) -> Button:
	for node in get_tree().current_scene.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node
	return null


func _button_containing(text: String) -> Button:
	for node in get_tree().current_scene.find_children("*", "Button", true, false):
		if (node as Button).text.contains(text):
			return node
	return null
