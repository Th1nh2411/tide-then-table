class_name FishingOverlay3D
extends CanvasLayer
## Hosts the existing 2D fishing minigame in a dedicated viewport over 3D sea.
## The world is paused until all gameplay inputs are released, preventing a
## held key from immediately steering or accelerating the boat after fishing.

signal catch_finished(success: bool, fish_data: FishData)
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
var wave_power: WavePower


func _ready() -> void:
	hide()
	_minigame.finished.connect(_on_minigame_finished)
	_minigame.catch_size_changed.connect(_on_catch_size_changed)
	# The container supplies viewport mouse input, and holds keyboard focus.
	_container.focus_mode = Control.FOCUS_ALL
	wave_power = WavePower.new()
	wave_power.process_mode = Node.PROCESS_MODE_ALWAYS
	wave_power.can_use = func() -> bool: return active and _minigame.is_running()
	add_child(wave_power)


func start_catch(fish_data: FishData, zone_scale: float = 1.0, size: float = 1.0, count: int = 1) -> void:
	if active or fish_data == null:
		return
	active = true
	_waiting_release = false
	_released_frames = 0
	_fish = fish_data
	_size = size
	_was_paused = get_tree().paused
	_release_notice.hide()
	show()
	get_tree().paused = true
	_container.grab_focus()
	_minigame.start(fish_data, zone_scale, count, size)


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
	get_tree().paused = _was_paused
	catch_detailed.emit(_fish, _caught, _quality, _count, _size)
	catch_finished.emit(_caught, _fish)


func _controls_held() -> bool:
	for action in [&"throttle_forward", &"throttle_back", &"turn_left", &"turn_right",
			&"cast", &"interact", &"drop_net", &"open_hold"]:
		if Input.is_action_pressed(action):
			return true
	return false
