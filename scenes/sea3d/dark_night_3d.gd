class_name DarkNight3D
extends Node3D
## "Đêm âm" (PLAN §10): Rin went out on a night with an omen. Added by
## SeaSetup3D only when LoopCalendar.OMEN_FLAG is set, so calm nights are
## untouched. Turns the sea wrong (DarkNightLook), burns oil faster, darker
## HorrorBed mix, then haunts the edge of the lamp: knocks on the hull,
## whispers, static, a figure on the water, eyes gliding past. After a
## while away from the dock, far out, low on oil or after a catch, the sea
## takes him (SeaTrip3D.taken_by_the_sea); the bedroom then resets the loop.

const NODE_NAME := "DarkNight"
const BED := "sea_dark"
const WHISPERS: Array[String] = ["...về đi...", "...đừng ra xa...", "...hắn đang ở ngoài này..."]

@export var look: DarkNightLook = DarkNightLook.new()
@export var oil_burn_scale := 2.2
@export_group("Haunting")
@export var first_event_seconds := 7.0
@export var event_gap_min := 6.0
@export var event_gap_max := 11.0
## Gaps shrink towards this fraction as the end gets close.
@export var event_gap_end_scale := 0.45
@export var figure_angle_min_deg := 35.0
@export var figure_angle_max_deg := 60.0
@export var figure_reach_scale := 0.9
@export var blink_seconds := 0.15
## Knocks: near silence first (Sfx.duck), then the knuckles on the hull side
## facing the raft (a 3D sound), this many seconds into the duck.
@export var knock_duck_seconds := 1.7
@export var knock_after := 1.0
@export_group("Dread by day")
## LoopCalendar.dread_level(): below this (mùng 9-10) only sounds, no figures.
@export var figures_from_dread := 0.3
## Below this (before 13 tháng Bảy) figures keep at least far_figure_distance away.
@export var close_from_dread := 0.6
@export var far_figure_distance := 15.0
@export_group("Taken")
## Seconds away from the dock (not fishing / visiting) before the sea takes him.
@export var taken_after_seconds := 60.0
@export var taken_distance := 55.0
@export var taken_oil_fraction := 0.2
@export var taken_after_catch_seconds := 3.0
## >1 plays the ending faster (tests).
@export var taken_speed := 1.0

var sea: SeaScene3D
var away_seconds := 0.0
var taken := false
var _next_event := 0.0
var _catch_timer := 0.0
var _after_catch := false
var _cycles := 0
var _was_fishing := false
var _events: Array[String] = []
var _said: Dictionary = {}
var _moon: Node3D
var _rng := RandomNumberGenerator.new()


## Adds the đêm âm node to `sea` when tonight has an omen; null otherwise.
static func attach(host: SeaScene3D) -> DarkNight3D:
	if not GameState.has_flag(LoopCalendar.OMEN_FLAG):
		return null
	var dark := DarkNight3D.new()
	dark.name = NODE_NAME
	dark.sea = host
	host.add_child(dark)
	return dark


static func active(host: Node) -> DarkNight3D:
	return host.get_node_or_null(NODE_NAME) as DarkNight3D


func _ready() -> void:
	_rng.randomize()
	_next_event = first_event_seconds
	look.apply(sea)
	_moon = look.build_moon(self)
	sea.oil_burn_scale *= oil_burn_scale
	_start_sound.call_deferred()


## After the sea's own Sfx.bed("sea") in its _ready.
func _start_sound() -> void:
	Sfx.bed(BED)
	_say_once("start", "Biển đêm nay... im quá.", 3.0)


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera and _moon:
		_moon.global_position = camera.global_position + look.moon_direction(sea) * look.moon_distance
	if taken or sea.ending:
		return
	if sea.fishing or sea.poi_busy:
		_was_fishing = sea.fishing
		return
	if _was_fishing:
		_was_fishing = false
		_after_catch = true
		_catch_timer = taken_after_catch_seconds
	if not sea._at_dock():
		away_seconds += delta
	_next_event -= delta
	if _next_event <= 0.0:
		_haunt()
		_next_event = _rng.randf_range(event_gap_min, event_gap_max) * lerpf(1.0, event_gap_end_scale, progress())
	if _after_catch:
		_catch_timer -= delta
	if should_take():
		take()


## 0..1 towards the end of the night (the strongest of the triggers).
func progress() -> float:
	var oil_fraction := sea.oil / maxf(sea.oil_capacity, 1.0)
	return clampf(maxf(maxf(away_seconds / taken_after_seconds,
		sea.boat.position.distance_to(sea.START) / taken_distance),
		inverse_lerp(1.0, taken_oil_fraction, oil_fraction)), 0.0, 1.0)


func should_take() -> bool:
	return progress() >= 1.0 or (_after_catch and _catch_timer <= 0.0)


func take() -> void:
	if taken:
		return
	taken = true
	SeaTrip3D.taken_by_the_sea(sea)


## The ending's visuals (SeaTrip3D.taken_by_the_sea awaits this).
func play_taken() -> void:
	await DarkNightTaken3D.play(sea, taken_speed)


func _haunt() -> void:
	if _events.is_empty():
		_events = event_pool()
		if _cycles > 0:
			_events.shuffle()
		_cycles += 1
	var event: String = _events.pop_front()
	match event:
		"knock":
			Sfx.duck(knock_duck_seconds)
			create_tween().tween_callback(_knock).set_delay(knock_after)
		"whisper":
			Sfx.play("whisper", 0.1)
			sea._say(WHISPERS[_rng.randi() % WHISPERS.size()], 2.0)
		"static":
			Sfx.play("static")
			_blink()
			_say_once("static", "Cái gì... rè rè trong tai vậy?", 2.5)
		"figure", "swim":
			_spawn_figure(DarkNightFigure3D.Kind.STAND if event == "figure" else DarkNightFigure3D.Kind.SWIM)


## Tonight's haunting events; early in the loop (dread) only sounds.
func event_pool() -> Array[String]:
	if LoopCalendar.dread_level() < figures_from_dread:
		return ["knock", "whisper", "static"]
	return ["knock", "figure", "whisper", "swim", "static"]


## Knuckles on the hull, on the side facing the raft.
func _knock() -> void:
	if taken:
		return
	var to_raft := sea.RAFT_POS - sea.boat.global_position
	to_raft.y = 0.0
	Sfx.play_at("knock3", sea.boat.global_position + to_raft.normalized() * 0.9 + Vector3(0, 0.2, 0), sea, 1.0, 3.0)
	_say_once("knock", "Ai... gõ mạn thúng vậy?", 2.5)


## How far out a figure stands: at the lamp's edge, or far off early in the loop.
func figure_distance(lamp_reach: float) -> float:
	if LoopCalendar.dread_level() < close_from_dread:
		return maxf(lamp_reach, far_figure_distance)
	return lamp_reach


func _spawn_figure(kind: DarkNightFigure3D.Kind) -> void:
	var camera := get_viewport().get_camera_3d()
	var forward := -camera.global_basis.z if camera else Vector3.FORWARD.rotated(Vector3.UP, sea.boat.rotation.y)
	forward.y = 0.0
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var angle := deg_to_rad(_rng.randf_range(figure_angle_min_deg, figure_angle_max_deg)) * side
	var reach := figure_distance(sea.boat_lamp.spot_range * figure_reach_scale if is_instance_valid(sea.boat_lamp) else 12.0)
	var figure := DarkNightFigure3D.new()
	figure.kind = kind
	var dir := forward.normalized().rotated(Vector3.UP, angle)
	figure.swim_dir = dir.rotated(Vector3.UP, PI * 0.5 * side)
	add_child(figure)
	figure.global_position = Vector3(sea.boat.position.x, SeaWater3D.WATER_Y, sea.boat.position.z) + dir * reach
	figure.vanished.connect(_on_figure_vanished.bind(kind))


func _on_figure_vanished(seen: bool, kind: DarkNightFigure3D.Kind) -> void:
	if not seen or taken:
		return
	Sfx.play("static", 0.2)
	if kind == DarkNightFigure3D.Kind.STAND:
		_say_once("figure", "Vừa có ai... đứng trên mặt nước?", 2.5)
	else:
		_say_once("swim", "Cái gì vừa lặn xuống vậy?", 2.5)


## Lamp goes out for a blink (visibility only: the oil code sets its energy).
func _blink() -> void:
	var lamp := sea.boat_lamp
	if not is_instance_valid(lamp):
		return
	lamp.visible = false
	await get_tree().create_timer(blink_seconds).timeout
	if is_instance_valid(lamp) and not taken:
		lamp.visible = true


func _say_once(id: String, line: String, seconds: float) -> void:
	if _said.has(id):
		return
	_said[id] = true
	sea._say(line, seconds)
