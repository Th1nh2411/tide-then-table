extends Node2D
## Sea screen root for the night trip. Starts the night (lamp oil burns),
## wires the dock and HUD, ends the trip (docking, or a rescue tow when the
## hull breaks or the oil runs dry), runs the story hooks (omen, fog,
## whirlpool ending) and holds debug tools.

const REST_SCENE_PATH: String = "res://scenes/rest/rest_scene.tscn"
const ENDING_SCENE_PATH: String = "res://scenes/ending/ending_scene.tscn"

## Boat upgrade track: the player's current level decides today's boat.
@export var boat_upgrade: UpgradeData
## Boats selectable with debug keys 1/2/3 (debug builds only).
@export var debug_boats: Array[BoatData] = []
## How long the "towed home" message stays before switching scenes.
@export var tow_message_seconds: float = 1.5
## Rescue tow fees (k, capped at what the player has).
@export var rescue_fee: int = 150
@export var oil_rescue_fee: int = 80
## Hull the rescue crew patches a broken boat up to (free), so a player
## with no money can still sail the next night.
@export var tow_patch_hp: float = 20.0
## For order texts (fish names).
@export var fish_catalog: FishCatalog
## Cutscenes that can play when a trip ends (first eligible one, once).
@export var trip_end_cutscenes: Array[Cutscene] = []
## Seconds the boat spins into the whirlpool before the white fade.
@export var whirlpool_pull_seconds: float = 2.0

var _day_ended: bool = false

@onready var _boat: Boat = $Boat
@onready var _bounds: MapBounds = $MapBounds
@onready var _dock: Dock = $Dock
@onready var _hud: SeaHud = $SeaHud
@onready var _hold_manager: HoldManager = $HoldManager
@onready var _nets: NetController = $NetController
@onready var _fishing: FishingController = $FishingController
@onready var _fog: FogArea = $FogArea
@onready var _hull: HullController = $HullController
@onready var _oil: LampOil = $LampOil
@onready var _range: BoatRange = $BoatRange
@onready var _cutscene: CutscenePlayer = $CutscenePlayer
@onready var _events: NightEvents = $NightEvents
@onready var _debug_label: Label = %DebugLabel


func _ready() -> void:
	Sfx.ambience("sea")
	var camera := _boat.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = _bounds.map_size.x
	camera.limit_bottom = _bounds.map_size.y
	_debug_label.visible = OS.is_debug_build()
	if boat_upgrade:
		_boat.apply_boat_data(GameState.get_upgrade_value(boat_upgrade))

	_dock.boat_entered.connect(_on_dock_entered)
	_hull.hull_changed.connect(_refresh_dock_prompt)
	_hull.boat_broken.connect(_on_boat_broken)
	var wave := WavePower.new()
	wave.can_use = _fishing.minigame.is_running
	add_child(wave)
	_hud.set_speaker("Rin", _rin_head)
	var story_debug := CutsceneDebug.new()
	story_debug.player = _cutscene
	story_debug.cutscenes = trip_end_cutscenes
	story_debug.message_requested.connect(_hud.flash_message.bind(2.5))
	add_child(story_debug)
	var card := NewCatchCard.new()
	add_child(card)
	_hold_manager.new_species_caught.connect(card.show_fish)
	var phone := $PhoneApp as PhoneApp
	phone.repair_allowed = _hull.is_at_dock
	phone.repair_action = _hull.repair
	_dock.boat_exited.connect(_on_dock_exited)
	_dock.docking_requested.connect(_on_docking_requested)
	_hud.unload_pressed.connect(_unload_at_dock)
	_hud.go_home_pressed.connect(_go_home)
	_nets.nets_changed.connect(_hud.set_nets)
	_fishing.fish_caught.connect(_on_fish_caught)
	_fog.whirlpool_entered.connect(_on_whirlpool_entered)
	_oil.oil_changed.connect(_hud.set_oil)
	_oil.oil_low.connect(_hud.flash_message.bind("Dầu đèn còn 1/4, trời sắp rạng. Về bến thôi!", 2.5))
	_oil.oil_empty.connect(_on_oil_empty)
	DayClock.start_night()
	_add_guide()
	_add_quest_tracker()
	# Deferred: FogArea decides the fog zone's visibility in its own _ready.
	_capture_map.call_deferred()
	_show_orders()
	if GameState.last_spoiled_count > 0:
		_hud.flash_message("Hư mất %d con trong kho rồi, tiếc ghê..." % GameState.last_spoiled_count, 2.5)
		GameState.last_spoiled_count = 0
	if Story.check_day():
		_hud.flash_message("Biển lặng lạ thường... phía đông bắc sương dày lên.", 3.0)
	elif Story.is_fog_open():
		_hud.flash_message("Sương phủ kín góc đông bắc... trong đó có ánh sáng gì vậy?", 3.0)
	# Autosave at the start of every night (hold is empty, storage is settled).
	# Headless test runs pass `-- --no-autosave` so they never touch the real save.
	SaveSystem.autosave("sea")


## Floating quest box (main story + fish orders), top-left under the money.
func _add_quest_tracker() -> void:
	var tracker := QuestTracker.new()
	tracker.catalog = fish_catalog
	add_child(tracker)
	_cutscene.hidden_nodes.append(tracker)


## First-time pointers (SeaGuide).
func _add_guide() -> void:
	var guide: SeaGuide = SeaGuide.new()
	guide.boat = _boat
	guide.spawner = _fishing.spawner
	guide.fishing = _fishing
	guide.nets = _nets
	guide.hold_manager = _hold_manager
	guide.oil = _oil
	guide.dock = _dock
	guide.raft = get_node_or_null("Places/LobsterRaft") as Node2D
	add_child(guide)


func _capture_map() -> void:
	PhoneMap.capture(Vector2(_bounds.map_size), $Zones, $Land, $Obstacles, _dock,
		_fog.get_whirlpool_position(), get_tree().get_nodes_in_group("pois"), _range.limit_y)


func _show_orders() -> void:
	_hud.set_orders(PackedStringArray())  # the orders themselves are in the QuestTracker
	var fresh := false
	for order: Dictionary in GameState.orders:
		# Arrived this morning: all its nights are still ahead.
		fresh = fresh or int(order["due_day"]) - GameState.day + 1 == FishOrders.NIGHTS_TO_DELIVER
	if fresh:
		_hud.flash_message("[MSG] Có khách đặt cá", 2.0)


func _process(_delta: float) -> void:
	if _debug_label.visible:
		_debug_label.text = "%s | tốc độ %d | [1-3] đổi thuyền [F2] mở sương [F3] cutscene [F4] Nhịp Sóng" % [
			_boat.boat_data.display_name, roundi(_boat.speed)]


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < debug_boats.size():
		_boat.apply_boat_data(debug_boats[index])
	elif key.physical_keycode == KEY_F2:
		# Debug: pretend the omen happened yesterday and reload to open the fog.
		GameState.set_flag(Story.OMEN_DAY_FLAG, GameState.day - 1)
		get_tree().reload_current_scene()


func _on_fish_caught(fish: FishData, _quality: float, _count: int, _size: float) -> void:
	if Story.on_fish_caught(fish):
		_hud.flash_message("[WARN] species_id không có trong database. Ngoài khơi đông bắc có gì đó lạ.", 3.0)


## Ending: the whirlpool pulls the boat in, then everything goes white.
func _on_whirlpool_entered(_whirlpool: Whirlpool) -> void:
	if _day_ended:
		return
	_day_ended = true
	DayClock.stop()
	_boat.set_physics_process(false)
	_hud.hide_prompt()
	GameState.set_flag(Story.ENDING_SEEN_FLAG)
	Sfx.play("whoosh", 0.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(_boat, "global_position", _fog.get_whirlpool_position(), whirlpool_pull_seconds)
	tween.tween_property(_boat, "rotation", _boat.rotation + TAU * 3.0, whirlpool_pull_seconds)
	tween.tween_property(_boat, "scale", Vector2(0.3, 0.3), whirlpool_pull_seconds)
	await tween.finished
	SceneRouter.go_to(ENDING_SCENE_PATH, Color.WHITE)


## E at the dock = unload (same as the pinned button).
func _on_docking_requested() -> void:
	_unload_at_dock()


## Dock button: the catch goes to storage, the night goes on.
func _unload_at_dock() -> void:
	var count := _hold_manager.get_items().size()
	if _day_ended or count == 0:
		return
	GameState.unload_catch(_hold_manager.take_all())
	Sfx.play("coins")
	_hud.flash_message("Dỡ xong %d con. Ra khơi tiếp thôi!" % count, 2.0)
	_refresh_dock_prompt()


## Dock button: the night ends here (nets still out are lost).
func _go_home() -> void:
	if not _day_ended and _hull.is_at_dock():
		_end_sea_day(false)


func _on_dock_entered() -> void:
	_hull.set_at_dock(true)
	_refresh_dock_prompt()


func _on_dock_exited() -> void:
	_hull.set_at_dock(false)
	_hud.hide_prompt()
	_hud.hide_dock()


func _refresh_dock_prompt() -> void:
	if _hull.is_at_dock() and not _day_ended:
		var repair := _hull.repair_prompt()
		if repair:
			_hud.show_prompt(repair)
		else:
			_hud.hide_prompt()
		_hud.show_dock(_hold_manager.get_items().size(), _nets.nets_out())


func _on_boat_broken() -> void:
	BoatCondition.tow_patch(tow_patch_hp)
	_rescue("Thuyền hư rồi... đành gọi cứu hộ kéo về", rescue_fee)


func _on_oil_empty() -> void:
	_rescue("Hết dầu đèn, tối om... đành gọi cứu hộ kéo về", oil_rescue_fee)


## Pay the rescue boat (as much as the player has) and get towed home.
func _rescue(text: String, fee: int) -> void:
	if _day_ended:
		return
	_boat.set_physics_process(false)
	var paid := mini(fee, GameState.money)
	GameState.spend_money(paid)
	_hud.show_message("%s (-%dk)" % [text, paid])
	await get_tree().create_timer(tow_message_seconds).timeout
	_end_sea_day(true)


func _end_sea_day(towed: bool) -> void:
	# Guard: docking and a rescue can both fire on the same frame.
	if _day_ended:
		return
	_day_ended = true
	DayClock.stop()
	_boat.set_physics_process(false)
	_hud.hide_prompt()
	_hud.hide_dock()
	_events.on_trip_end(towed)
	GameState.finish_sea_day(DayClock.current_minutes, towed, _hold_manager.get_items())
	var scene := DialogueLibrary.pick(trip_end_cutscenes) as Cutscene
	if scene:
		await _cutscene.play(scene)
	SceneRouter.go_to(REST_SCENE_PATH)


## Above Rin on the boat, on screen (his speech bubble).
func _rin_head() -> Vector2:
	return _boat.get_global_transform_with_canvas().origin + Vector2(0, -40)
