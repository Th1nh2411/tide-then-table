class_name FishingOverlay3D
extends CanvasLayer
## Hosts the existing 2D fishing minigame in a dedicated viewport over 3D sea.
## The world is paused until all gameplay inputs are released, preventing a
## held key from immediately steering or accelerating the boat after fishing.

signal catch_finished(success: bool, fish_data: FishData)
signal rin_fainted
signal catch_detailed(fish_data: FishData, caught: bool, quality: float, count: int, size: float)

@onready var _container: SubViewportContainer = $SubViewportContainer
@onready var _minigame: FishingMinigame = $SubViewportContainer/SubViewport/FishingMinigame
@onready var _release_notice: Label = $ReleaseNotice

var active: bool = false
var _waiting_release: bool = false
var _released_frames: int = 0
var _was_paused: bool = false
var _fish: FishData
var _size: float = 1.0
var _caught: bool = false
var _quality: float = 0.0
var _count: int = 0
var trip_stun: float = 0.0
var _fainted: bool = false
var _hold: HoldUI
## FishData.Zone of the next rod cast (sea backdrop); -1 = the fish's own.
var zone: int = -1


func _ready() -> void:
	hide()
	_minigame.process_mode = Node.PROCESS_MODE_DISABLED
	_minigame.finished.connect(_on_minigame_finished)
	_minigame.fight_stun_changed.connect(func(value: float) -> void: trip_stun = clampf(value, 0.0, 1.0))
	_minigame.rin_fainted.connect(func() -> void: _fainted = true)
	_minigame.hold_requested.connect(_open_hold)
	_minigame.catch_size_changed.connect(_on_catch_size_changed)
	# The container supplies viewport mouse input, and holds keyboard focus.
	_container.focus_mode = Control.FOCUS_ALL


func start_catch(fish_data: FishData, zone_scale: float = 1.0, size: float = 1.0, count: int = 1, school: int = 6) -> void:
	if active or fish_data == null:
		return
	active = true
	_fainted = false
	_caught = false
	_quality = 0.0
	_count = 0
	_waiting_release = false
	_released_frames = 0
	_fish = fish_data
	_size = size
	_was_paused = get_tree().paused
	_release_notice.hide()
	show()
	get_tree().paused = true
	_container.grab_focus()
	_minigame.process_mode = Node.PROCESS_MODE_ALWAYS
	_minigame.school_size = maxi(school, 1)
	_minigame.zone = zone
	_minigame.start(fish_data, zone_scale, count, size, trip_stun)


func _on_catch_size_changed(value: float) -> void:
	_size = value


func _on_minigame_finished(fish_data: FishData, caught: bool, quality: float, count: int) -> void:
	if not active or _waiting_release:
		return
	_fish = fish_data
	_caught = caught
	_quality = quality
	_count = count
	_waiting_release = true
	_release_notice.show()


func _process(_delta: float) -> void:
	if _hold and _hold.visible:
		return
	if not _waiting_release:
		return
	if _controls_held():
		_released_frames = 0
		return
	_released_frames += 1
	if _released_frames < 2:
		return
	_waiting_release = false
	active = false
	_release_notice.hide()
	_container.release_focus()
	hide()
	_minigame.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = _was_paused
	catch_detailed.emit(_fish, _caught, _quality, _count, _size)
	catch_finished.emit(_caught, _fish)
	if _fainted:
		rin_fainted.emit()


func _controls_held() -> bool:
	for action in [&"throttle_forward", &"throttle_back", &"turn_left", &"turn_right",
			&"cast", &"interact", &"open_hold"]:
		if Input.is_action_pressed(action):
			return true
	return false


## Inventory lives on the root viewport so it also works during a fight.
func bind_hold(hold: HoldUI) -> void:
	_hold = hold
	_hold.layer = layer + 1
	_hold.closed.connect(_on_hold_closed)


func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("open_hold") and _hold and not _hold.visible:
		get_viewport().set_input_as_handled()
		_open_hold()


func _open_hold() -> void:
	if not active or not _hold or _hold.visible:
		return
	_minigame.process_mode = Node.PROCESS_MODE_DISABLED
	_hold.open_browse(true)
	_container.release_focus()


func _on_hold_closed() -> void:
	if active:
		_minigame.process_mode = Node.PROCESS_MODE_ALWAYS
		_container.grab_focus()


func _exit_tree() -> void:
	if active and is_inside_tree():
		get_tree().paused = _was_paused
