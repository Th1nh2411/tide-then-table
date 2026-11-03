class_name SeaScene3D
extends Node3D
## Night trip in 3D (horror build): the thúng, lamp oil, hull, first-person
## rod fishing into a basket. No money, upgrades, weather, nets, phone or
## visitable places. Orchestrator: world -> SeaWorldBuilder3D, rod + basket ->
## Fishing3D, HUD/navigation -> SeaHud3D, steering -> SeaBoatMover3D,
## oil / trip end -> SeaTrip3D, debug keys -> SeaDebug3D.

const ENDING_SCENE := SeaTrip3D.ENDING_SCENE
const CAMERA_OFFSET := Vector3(0,6.2,8.4)
const CAMERA_LOOK_AHEAD := 1.8
const OIL_BURN_PER_SECOND: float = 100.0 / 240.0

@export var fish_catalog: FishCatalog
## The boat is fixed (no upgrades): the thúng.
@export var boat_data: BoatData
## Lamp oil per night (100 = OIL_BURN_PER_SECOND burns it in 240 s).
@export var oil_capacity := 100.0

@onready var boat: CharacterBody3D = $Boat
@onready var boat_visual: Node3D = $Boat/BoatVisual
@onready var camera: Camera3D = $Camera3D

var oil := 100.0
var oil_low_sent := false
## Extra oil burn (đêm âm: DarkNight3D).
var oil_burn_scale := 1.0
# Same layout as the 2D sea (SeaLayout3D); shoals are rolled each night (SeaShoals3D).
var START: Vector3 = SeaLayout3D.to_world(SeaLayout3D.DOCK_PX)
var SHRINE_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.SHRINE_PX)
var LIGHTHOUSE_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.LIGHTHOUSE_PX)
var HUT_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.HUT_PX)
var RAFT_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.RAFT_PX)
var WHIRLPOOL_POS: Vector3 = SeaLayout3D.to_world(SeaLayout3D.WHIRLPOOL_PX)
var shoals: Array[SeaShoals3D.Shoal] = []
var _wait_controls_release := false
var _application_focused := true
var navigation: Control
var yaw_velocity := 0.0
## Paddle strokes of a rowed boat (thúng); its phase also poses Rin and the paddle.
var row := RowStroke.new()
var paddle: Node3D
var impact_cooldown := 0.0
## Bounce, spin, rocking, shake and splash of collisions (SeaBoatMover3D calls it).
var impact := SeaBoatImpact3D.new()
var elapsed := 0.0
## True while the line is out (Fishing3D): the boat holds still.
var fishing := false
var ending := false
var status := ""
var status_until := 0.0
var _said: Array[Array] = []
var rng := RandomNumberGenerator.new()
var hud_view: SeaHudView3D
## Current Rin's line (hidden; hud_view's speech strip shows it).
var message: Label
var bubble_spots: Array[BubbleSpot3D] = []
var submerged: Array[SubmergedRock3D] = []
var rin_figure: Array[Node3D] = []
var wake_marks: Array[MeshInstance3D] = []
var boat_lamp: SpotLight3D
## The rod, the bobber and the basket (Fishing3D).
var rod: Fishing3D
## Always false now (no place dialogs); DarkNight3D still reads it.
var poi_busy := false
var whirlpool_marks: Array[MeshInstance3D] = []
## 0..1: how deep the boat is in the sea's edge band (SeaEdge3D).
var edge_amount := 0.0

func _ready() -> void:
	StylePass3D.set_phase("sea")
	rng.randomize()
	if boat_data == null:
		boat_data = load("res://data/boats/thuyen_thung.tres") as BoatData
	oil = oil_capacity
	boat.position = START
	shoals = SeaShoals3D.spawn(fish_catalog, rng, Story.is_fog_open())
	SeaWorldBuilder3D.build_environment(self)
	SeaWorldBuilder3D.build_world(self)
	SeaWorldBuilder3D.build_pois(self)
	SeaWorldBuilder3D.build_boat(self)
	SeaHud3D.build_hud(self)
	SeaHud3D.build_shared_ui(self)
	SeaSetup3D.build_tools(self)
	SeaHud3D.build_navigation(self)
	FallSafety3D.attach(self, boat)
	DayClock.start_night()
	var fog_tonight := Story.check_day()
	# Saves happen in the morning only (horror build): a night is judged when Rin wakes.
	Sfx.ambience("sea")
	Sfx.bed("sea")
	_night_start_lines(fog_tonight)
	_update_hud()

func _night_start_lines(fog_tonight: bool) -> void:
	SeaTrip3D.night_start_lines(self, fog_tonight)

func _physics_process(delta: float) -> void:
	if ending:
		return
	if fishing:
		# The lamp still burns while Rin waits on a bite.
		if not _at_dock():
			_spend_oil(delta * OIL_BURN_PER_SECOND * oil_burn_scale)
		return
	elapsed += delta
	var motion := SeaBoatMover3D.drive(self, delta)
	if motion.is_empty():
		return
	var forward: Vector3 = motion[0]
	var forward_speed: float = motion[1]
	SeaWorldBuilder3D.animate(self, delta, forward, forward_speed)
	impact.apply(self, delta)
	if not _at_dock():
		_spend_oil(delta * OIL_BURN_PER_SECOND * oil_burn_scale)
	if GameState.boat_hp <= 0.0:
		_end_trip(true)
		return
	if Story.is_fog_open() and boat.position.distance_to(WHIRLPOOL_POS) < 2.0:
		_enter_whirlpool()
		return
	if oil <= 0.0:
		_say("Đèn tắt rồi... phải lần về bến thôi.", 3.0)
		_end_trip(true)
		return
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if SeaDebug3D.handle(self, event as InputEventKey):
		get_viewport().set_input_as_handled()
		return
	if ending or fishing or get_tree().paused:
		return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_R and _at_dock():
		_end_trip(false)
	elif key.physical_keycode == KEY_F and _at_dock():
		if BoatCondition.is_damaged():
			BoatCondition.repair()
			_say("Vá xong mạn thúng.", 2.5)
		else:
			_say("Thúng còn lành.", 2.0)
	else:
		return
	get_viewport().set_input_as_handled()

func _at_dock() -> bool:
	return boat.position.distance_to(START) < 4.0 and boat.velocity.length() < 2.0

func _enter_whirlpool() -> void:
	SeaTrip3D.enter_whirlpool(self)

## Lamp reach for bubbles and submerged rocks: shrinks as the oil runs low.
func _bubble_range() -> float:
	var fraction := oil / maxf(oil_capacity, 1.0)
	var base: float = boat_lamp.spot_range if is_instance_valid(boat_lamp) else 14.0
	return base * 0.6 * lerpf(0.55, 1.0, clampf(fraction * 2.0, 0.0, 1.0))


func _end_trip(towed: bool) -> void:
	SeaTrip3D.end_trip(self, towed)

## Rin's line; waits for the current one to finish (one bubble at a time).
func _say(text: String, seconds: float) -> void:
	if message.text != "" and Time.get_ticks_msec() / 1000.0 < status_until:
		if text != status and _said.size() < 4:
			_said.append([text, seconds])
		return
	status = text
	status_until = Time.get_ticks_msec() / 1000.0 + seconds
	message.text = status

## Called from the HUD tick: shows the next queued line once the last one ends.
func _next_line() -> void:
	if Time.get_ticks_msec() / 1000.0 <= status_until:
		return
	message.text = ""
	if not _said.is_empty():
		var line: Array = _said.pop_front()
		_say(str(line[0]), float(line[1]))

func _update_hud() -> void:
	SeaHud3D.update(self)

func _movement_controls_held() -> bool:
	return Input.is_action_pressed("throttle_forward") or Input.is_action_pressed("throttle_back") or Input.is_action_pressed("turn_left") or Input.is_action_pressed("turn_right")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_application_focused = false
		_wait_controls_release = true
		if is_instance_valid(boat):
			boat.velocity = Vector3.ZERO
			yaw_velocity = 0.0
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_application_focused = true


func _spend_oil(units: float) -> void:
	SeaTrip3D.spend_oil(self, units)


func _casts_used_total() -> int:
	var used := 0
	for shoal in shoals:
		used += shoal.max_fish - shoal.fish_left
	return used


func _nearest_school_index() -> int:
	var nearest := -1
	var distance := INF
	var min_z := SeaLayout3D.reach_z(boat_data.max_depth)
	for i in range(shoals.size()):
		var spot: Vector3 = shoals[i].pos
		if spot.z < min_z or shoals[i].fish_left <= 0:
			continue
		var d := boat.position.distance_to(spot)
		if d < distance:
			distance = d
			nearest = i
	return nearest


func navigation_targets() -> Array[Dictionary]:
	return SeaHud3D.navigation_targets(self)
