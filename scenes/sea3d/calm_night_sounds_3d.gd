class_name CalmNightSounds3D
extends Node3D
## False sounds on a calm night at sea (research 2.1 / 3.3): now and then
## something harmless but uncertain, placed in the world around the thúng —
## a fish slapping the water out of sight, the paddle knocking the thúng once,
## the bobber twitching with no bite, a far splash. Rare (one every 25-60 s,
## a little more often as the loop's dread grows), never the đêm âm knock.
## Added by SeaSetup3D only on calm nights (not omen nights, not rằm).

const NODE_NAME := "CalmNightSounds"
const KINDS: Array[String] = ["slap", "tock", "twitch", "far_splash"]

@export var gap_min := 25.0
@export var gap_max := 60.0
## At full dread (LoopCalendar.dread_level) the longest gap shrinks to this.
@export var gap_max_at_dread := 40.0
@export var first_after := 20.0
@export var slap_distance := Vector2(7.0, 13.0)
@export var far_distance := Vector2(24.0, 34.0)

var sea: SeaScene3D
## What played, in order (tests).
var played: Array[String] = []
var _left := 0.0
var _rng := RandomNumberGenerator.new()


static func attach(host: SeaScene3D) -> CalmNightSounds3D:
	if GameState.has_flag(LoopCalendar.OMEN_FLAG) or RamNight.is_ram():
		return null
	var sounds := CalmNightSounds3D.new()
	sounds.name = NODE_NAME
	sounds.sea = host
	host.add_child(sounds)
	return sounds


func _ready() -> void:
	_rng.randomize()
	_left = first_after


func _process(delta: float) -> void:
	if sea.ending:
		return
	_left -= delta
	if _left <= 0.0:
		play(KINDS[_rng.randi() % KINDS.size()])
		_left = next_gap()


## Seconds to the next false sound (dread shortens the longest gaps).
func next_gap() -> float:
	var longest := lerpf(gap_max, gap_max_at_dread, LoopCalendar.dread_level())
	return _rng.randf_range(gap_min, maxf(longest, gap_min))


func play(kind: String) -> void:
	var boat := sea.boat.global_position
	match kind:
		"slap":  # out of sight: behind or beside Rin
			Sfx.play_at("slap", _around(boat, slap_distance, true), sea, _rng.randf_range(0.9, 1.15))
		"tock":
			Sfx.play_at("tock", boat + Vector3(_rng.randf_range(-0.6, 0.6), 0.2, 0.6), sea, _rng.randf_range(0.9, 1.1), 2.0)
		"twitch":  # only with the line out and nothing biting: no "!"
			var rod := sea.rod
			if rod == null or rod.state != Fishing3D.State.WAITING:
				kind = "far_splash"
			else:
				rod.rod.shake = maxf(rod.rod.shake, 0.3)
				Sfx.play_at("plip", rod.target, sea, 1.0, 3.0)
	if kind == "far_splash":
		Sfx.play_at("splash", _around(boat, far_distance, false), sea, 0.8, 8.0)
	played.append(kind)


## A point on the water `span` metres away; `hidden` keeps it off the view.
func _around(from: Vector3, span: Vector2, hidden: bool) -> Vector3:
	var angle := _rng.randf() * TAU
	var camera := get_viewport().get_camera_3d()
	if hidden and camera:
		var back := camera.global_basis.z
		angle = atan2(back.x, back.z) + _rng.randf_range(-1.3, 1.3)
	var dir := Vector3(sin(angle), 0, cos(angle))
	return Vector3(from.x, SeaWater3D.WATER_Y, from.z) + dir * _rng.randf_range(span.x, span.y)
