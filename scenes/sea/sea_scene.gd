extends Node2D
## Sea screen root. Starts the day clock, wires the dock and HUD,
## ends the sea day (docking or towed at the deadline), runs the story hooks
## (omen, fog, whirlpool ending) and holds debug tools.

const RESTAURANT_SCENE_PATH: String = "res://scenes/restaurant/restaurant_scene.tscn"
const ENDING_SCENE_PATH: String = "res://scenes/ending/ending_scene.tscn"

## Boat upgrade track: the player's current level decides today's boat.
@export var boat_upgrade: UpgradeData
## Boats selectable with debug keys 1/2/3 (debug builds only).
@export var debug_boats: Array[BoatData] = []
## How long the "towed home" message stays before switching scenes.
@export var tow_message_seconds: float = 1.5
## Rescue when the hull breaks: fee (k, capped at what the player has) and
## in-game minutes lost waiting to be towed.
@export var rescue_fee: int = 60
@export var rescue_minutes: float = 60.0
## Seconds the boat spins into the whirlpool before the white fade.
@export var whirlpool_pull_seconds: float = 2.0

var _day_ended: bool = false
## Set after warning about nets still at sea; a second `interact` docks anyway.
var _dock_confirmed: bool = false

@onready var _boat: Boat = $Boat
@onready var _bounds: MapBounds = $MapBounds
@onready var _dock: Dock = $Dock
@onready var _hud: SeaHud = $SeaHud
@onready var _hold_manager: HoldManager = $HoldManager
@onready var _nets: NetController = $NetController
@onready var _fishing: FishingController = $FishingController
@onready var _fog: FogArea = $FogArea
@onready var _hull: HullController = $HullController
@onready var _debug_label: Label = %DebugLabel


func _ready() -> void:
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
	_dock.boat_exited.connect(_on_dock_exited)
	_dock.docking_requested.connect(_on_docking_requested)
	_nets.nets_changed.connect(_hud.set_nets)
	_fishing.fish_caught.connect(_on_fish_caught)
	_fog.whirlpool_entered.connect(_on_whirlpool_entered)
	DayClock.return_deadline_reached.connect(_on_return_deadline_reached)
	DayClock.start_day()
	if GameState.last_spoiled_count > 0:
		_hud.flash_message("Qua đêm %d món trong kho đã hỏng, phải bỏ đi" % GameState.last_spoiled_count, 2.5)
		GameState.last_spoiled_count = 0
	if Story.check_day():
		_hud.flash_message("Biển lặng lạ thường... phía đông bắc sương mù dày lên.", 3.0)
	elif Story.is_fog_open():
		_hud.flash_message("Sương mù phủ góc đông bắc. Trong đó có ánh sáng lạ...", 3.0)
	# Autosave at the start of every day (hold is empty, storage is settled).
	# Headless test runs pass `-- --no-autosave` so they never touch the real save.
	if not OS.get_cmdline_user_args().has("--no-autosave"):
		SaveSystem.save_game()


func _process(_delta: float) -> void:
	if _debug_label.visible:
		_debug_label.text = "%s | tốc độ %d | [1-3] đổi thuyền" % [
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


func _on_fish_caught(fish: FishData, _quality: float, _count: int) -> void:
	if Story.on_fish_caught(fish):
		_hud.flash_message("Con cá này phát sáng... Ngoài khơi đông bắc có gì đó lạ.", 3.0)


## Ending: the whirlpool pulls the boat in, then everything goes white.
func _on_whirlpool_entered(_whirlpool: Whirlpool) -> void:
	if _day_ended:
		return
	_day_ended = true
	DayClock.stop()
	_boat.set_physics_process(false)
	_hud.hide_prompt()
	GameState.set_flag(Story.ENDING_SEEN_FLAG)
	var tween := create_tween().set_parallel()
	tween.tween_property(_boat, "global_position", _fog.get_whirlpool_position(), whirlpool_pull_seconds)
	tween.tween_property(_boat, "rotation", _boat.rotation + TAU * 3.0, whirlpool_pull_seconds)
	tween.tween_property(_boat, "scale", Vector2(0.3, 0.3), whirlpool_pull_seconds)
	await tween.finished
	SceneRouter.go_to(ENDING_SCENE_PATH, Color.WHITE)


func _on_docking_requested() -> void:
	if _nets.nets_out() > 0 and not _dock_confirmed:
		_dock_confirmed = true
		_hud.flash_message("Còn %d lưới ngoài biển! E lần nữa để bỏ lại (mất ốc trong lưới)" % _nets.nets_out(), 2.5)
		return
	_end_sea_day(false)


func _on_dock_entered() -> void:
	_hull.set_at_dock(true)
	_refresh_dock_prompt()


func _on_dock_exited() -> void:
	_dock_confirmed = false
	_hull.set_at_dock(false)
	_hud.hide_prompt()


func _refresh_dock_prompt() -> void:
	if _hull.is_at_dock() and not _day_ended:
		_hud.show_prompt("E: Cập bến" + _hull.repair_prompt())


## Hull hit 0 at sea: pay the rescue boat, lose time, get towed home.
func _on_boat_broken() -> void:
	if _day_ended:
		return
	_boat.set_physics_process(false)
	var fee := mini(rescue_fee, GameState.money)
	GameState.spend_money(fee)
	DayClock.advance(rescue_minutes)
	_hud.show_message("Thuyền hư! Cứu hộ kéo về bến (-%dk)" % fee)
	await get_tree().create_timer(tow_message_seconds).timeout
	_end_sea_day(true)


func _on_return_deadline_reached() -> void:
	if _day_ended:
		return
	_boat.set_physics_process(false)
	_hud.show_message("Đã 21:00 — thuyền bị kéo về bến")
	await get_tree().create_timer(tow_message_seconds).timeout
	_end_sea_day(true)


func _end_sea_day(towed: bool) -> void:
	# Guard: docking and the deadline can both fire on the same frame.
	if _day_ended:
		return
	_day_ended = true
	DayClock.stop()
	_boat.set_physics_process(false)
	_hud.hide_prompt()
	GameState.finish_sea_day(DayClock.current_minutes, DayClock.get_shift_ratio(), towed,
		_hold_manager.get_items())
	SceneRouter.go_to(RESTAURANT_SCENE_PATH)
