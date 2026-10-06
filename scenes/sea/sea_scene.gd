extends Node2D
## Sea screen root. Starts the day clock, wires the dock and HUD,
## ends the sea day (docking or towed at the deadline), and holds debug tools.

const RESTAURANT_SCENE_PATH: String = "res://scenes/restaurant/restaurant_scene.tscn"

## Boats selectable with debug keys 1/2/3 (debug builds only).
@export var debug_boats: Array[BoatData] = []
## How long the "towed home" message stays before switching scenes.
@export var tow_message_seconds: float = 1.5

var _day_ended: bool = false
## Set after warning about nets still at sea; a second `interact` docks anyway.
var _dock_confirmed: bool = false

@onready var _boat: Boat = $Boat
@onready var _bounds: MapBounds = $MapBounds
@onready var _dock: Dock = $Dock
@onready var _hud: SeaHud = $SeaHud
@onready var _hold_manager: HoldManager = $HoldManager
@onready var _nets: NetController = $NetController
@onready var _debug_label: Label = %DebugLabel


func _ready() -> void:
	var camera := _boat.camera
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = _bounds.map_size.x
	camera.limit_bottom = _bounds.map_size.y
	_debug_label.visible = OS.is_debug_build()

	_dock.boat_entered.connect(_hud.show_prompt.bind("E: Cập bến"))
	_dock.boat_exited.connect(_on_dock_exited)
	_dock.docking_requested.connect(_on_docking_requested)
	_nets.nets_changed.connect(_hud.set_nets)
	DayClock.return_deadline_reached.connect(_on_return_deadline_reached)
	DayClock.start_day()


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


func _on_docking_requested() -> void:
	if _nets.nets_out() > 0 and not _dock_confirmed:
		_dock_confirmed = true
		_hud.flash_message("Còn %d lưới ngoài biển! E lần nữa để bỏ lại (mất ốc trong lưới)" % _nets.nets_out(), 2.5)
		return
	_end_sea_day(false)


func _on_dock_exited() -> void:
	_dock_confirmed = false
	_hud.hide_prompt()


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
