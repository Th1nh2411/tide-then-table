class_name ChuBayTalk3D
extends NpcTalk3D
## What chú Bảy says (data/story/chu_bay.tres): on an omen day only "Tối nay
## ở nhà đi con."; on mùng 9 after a loop reset he remembers ("Lại gặp con
## rồi..."); then his line of the day; on SKETCH_DAY the last line hands Rin
## the sketch of the way to the raft. Talking once sets MET_FLAG (kept
## through resets: Vy's reveal on mùng 14 reads it).

const LINES: NpcLinesData = preload("res://data/story/chu_bay.tres")
const MET_FLAG := "note_bay_met"
## 3 = mùng 11.
const SKETCH_DAY := 3
const SKETCH_LINE := "Cầm lấy. Chú vẽ đường ra cái bè. Đừng có đi một mình."
const REACH := 2.1


func _init(rig_: PersonRig3D = null) -> void:
	super(rig_, LINES, REACH)
	turn = false
	head_height = 1.1


## His lines for `day`; `omen_id` "" on a calm night, `missed` "" unless mùng 9 after a reset.
static func day_list(day: int, omen_id: String = "", missed: String = "") -> Array[String]:
	if omen_id != "":
		return [LINES.named_line("warn")]
	var out: Array[String] = []
	if missed != "":
		out.append(LINES.named_line("again_calm" if missed == LoopCalendar.MISSED_CALM else "again_omen"))
	out.append_array(LINES.lines_for(day))
	if day == SKETCH_DAY:
		out.append(LINES.format(SKETCH_LINE))
	return out


static func is_sketch_line(line: String) -> bool:
	return line == LINES.format(SKETCH_LINE)


func today() -> Array[String]:
	return day_list(GameState.day, omen_id(), missed_today())


func say() -> String:
	GameState.set_flag(MET_FLAG)
	return super()
