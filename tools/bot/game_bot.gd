extends Node
## Whole-game bot (tools/run_bot.sh): plays from New Game to the ending
## through the real scenes, to measure pacing / balance and catch softlocks. Sea: teleports between real spots but burns the oil the trip
## would cost, real catch rolls, 80% skill, unloads at the dock when the hold
## is nearly full. Restaurant: waiter bot, whole shift. Evening: buys upgrades
## by policy. Prints one line per day + an estimate of human play time, and
## "STUCK ..." / "SAVE MISMATCH ..." lines when something goes wrong.
## Env: POLICY=story|balanced (upgrade order), SPEED (time scale, default 6).

const POLICY_STORY: Array[String] = ["boat:1", "boat:2", "rod:1", "lamp:1", "kitchen:1", "seats:1", "fridge:1",
	"rod:2", "lamp:2", "kitchen:2", "seats:2", "decor:1", "fridge:2", "decor:2"]
const POLICY_BALANCED: Array[String] = ["rod:1", "lamp:1", "boat:1", "kitchen:1", "seats:1", "boat:2", "fridge:1",
	"rod:2", "lamp:2", "kitchen:2", "seats:2", "decor:1", "fridge:2", "decor:2"]
const MAX_DAYS := 16
const SKILL := 0.8
const MINIGAME_SECONDS := 12.0  # bite wait + fight, human
const RESERVE := 300  # money kept for groceries

var policy: Array[String] = POLICY_STORY
var _rng := RandomNumberGenerator.new()
var _upgrades: Dictionary = {}
var _human_seconds: float = 0.0
var _day_line: Dictionary = {}
var _cutscenes: Array[String] = []
var _min_money: int = 1 << 30
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	if OS.get_environment("POLICY") == "balanced":
		policy = POLICY_BALANCED
	for path in DirAccess.get_files_at("res://data/upgrades"):
		if path.ends_with(".tres"):
			var up: UpgradeData = load("res://data/upgrades/" + path)
			_upgrades[up.id] = up
	var speed := OS.get_environment("SPEED")
	Engine.time_scale = float(speed) if speed != "" else 6.0
	_run()


func _run() -> void:
	await _wait(1.0)
	var new_game := get_tree().current_scene.get("_new_game_button") as Button
	new_game.pressed.emit()
	if get_tree().current_scene.scene_file_path.contains("main_menu"):
		await _wait(0.3)
		new_game.pressed.emit()
	await _wait(2.0)
	await _through_cutscene("intro_call")
	_human_seconds += 30.0
	while GameState.day <= MAX_DAYS:
		_day_line = {"day": GameState.day}
		if not await _until_scene("sea_scene"):
			return
		await _wait(1.0)
		_roundtrip("sea start d%d" % GameState.day)
		if await _sea_night():
			_report_end("ENDING")
			return
		if not await _until_scene("rest_scene"):
			return
		await _wait(0.5)
		_human_seconds += 8.0
		_roundtrip("rest d%d" % GameState.day)
		(get_tree().current_scene.get("_wake_button") as Button).pressed.emit()
		if not await _until_scene("restaurant_scene"):
			return
		await _wait(1.0)
		await _through_cutscene("arrival d%d" % GameState.day)
		await _restaurant_day()
		_print_day()
	_report_end("NO ENDING by day %d" % MAX_DAYS)


func _report_end(what: String) -> void:
	print("RUN %s | policy %s | day %d | money %dk | min money %dk | ~%.0f min human time | cutscenes: %s" % [
		what, "story" if policy == POLICY_STORY else "balanced", GameState.day, GameState.money, _min_money,
		_human_seconds / 60.0, ", ".join(_cutscenes)])
	get_tree().quit()


func _print_day() -> void:
	var d := _day_line
	print("DAY %d | thuyền%d cần%d đèn%d bếp%d bàn%d | cá %d (dỡ %d, sáng %d) | biển ~%.1f ph | phục vụ %d bỏ %d | ca %+dk | mua %s | tiền %dk | stage %d | staff %s | tổng ~%.0f ph" % [
		d["day"], _lvl("boat"), _lvl("rod"), _lvl("lamp"), _lvl("kitchen"), _lvl("seats"),
		d.get("fish", 0), d.get("docks", 0), d.get("glow", 0), float(d.get("sea_s", 0.0)) / 60.0,
		d.get("served", 0), d.get("angry", 0), d.get("shift_money", 0), str(d.get("bought", [])),
		GameState.money, Story.stage(), str(GameState.staff.get("hired", [])), _human_seconds / 60.0])


func _lvl(id: String) -> int:
	return GameState.get_upgrade_level(id)


# --- sea --------------------------------------------------------------------

## Returns true if the night ended in the whirlpool.
func _sea_night() -> bool:
	var sea := get_tree().current_scene
	await _through_cutscene("sea start d%d" % GameState.day)
	var fishing := sea.get_node("FishingController") as FishingController
	var boat := sea.get_node("Boat") as Boat
	var oil := sea.get_node("LampOil") as LampOil
	var hold_manager := sea.get_node("HoldManager") as HoldManager
	var dock: Vector2 = (sea.get_node("Dock") as Node2D).global_position
	var limit := (sea.find_children("*", "BoatRange", true, false)[0] as BoatRange).limit_for(boat.boat_data)
	var speed := boat.boat_data.max_speed * 0.8 / 1.2
	var burn := oil.burn_per_second
	var sea_s := 0.0
	var fish := 0
	var docks := 0
	var glow := 0
	var pos := boat.global_position
	if Story.is_fog_open():
		var fog := sea.get_node("FogArea") as FogArea
		var target := fog.get_whirlpool_position()
		print("SEA d%d: fog open, boat lvl %d, whirlpool y %.0f, range limit y %.0f" % [GameState.day, _lvl("boat"), target.y, limit])
		if target.y >= limit - 30.0:
			var t := pos.distance_to(target) / speed
			_human_seconds += t + 20.0
			boat.global_position = target
			await _until_scene("ending_scene")
			return true
	var spots: Array[FishingSpot] = []
	for child in fishing.spawner.get_children():
		var spot := child as FishingSpot
		if spot and spot.global_position.y >= limit:
			spots.append(spot)
	var hold_cells := boat.boat_data.hold_size.x * boat.boat_data.hold_size.y
	while true:
		var best: FishingSpot = null
		var best_t := INF
		for spot in spots:
			if not is_instance_valid(spot) or spot.casts_left <= 0:
				continue
			var t := pos.distance_to(spot.global_position) / speed
			var home := spot.global_position.distance_to(dock) / speed
			if (t + home) * burn + 2.0 * spot.casts_left + 4.0 < oil.amount and t < best_t:
				best_t = t
				best = spot
		if best == null:
			break
		oil.spend(best_t * burn)
		sea_s += best_t
		pos = best.global_position
		boat.global_position = pos
		boat.speed = 0.0
		await _wait(0.2)
		while is_instance_valid(best) and best.casts_left > 0 and oil.amount > 2.0:
			if hold_manager.hold.fill_fraction() * hold_cells > hold_cells - 6:
				var to_dock := pos.distance_to(dock) / speed
				oil.spend(to_dock * burn * 2.0)
				sea_s += to_dock * 2.0 + 5.0
				GameState.unload_catch(hold_manager.take_all())
				docks += 1
			var before := hold_manager.hold.items.size()
			fishing.spawner.fishing_requested.emit(best)
			await _wait(0.3)
			while fishing.minigame.is_running():
				var game: MinigameBase = fishing.minigame.get("_game")
				if game:
					game._finish(_rng.randf() < SKILL, _rng.randf() < 0.3)
				await _wait(0.2)
			sea_s += MINIGAME_SECONDS
			await _wait(0.2)
			if get_tree().paused:  # overflow: throw the extra back
				var hold_ui := sea.get_node("HoldUI") as HoldUI
				if hold_ui.visible:
					hold_ui.close()
				await _through_cutscene("sea pause d%d" % GameState.day)
			var after := hold_manager.hold.items.size()
			if after > before:
				fish += after - before
				if hold_manager.hold.items[-1].fish.id == Story.OMEN_FISH_ID:
					glow += 1
	sea_s += pos.distance_to(dock) / speed
	_human_seconds += sea_s + 15.0
	_day_line.merge({"fish": fish, "docks": docks, "sea_s": sea_s, "glow": glow}, true)
	sea.call("_end_sea_day", false)
	await _wait(1.5)
	await _through_cutscene("trip end d%d" % GameState.day)
	return false


# --- restaurant ---------------------------------------------------------------

func _restaurant_day() -> void:
	var rest := get_tree().current_scene
	var money_before := GameState.money
	var panel: Control = rest.get("_menu_panel")
	panel.show()
	await _wait(0.3)
	(panel.get_node("%AutoButton") as Button).pressed.emit()
	await _wait(0.3)
	(panel.get_node("%OpenButton") as Button).pressed.emit()
	_human_seconds += 25.0 + 180.0 + 20.0
	await _wait(0.5)
	var guard := 0.0
	while not bool(rest.get("_shift_over")) and guard < 400.0:
		if get_tree().paused:
			await _through_cutscene("mid shift d%d" % GameState.day)
		await _waiter_step(rest)
		await get_tree().process_frame
		guard += get_process_delta_time()
		_min_money = mini(_min_money, GameState.money)
	if guard >= 400.0:
		print("STUCK shift never ended d%d" % GameState.day)
	await _wait(0.5)
	var closer: ShiftCloser = rest.get("_closer")
	_day_line["served"] = closer.served
	_day_line["angry"] = closer.left_angry
	(rest.get_node("%NextDayButton") as Button).pressed.emit()
	await _wait(1.0)
	await _through_cutscene("after shift d%d" % GameState.day)
	_day_line["shift_money"] = GameState.money - money_before
	_buy_upgrades()
	var evening: RestaurantEvening = rest.get("_evening")
	evening.sail_button.pressed.emit()


func _buy_upgrades() -> void:
	var bought: Array[String] = []
	for entry in policy:
		var parts := entry.split(":")
		var up: UpgradeData = _upgrades[parts[0]]
		if _lvl(up.id) >= int(parts[1]):
			continue
		var cost := up.next_cost(_lvl(up.id))
		if cost < 0 or GameState.money - cost < RESERVE:
			break  # save up for this one first
		if GameState.buy_upgrade(up):
			bought.append(entry)
	_day_line["bought"] = bought


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
			if order.dish.is_market_dish() and not order.dish.instant_serve \
					and stall.stock.portions(order.dish) == 0 and stall.bag.count(order.dish) == 0:
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
	rin.facing = cell - rin.cell()
	kitchen.interact(cell)


func _shop(rin: RinChef, room: StreetRoom, stall: MarketStall, dish: DishData) -> void:
	var counter: Vector2i = room.grid.cells_of("V")[0]
	await rin.walk_and_wait(room.grid.path(rin.cell(), room.grid.stand_cell(counter, rin.cell())))
	stall.buy(dish, GameState.money >= dish.buy_cost(true) + 200)
	var fridge: Vector2i = room.grid.cells_of("F")[0]
	await rin.walk_and_wait(room.grid.path(rin.cell(), room.grid.stand_cell(fridge, rin.cell())))
	stall.store_at(fridge)


func _minigame(kitchen: KitchenStation, overlay: CookingOverlay) -> void:
	var t := 0.0
	while kitchen.busy and not overlay.is_running() and t < 3.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _wait(3.0)
	var game: CookingGameBase = overlay.get("_game")
	if game and overlay.is_running():
		game._finish(CookingGameBase.Result.PERFECT if _rng.randf() < 0.4 else CookingGameBase.Result.OK)
	while kitchen.busy:
		await get_tree().process_frame


# --- helpers ------------------------------------------------------------------

func _through_cutscene(label: String) -> void:
	var t := 0.0
	var counted := false
	while get_tree().paused and t < 120.0:
		if not counted:
			counted = true
			_cutscenes.append(label)
			_human_seconds += 30.0
		await _wait(0.4)
		t += 0.4
		for edit in get_tree().root.find_children("*", "LineEdit", true, false):
			if (edit as LineEdit).is_visible_in_tree():
				(edit as LineEdit).text_submitted.emit((edit as LineEdit).text)
		for pressed: bool in [true, false]:
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = pressed
			Input.parse_input_event(ev)
		var key := InputEventKey.new()
		key.physical_keycode = KEY_1
		key.pressed = true
		Input.parse_input_event(key)
	if t >= 120.0:
		print("STUCK paused at %s" % label)


## False (and the run ends) if the scene never shows up.
func _until_scene(scene_name: String) -> bool:
	var t := 0.0
	while (get_tree().current_scene == null or not get_tree().current_scene.scene_file_path.contains(scene_name)) and t < 60.0:
		if get_tree().paused:
			await _through_cutscene("waiting for " + scene_name)
		await _wait(0.2)
		t += 0.2
	if t >= 60.0:
		print("STUCK waiting for %s, at %s" % [scene_name,
			get_tree().current_scene.scene_file_path if get_tree().current_scene else "null"])
		_report_end("STUCK")
		return false
	await _wait(0.4)
	return true


## Save to a temp file, load it back, compare: Continue must restore all.
func _roundtrip(label: String) -> void:
	var path := "user://_tmp_bot_save.json"
	var before := JSON.stringify(SaveSystem.to_dict(), "", true)
	SaveSystem.save_game(path)
	SaveSystem.load_game(path)
	var after := JSON.stringify(SaveSystem.to_dict(), "", true)
	SaveSystem.delete_save(path)
	if before != after:
		print("SAVE MISMATCH at %s" % label)
		var a := before.split("\n")
		var b := after.split("\n")
		for i in mini(a.size(), b.size()):
			if a[i] != b[i]:
				print("  before: %s\n  after:  %s" % [a[i], b[i]])
				break


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout
