class_name NpcLinesData
extends Resource
## A villager's E lines (PLAN §10 "Mọi nhân vật đều có vai trò"): one entry
## per day (index 0 = mùng 9), "|" splits a day's entry into the lines said
## on each E in turn (cycling). Same day = same lines, also after a loop
## reset; only `after_reset` (mùng 9 after a wrong night) and tonight's omen
## put a line in front. `speaker` prefixes each line ("Bảo: ...").

@export var speaker: String = ""
@export_multiline var days: Array[String] = []
## Used instead of `days` at night when not empty (chú Hai by his door).
@export_multiline var nights: Array[String] = []
## Tonight's omen id -> a line said first that day.
@export var omen_lines: Dictionary = {}
## The same, at night only (after the omen has played).
@export var night_omen_lines: Dictionary = {}
## Mùng 9 after a loop reset: LoopCalendar.missed() id -> the first line.
@export var after_reset: Dictionary = {}
## Extra lines the owner code asks for by key.
@export var named: Dictionary = {}


## The day's lines, formatted. `missed` is "" unless this is mùng 9 after a reset.
func lines_for(day: int, omen_id: String = "", missed: String = "", night: bool = false) -> Array[String]:
	var out: Array[String] = []
	if missed != "" and after_reset.has(missed):
		out.append(format(str(after_reset[missed])))
	if night and night_omen_lines.has(omen_id):
		out.append(format(str(night_omen_lines[omen_id])))
	elif omen_lines.has(omen_id):
		out.append(format(str(omen_lines[omen_id])))
	var pool := nights if night and not nights.is_empty() else days
	var index := day - 1
	if index >= 0 and index < pool.size():
		for part: String in pool[index].split("|", false):
			if part.strip_edges() != "":
				out.append(format(part.strip_edges()))
	return out


## True when the day has an own entry (absent days are "").
func has_day(day: int, night: bool = false) -> bool:
	return not lines_for(day, "", "", night).is_empty()


func named_line(key: String) -> String:
	return format(str(named[key])) if named.has(key) else ""


func format(text: String) -> String:
	return "%s: %s" % [speaker, text] if speaker != "" else text
