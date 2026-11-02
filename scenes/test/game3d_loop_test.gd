extends Node
## Integration: real scene routes + minigame results + shared persistent state.
## Travel and minigame skill are scripted; no player's save is read or written.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"
const BEDROOM := "res://scenes/home3d/bedroom_scene_3d.tscn"
const WATERFRONT := "res://scenes/home3d/waterfront_scene_3d.tscn"
const QUAN := "res://scenes/restaurant3d/restaurant_scene_3d.tscn"
const SAVE := "user://test_game3d_loop.json"
var _failures: int = 0
var _frames_elapsed: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Remain a root sibling while SceneRouter replaces the actual game scenes.
	get_tree().current_scene = null
	_run.call_deferred()

func _process(_delta: float) -> void:
	_frames_elapsed += 1
	if _frames_elapsed > 1000:
		print("FAIL 3D loop timed out")
		get_tree().quit(1)

func _frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().process_frame

func _check(ok: bool, words: String) -> void:
	print(("PASS " if ok else "FAIL ") + words)
	if not ok:
		_failures += 1

func _scene(path: String) -> Node:
	for i: int in range(180):
		var current: Node = get_tree().current_scene
		if current and current.scene_file_path == path and not SceneRouter._is_transitioning:
			return current
		await get_tree().process_frame
	print("FAIL did not reach " + path)
	get_tree().quit(1)
	return null

func _run() -> void:
	SaveSystem.autosave_off = true
	SceneRouter.fade_duration = 0.01
	GameState.reset()
	SceneRouter.go_to(SEA)
	var sea: Node = await _scene(SEA)
	if not sea:
		return
	_check(sea is Node3D, "F5 gameplay route opens native 3D sea")
	var rod: Fishing3D = sea.rod
	var shoal: SeaShoals3D.Shoal = sea.shoals[sea._nearest_school_index()]
	shoal.fish_left = maxi(shoal.fish_left, LoopCalendar.MIN_FISH)
	sea.boat.position = shoal.pos + Vector3(0, 0, 8.0)
	for n: int in range(LoopCalendar.MIN_FISH):
		catch_one(rod, shoal.pos)
	_check(rod.basket.count() == LoopCalendar.MIN_FISH and not get_tree().paused, "three fish caught on the rod go into the basket")
	var fish: FishData = rod.basket.fish[0]
	_check(GameState.caught_species.has(fish.id), "catch reaches persistent Dex")
	sea.boat.position = sea.START
	sea.boat.velocity = Vector3.ZERO
	sea._end_trip(false)
	var room: Node = await _scene(BEDROOM)
	if not room:
		return
	_check(GameState.resume_at == "home" and GameState.day == 2 and GameState.caught_species.has(fish.id),
		"docking with 3 fish wakes Rin in his room on the next day, catch remembered")
	room.leave()
	var morning: Node = await _scene(WATERFRONT)
	if not morning:
		return
	_check(not morning.evening, "bedroom door opens onto the waterfront in the morning")
	morning.go_to_restaurant()
	var quan: Node = await _scene(QUAN)
	if not quan:
		return
	_check(quan is Node3D, "the lane routes to the native 3D restaurant")
	_check(quan.shift_running, "the shift opens by itself when Rin arrives (no menu planning)")
	var tray := quan.get_node_or_null(RestaurantFish3D.NODE_NAME) as RestaurantFish3D
	_check(tray != null and tray.fish_count == LoopCalendar.MIN_FISH and tray.lines.has(RestaurantFish3D.ASK_LINE),
		"last night's fish wait by Bảo's cart; Bảo asks for tonight's")
	quan._spawn_order()
	var table: int = -1
	for i: int in range(quan.orders.size()):
		if not quan.orders[i].is_empty():
			table = i
			break
	if table < 0:
		_check(false, "guest orders from the fixed menu")
		get_tree().quit(1)
		return
	var dish: DishData = quan.orders[table]["dish"]
	_check(RestaurantService3D.FIXED_MENU.dishes.has(dish), "guest orders from the fixed menu")
	if dish.instant_serve:
		quan.player.position = quan.BEER_POSITION
		quan._interact()
		_check(quan.carrying_table == table, "E at the keg puts the beer tower in Rin's hands")
	else:
		quan._tick_bao(0.0)
		quan._tick_bao(20.0)
		_check(bool(quan.orders[table].get("cooked", false)), "Bao cooks the ordered dish")
		quan.player.position = quan.PASS_POSITION
		quan._interact()
		_check(quan.carrying_table == table, "E at pass picks up cooked plate")
	quan.player.position = quan.TABLES[table] + Vector3(0, 0, 1.2)
	quan._interact()
	_check(str(quan.orders[table].get("phase", "")) == "eating" and quan.earned == 0,
		"E serves table; the bill waits until guests finish eating")
	quan._finish_meal(table)
	for i: int in range(4):  # extra lines / rounds of the same party
		if quan.dirty_tables[table]:
			break
		quan.orders[table]["cooked"] = true
		quan.orders[table]["phase"] = "eating"
		quan._finish_meal(table)
	_check(quan.earned > 0 and quan.dirty_tables[table], "the party pays (counted, not money) and leaves a dirty table")
	quan._clean_table(table)
	_check(not quan.dirty_tables[table], "table can be cleaned for next guest")
	quan._end_shift()
	_check(quan.shift_over and GameState.day_history.size() == 1 and int(GameState.day_history[0]["earned"]) == quan.earned,
		"closing records the shift for the ending card")
	quan._walk_home()
	var evening: Node = await _scene(WATERFRONT)
	if not evening:
		return
	_check(evening.evening, "after the shift Rin walks back to the waterfront in the evening")
	evening.go_to_sea()
	sea = await _scene(SEA)
	if not sea:
		return
	_check(GameState.day == 2, "the thúng goes to sea the same night")
	_check(SaveSystem.save_game(SAVE), "3D loop can save to isolated scratch slot")
	var saved_day: int = GameState.day
	GameState.day = 1
	_check(SaveSystem.load_game(SAVE) and GameState.day == saved_day and GameState.day_history.size() == 1,
		"save/load retains the day and the shift record")
	SaveSystem.delete_save(SAVE)
	get_tree().quit(1 if _failures else 0)


## The real rod path, driven like the bot: cast, bite, hook, reel with care, basket.
static func catch_one(rod: Fishing3D, at: Vector3) -> void:
	var before := rod.basket.count()
	for attempt: int in range(10):
		rod.cast(at)
		while rod.state == Fishing3D.State.CASTING:
			rod.tick(0.05)
		rod.force_bite()
		rod.hook()
		while rod.state == Fishing3D.State.REELING:
			rod.hold_override = rod.reel.tension < (0.45 if rod.reel.running else 0.75)
			rod.tick(0.05)
		rod.hold_override = false
		if rod.drop_in_basket() and rod.basket.count() > before:
			return
