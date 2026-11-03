class_name VyTalk3D
extends RefCounted
## E on Vy: one short subtitle, picked by day and how often Rin asked today
## (deterministic). From LATE_DAY her first line of the day is a quiet uneasy
## one (data/story/vy_late.tres). She stops and faces Rin while she talks.

const LINES: LinesData = preload("res://data/story/vy.tres")
const LATE: LinesData = preload("res://data/story/vy_late.tres")
const LATE_DAY := 5
const REACH := 1.8
const LOOK_DOT := 0.5
const HOLD_SECONDS := 1.6

var vy: VyStaff3D
var talks := 0
var _hold := 0.0


func _init(owner: VyStaff3D) -> void:
	vy = owner


## The line for `day` (1 = mùng 9) and the n-th talk of that day.
static func line_for(day: int, n: int) -> String:
	if day >= LATE_DAY and n == 0:
		return LATE.line(day - LATE_DAY)
	return LINES.line((day - 1) * 2 + n)


## Rin stands close and (when there is a camera) looks at her.
func can_talk(rin: Vector3, camera: Camera3D) -> bool:
	if not vy.present() or rin.distance_to(vy.rig.position) > REACH:
		return false
	if camera == null:
		return true
	var head := vy.rig.global_position + Vector3(0, 1.4, 0)
	return (-camera.global_basis.z).dot((head - camera.global_position).normalized()) > LOOK_DOT


func say() -> String:
	var words := line_for(GameState.day, talks)
	talks += 1
	_hold = HOLD_SECONDS
	return words


## True while she stands still for Rin (turned to him).
func holding(delta: float) -> bool:
	if _hold <= 0.0:
		return false
	_hold -= delta
	var to: Vector3 = vy.host.player.position - vy.rig.position
	vy.rig.rotation.y = lerp_angle(vy.rig.rotation.y, atan2(to.x, to.z), 0.25)
	return true
