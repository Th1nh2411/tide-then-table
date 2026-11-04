class_name NpcTalk3D
extends RefCounted
## E on a villager: a short subtitle from their NpcLinesData, picked by day
## and how often Rin asked today (deterministic, the same after a loop reset).
## Rin must stand close and look at them. Standing people turn to Rin while
## the line shows (holding()); seated ones (`turn` false) stay put. Each
## line turns Rin's view to their head (LookAtSpeaker3D).

const LOOK_DOT := 0.5
const HOLD_SECONDS := 1.6

var rig: PersonRig3D
var lines: NpcLinesData
var reach := 1.8
## Eye-line height on the rig for the look check (seated people are lower).
var head_height := 1.4
var turn := true
## Where Rin's view turns for a line when there is no rig (a counter, the altar).
var focus := Vector3.INF
## Who they turn to (Rin's body).
var listener: Node3D
## Lines said before the day's own this scene (rằm, tonight's omen...).
var first: Array[String] = []
## Night lines (NpcLinesData.nights) instead of the day's.
var night := false
var talks := 0
var _hold := 0.0


func _init(rig_: PersonRig3D = null, lines_: NpcLinesData = null, reach_: float = 1.8) -> void:
	rig = rig_
	lines = lines_
	reach = reach_


## What they say today, in order (E cycles through it).
func today() -> Array[String]:
	var out: Array[String] = first.duplicate()
	if lines:
		out.append_array(lines.lines_for(GameState.day, omen_id(), missed_today(), night))
	return out


## Tonight's omen id ("" on a calm night).
static func omen_id() -> String:
	var omen := OmenPicker.tonight()
	return omen.id if omen else ""


## What the last wrong night missed, only on mùng 9 after a reset.
static func missed_today() -> String:
	return LoopCalendar.missed() if GameState.day == 1 and LoopCalendar.loops() > 0 else ""


## Rin stands close and (when there is a camera) looks at them.
func can_talk(rin: Vector3, camera: Camera3D) -> bool:
	if rig == null or not rig.is_inside_tree() or not rig.is_visible_in_tree():
		return false
	var flat := rig.global_position - rin
	flat.y = 0.0
	if flat.length() > reach or today().is_empty():
		return false
	if camera == null:
		return true
	var head := rig.global_position + Vector3(0, head_height, 0)
	return (-camera.global_basis.z).dot((head - camera.global_position).normalized()) > LOOK_DOT


## The next line ("" when they have nothing today).
func say() -> String:
	var all := today()
	if all.is_empty():
		return ""
	var words := all[talks % all.size()]
	talks += 1
	_hold = HOLD_SECONDS
	if rig:
		LookAtSpeaker3D.person(rig, head_height + 0.1)
	elif focus != Vector3.INF:
		LookAtSpeaker3D.at(focus)
	return words


## True while they stand still for Rin (turned to him).
func holding(delta: float) -> bool:
	if _hold <= 0.0:
		return false
	_hold -= delta
	if turn and rig and listener:
		var to: Vector3 = listener.global_position - rig.global_position
		var parent := rig.get_parent_node_3d()
		if parent:
			to = parent.global_basis.inverse() * to
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(to.x, to.z), 0.25)
	return true
