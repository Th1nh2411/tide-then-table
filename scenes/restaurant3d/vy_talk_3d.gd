class_name VyTalk3D
extends NpcTalk3D
## E on Vy (NpcTalk3D with her own order): from LATE_DAY a quiet uneasy line
## first (data/story/vy_late.tres), then what she overheard from the guests
## today (a clue, data/story/vy_heard.tres), then her two small-talk lines
## of the day (data/story/vy.tres). Deterministic by day and talk count.

const LINES: LinesData = preload("res://data/story/vy.tres")
const LATE: LinesData = preload("res://data/story/vy_late.tres")
const HEARD: NpcLinesData = preload("res://data/story/vy_heard.tres")
const LATE_DAY := 5
const REACH := 1.8

var vy: VyStaff3D


func _init(owner: VyStaff3D) -> void:
	super(owner.rig, HEARD, REACH)
	vy = owner
	listener = owner.host.get("player") as Node3D


## The line for `day` (1 = mùng 9) and the n-th talk of that day.
static func line_for(day: int, n: int) -> String:
	var all := day_list(day)
	return all[n % all.size()]


static func day_list(day: int) -> Array[String]:
	var out: Array[String] = []
	if day >= LATE_DAY:
		out.append(LATE.line(day - LATE_DAY))
	out.append_array(HEARD.lines_for(day))
	out.append(LINES.line((day - 1) * 2))
	out.append(LINES.line((day - 1) * 2 + 1))
	return out


func today() -> Array[String]:
	return day_list(GameState.day)


func can_talk(rin: Vector3, camera: Camera3D) -> bool:
	return vy.present() and super(rin, camera)
