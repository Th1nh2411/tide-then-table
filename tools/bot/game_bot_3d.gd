extends Node
## Integration bot for the native 3D loop. Travel and minigame skill are scripted.
## Uses real catches, stock, service, bills, upgrades, story and scene transitions.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"
const REST := "res://scenes/rest/rest_scene.tscn"
const QUAN := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const END := "res://scenes/ending/ending_scene.tscn"
var _ticks: int = 0
var _failed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene = null
	_run.call_deferred()

func _process(_delta: float) -> void:
	_ticks += 1
	if _ticks > 12000:
		_fail("watchdog")
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	var bridge: Variant = scene.get("story_bridge")
	if bridge is StoryBridge3D and bridge.playing:
		bridge._skipping = true
		bridge._dialogue._advanced.emit()
	if scene.scene_file_path == SEA:
		if scene.new_catch_card and scene.new_catch_card.visible:
			scene.new_catch_card._next()
		if scene.hold_ui and scene.hold_ui.visible:
			scene.hold_ui.close()

func _frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().process_frame

func _until(path: String) -> Node:
	for i: int in range(600):
		var scene: Node = get_tree().current_scene
		if scene and scene.scene_file_path == path and not SceneRouter._is_transitioning:
			return scene
		await get_tree().process_frame
	_fail("scene " + path)
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
	sea.boat.position = SeaLayout3D.to_world(Vector2(900, 1000))
	sea.boat.velocity = Vector3.ZERO
	sea._drop_net()
	sea.elapsed += 90.0
	if not sea._try_haul_net():
		_fail("net did not haul")
		return
	await _finish_fishing(sea)
	sea.boat.position = sea.START
	sea._unload()
	sea._end_trip(false)

func _service(quan: Node) -> void:
	for i: int in range(120):
		await get_tree().process_frame
		if not quan.story_bridge.playing:
			break
	quan.plan.auto_fill(quan.menu.dishes, GameState.storage)
	if not quan._has_stock():
		quan._sail_without_shift()
		return
	quan._open_shift()
	quan.cooking_overlay.result_seconds = 0.01
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
			if not bool(order.get("cooked", false)):
				quan.player.position = quan.BEER_POSITION if dish.instant_serve else quan.GRILL_POSITION
				quan._interact()
				if quan.cooking_overlay.is_running():
					quan.cooking_overlay._game._finish(CookingGameBase.Result.PERFECT)
					await _frames(5)
			if bool(order.get("cooked", false)):
				# Let hired staff make their real pickup and delivery trips.
				quan._move_staff(20.0)
				quan._move_staff(20.0)
				if str(order.get("phase", "waiting")) == "waiting":
					quan.player.position = quan.PASS_POSITION
					quan._interact()
					quan.player.position = quan.TABLES[table] + Vector3(0, 0, 1.2)
					quan._interact()
				quan._finish_meal(table)
				quan._clean_table(table)
		await _frames(1)
		if not quan._has_stock() and quan.orders.all(func(order: Dictionary) -> bool: return order.is_empty()):
			quan._end_shift()
			break
	if not quan.shift_over:
		_fail("restaurant failed to drain orders")
		return
	var priority: Array[String] = ["boat", "rod", "lamp", "kitchen", "fridge"]
	if OS.get_environment("POLICY") == "balanced":
		priority = ["kitchen", "boat", "lamp", "rod", "fridge"]
	for id: String in priority:
		var upgrade: UpgradeData = load("res://data/upgrades/" + id + "_upgrade.tres")
		GameState.buy_upgrade(upgrade)
	print("DAY %d | served %d | lost %d | money %dk | boat %d | kitchen %d" % [GameState.day,
		quan.served, quan.lost, GameState.money, GameState.get_upgrade_level("boat"), GameState.get_upgrade_level("kitchen")])
	_roundtrip()
	quan._sail()

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
	SceneRouter.go_to(SEA)
	for night: int in range(12):
		var sea: Node = await _until(SEA)
		if not sea:
			return
		if Story.is_fog_open() and sea.WHIRLPOOL_POS.z >= SeaLayout3D.reach_z(sea.boat_data.max_depth):
			sea.boat.position = sea.WHIRLPOOL_POS
			await _until(END)
			print("RUN ENDING | 3D | day %d | money %dk" % [GameState.day, GameState.money])
			get_tree().quit(1 if _failed else 0)
			return
		await _night(sea)
		var rest: Node = await _until(REST)
		if not rest:
			return
		rest._wake_button.pressed.emit()
		var quan: Node = await _until(QUAN)
		if not quan:
			return
		await _service(quan)
	_fail("no ending after 12 days")

func _fail(reason: String) -> void:
	_failed = true
	print("STUCK 3D " + reason)
	get_tree().quit(1)
