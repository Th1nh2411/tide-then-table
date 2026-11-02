extends Node
## Integration bot for the horror build's day loop (PLAN §10), mùng 9 to
## rằm, then the ending: bedroom -> waterfront (morning) -> restaurant ->
## waterfront (evening) -> house (sleep) or thúng (night at sea) -> bedroom.
## Perfect info: on omen nights (OmenPicker) it goes into the house to sleep,
## otherwise down into the thúng. Once (day 2 of the first loop) it picks the
## wrong one to check the reset to mùng 9. Travel and minigame skill are scripted;
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
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	if scene.scene_file_path == SEA:
		if scene.new_catch_card and scene.new_catch_card.visible:
			scene.new_catch_card._next()
		if scene.hold_ui and scene.hold_ui.visible:
			scene.hold_ui.close()

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

func _finish_fishing(sea: Node) -> void:
	var overlay: FishingOverlay3D = sea.overlay
	if not overlay.active:
		_fail("fishing did not start")
		return
	overlay._minigame.result_seconds = 0.01
	overlay._minigame._game._finish(true, true)
	for i: int in range(120):
		await get_tree().process_frame
		if not overlay.active and not get_tree().paused:
			return
	_fail("fishing did not end")

func _night(sea: Node) -> void:
	var range_z: float = SeaLayout3D.reach_z(sea.boat_data.max_depth)
	for shoal: SeaShoals3D.Shoal in sea.shoals:
		var target: Vector3 = shoal.pos
		if target.z < range_z:
			continue
		sea.cast_cinematic_enabled = false
		for cast: int in range(shoal.fish_left):
			sea.boat.position = target
			sea.boat.velocity = Vector3.ZERO
			sea._try_fish()
			await _finish_fishing(sea)
			sea.boat.position = sea.START
			sea._unload()
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
	print("DAY %d | served %d | lost %d | rating %d" % [GameState.day, quan.served, quan.lost, GameState.last_rating])
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
		if expect_reset != "":
			if GameState.day != 1 or LoopCalendar.loops() != 1:
				_fail(expect_reset + " did not reset to mùng 9")
				return
			print("LOOP RESET | %s -> %s" % [expect_reset, LoopCalendar.date_text(GameState.day)])
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
		evening.go_to_sea()
		var sea: Node = await _until(SEA)
		if not sea:
			return
		await _night(sea)
	_fail("no ending after 20 days")

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
