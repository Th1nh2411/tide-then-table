extends Node
## Integration bot for the horror build's day loop (PLAN §10), mùng 9 to
## rằm, then the ending: bedroom -> waterfront (morning) -> restaurant ->
## waterfront (evening) -> house (sleep) or thúng (night at sea) -> bedroom.
## Perfect info: on omen nights (OmenPicker) it goes into the house to sleep,
## otherwise down into the thúng and brings back LoopCalendar.MIN_FISH fish
## through the real rod (Fishing3D: cast, bite, hook, reel, basket). Once (day 2 of the first loop) it picks the
## wrong one to check the reset to mùng 9. On rằm it takes the true path:
## refuses anh Út's tea, goes out, follows the ghost-lights to the raft and
## plays the dawn epilogue (RamNight). Travel and minigame skill are scripted;
## scenes, service, story and transitions are real. No money / upgrades any more.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"
const BEDROOM := "res://scenes/home3d/bedroom_scene_3d.tscn"
const QUAN := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const WATERFRONT := "res://scenes/home3d/waterfront_scene_3d.tscn"
const END := "res://scenes/ending/ending_scene.tscn"
var _ticks: int = 0
var _failed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene = null
	_run.call_deferred()

func _process(_delta: float) -> void:
	_ticks += 1
	if _ticks > 40000:
		_fail("watchdog")

func _frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().process_frame

func _until(path: String) -> Node:
	return await _until_any([path])

func _until_any(paths: Array[String]) -> Node:
	for i: int in range(600):
		var scene: Node = get_tree().current_scene
		if scene and paths.has(scene.scene_file_path) and not SceneRouter._is_transitioning:
			return scene
		await get_tree().process_frame
	_fail("scene " + str(paths))
	return null

## One fish into the basket the way a player does it: cast at `at`, wait for
## the bite (forced), click in the window, reel while the line is not too
## tight, look... and E (drop_in_basket). Ticks the rod faster than frames.
func _catch_one(sea: Node, at: Vector3) -> bool:
	var rod: Fishing3D = sea.rod
	var before: int = rod.basket.count()
	for attempt: int in range(8):
		if sea.ending or not rod.cast(at):
			return false
		while rod.state == Fishing3D.State.CASTING:
			rod.tick(0.05)
		rod.force_bite()
		rod.press()  # the click inside the "!" window
		var steps := 0
		while rod.state == Fishing3D.State.REELING and steps < 4000:
			rod.hold_override = rod.reel.tension < (0.45 if rod.reel.running else 0.75)
			rod.tick(0.05)
			steps += 1
			if steps % 40 == 0:
				await get_tree().process_frame
		rod.hold_override = false
		if rod.state == Fishing3D.State.HOLDING:
			rod.drop_in_basket()
			return rod.basket.count() > before
	return false

## A calm night: fish at the nearest reachable shoals until the basket holds
## MIN_FISH, then row home (placed at the dock) and end the trip.
func _night(sea: Node) -> void:
	var range_z: float = SeaLayout3D.reach_z(sea.boat_data.max_depth)
	for shoal: SeaShoals3D.Shoal in sea.shoals:
		if sea.rod.basket.count() >= LoopCalendar.MIN_FISH or sea.ending:
			break
		if shoal.pos.z < range_z or shoal.fish_left <= 0:
			continue
		sea.boat.position = shoal.pos + Vector3(0, 0, 8.0)
		sea.boat.velocity = Vector3.ZERO
		while shoal.fish_left > 0 and sea.rod.basket.count() < LoopCalendar.MIN_FISH and not sea.ending:
			if not await _catch_one(sea, shoal.pos):
				break
		await _frames(1)
	if sea.ending:
		return  # đêm âm took him
	if sea.rod.basket.count() < LoopCalendar.MIN_FISH:
		_fail("only %d fish tonight" % sea.rod.basket.count())
		return
	print("SEA | %s | basket %d" % [LoopCalendar.date_text(GameState.day), sea.rod.basket.count()])
	sea.boat.position = sea.START
	sea.boat.velocity = Vector3.ZERO
	sea._end_trip(false)

func _service(quan: Node) -> void:
	await _frames(3)
	quan._open_shift()  # normally opens on arrival; a no-op then
	for turn: int in range(200):
		if quan.shift_over:
			break
		quan._spawn_order()
		quan._tick_bao(20.0)
		quan._tick_bao(20.0)
		for table: int in range(quan.orders.size()):
			if quan.orders[table].is_empty():
				if quan.dirty_tables[table]:
					quan._clean_table(table)
				continue
			var order: Dictionary = quan.orders[table]
			if str(order.get("phase", "waiting")) == "eating":
				quan._finish_meal(table)
				continue
			var dish: DishData = order["dish"]
			if not bool(order.get("cooked", false)) and dish.instant_serve:
				quan.player.position = quan.BEER_POSITION
				quan._interact()
			if bool(order.get("cooked", false)):
				if str(order.get("phase", "waiting")) == "waiting":
					quan.player.position = quan.PASS_POSITION
					quan._interact()
					quan.player.position = quan.TABLES[table] + Vector3(0, 0, 1.2)
					quan._interact()
				quan._finish_meal(table)
				quan._clean_table(table)
		await _frames(1)
		# The fixed menu never runs out: serve a while, then close once the tables are empty.
		if turn >= 40 and quan.orders.all(func(order: Dictionary) -> bool: return order.is_empty()):
			quan._end_shift()
			break
	if not quan.shift_over:
		_fail("restaurant failed to drain orders")
		return
	var tray := quan.get_node(RestaurantFish3D.NODE_NAME) as RestaurantFish3D
	print("DAY %d | served %d | lost %d | rating %d | fish on the tray %d | %s" % [GameState.day, quan.served, quan.lost,
		GameState.last_rating, tray.fish_count, " / ".join(tray.lines)])
	if RamNight.is_ram() and not _refuse_tea(quan):
		return
	_roundtrip()
	quan._walk_home()

func _roundtrip() -> void:
	var expected: Dictionary = SaveSystem.to_dict()
	var path := "user://bot3d_roundtrip.json"
	if not SaveSystem.save_game(path) or not SaveSystem.load_game(path):
		_fail("save roundtrip")
	elif JSON.stringify(SaveSystem.to_dict()) != JSON.stringify(expected):
		_fail("save state mismatch")
	SaveSystem.delete_save(path)

func _run() -> void:
	SaveSystem.autosave_off = true
	SceneRouter.fade_duration = 0.01
	GameState.reset()
	SceneRouter.go_to(BEDROOM)
	var reset_checked := false
	var expect_reset := ""
	for step: int in range(20):
		var room: Node = await _until_any([BEDROOM, END])
		if not room:
			return
		if room.scene_file_path == BEDROOM and room.leaving:
			room = await _until(END)  # the last night ends straight from the bedroom
			if not room:
				return
		if room.scene_file_path == END:
			print("RUN ENDING | 3D | day %d | loops %d" % [GameState.day, LoopCalendar.loops()])
			get_tree().quit(1 if _failed else 0)
			return
		var visited: bool = room.has_node(WetFootprints3D.NODE_NAME)
		if visited != (expect_reset == "home on a calm night"):
			_fail("wet footprints %s after '%s'" % ["shown" if visited else "missing", expect_reset])
			return
		if expect_reset != "":
			if GameState.day != 1 or LoopCalendar.loops() != 1:
				_fail(expect_reset + " did not reset to mùng 9")
				return
			var hint: String = room.NEWS.hint(LoopCalendar.missed())
			if hint == "" or room.paper_hint() != hint:
				_fail("no hint on the mùng 9 paper after '%s'" % expect_reset)
				return
			print("LOOP RESET | %s -> %s | paper: %s" % [expect_reset, LoopCalendar.date_text(GameState.day), hint])
			expect_reset = ""
		var omen := OmenPicker.tonight()
		if GameState.has_flag(LoopCalendar.OMEN_FLAG) != (omen != null):
			_fail("omen flags out of sync")
			return
		var customs := OmenPicker.customs(OmenPicker.CATALOG, LoopCalendar.loops(), GameState.day)
		print("HOME | %s | loops %d | omen %s | customs %s" % [LoopCalendar.date_text(GameState.day), LoopCalendar.loops(),
			omen.id if omen else "-", ",".join(customs)])
		room.leave()
		var morning: Node = await _until(WATERFRONT)
		if not morning:
			return
		if morning.evening:
			_fail("waterfront in the morning thinks it is evening")
			return
		morning.go_to_restaurant()
		var quan: Node = await _until(QUAN)
		if not quan:
			return
		if omen and not _omen_shown(quan, omen):
			return
		var go_home := omen != null
		if not reset_checked and GameState.day == 2:
			reset_checked = true
			go_home = not go_home
			expect_reset = "out on an omen night" if omen else "home on a calm night"
		await _service(quan)
		var evening: Node = await _until(WATERFRONT)
		if not evening:
			return
		if not evening.evening or not evening.has_node("DockOmens"):
			_fail("evening waterfront without its dock omen props")
			return
		if go_home:
			evening.go_to_sleep()
			continue
		if RamNight.is_ram() and not evening.has_node("RamShore"):
			_fail("rằm evening without the hoa đăng")
			return
		evening.go_to_sea()
		var sea: Node = await _until(SEA)
		if not sea:
			return
		if RamNight.is_ram():
			await _ram_night(sea)
			continue
		await _night(sea)
	_fail("no ending after 20 days")

## Rằm at the restaurant: anh Út came; the true path refuses his tea.
func _refuse_tea(quan: Node) -> bool:
	var ut := quan.get_node_or_null("AnhUt") as RamGuest3D
	if ut == null:
		_fail("rằm without anh Út at the restaurant")
		return false
	ut.arrive()
	ut.answer(false)
	print("RAM | %s | anh Út's ginger tea refused" % LoopCalendar.date_text(GameState.day))
	return true

## Rằm at sea, the true path: follow the ghost-lights to the raft, see anh Út,
## then the dawn epilogue. The run loop then finds the ending card.
func _ram_night(sea: Node) -> void:
	var ram := RamSea3D.active(sea)
	if ram == null or ram.drank or ram.trail.is_empty():
		_fail("rằm sea without the ghost-light trail")
		return
	RamNight.speed = 40.0
	var raft: Vector3 = sea.RAFT_POS
	sea.boat.position = raft + (sea.START - raft).normalized() * (RamSea3D.REVEAL_DISTANCE - 2.0)
	sea.boat.velocity = Vector3.ZERO
	var epilogue: Node = await _until(RamEpilogue3D.SCENE)
	if not epilogue:
		return
	await _until(END)
	RamNight.speed = 1.0
	if RamNight.ending_id() != "true":
		_fail("rằm ended as '%s', expected the true ending" % RamNight.ending_id())
		return
	print("RAM ENDING | true | refused the tea, saw anh Út at the raft | clues %d" % NightErrand3D.clue_count())

## The restaurant built tonight's omen props (the dock's are checked on the waterfront).
func _omen_shown(quan: Node, omen: OmenData) -> bool:
	var props := quan.get_node_or_null("Omens") as RestaurantOmens3D
	var ok := props != null
	if ok and omen.id == "mam_cung":
		ok = (props.get_node("Offering") as OmenOffering3D).eaten
	elif ok and omen.id == "led_chao":
		ok = (props.get_node("LedSign") as OmenLedSign3D).items.has(omen.text)
	if not ok:
		_fail("omen %s not shown" % omen.id)
	return ok

func _fail(reason: String) -> void:
	_failed = true
	print("STUCK 3D " + reason)
	get_tree().quit(1)
