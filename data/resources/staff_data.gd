class_name StaffData
extends Resource
## Someone Rin can hire for the restaurant: carries Bảo's plates from the
## plate table to the tables and cleans dirty tables (StaffWorker). Own
## skills and wage. One .tres per person in res://data/staff/.

@export var id: String = ""
@export var display_name: String = ""
## Who answers which job ad (StaffCatalog.ads): 1 = flyer ... 3 = job centre.
@export var tier: int = 1
## Paid at the end of every shift worked.
@export var wage: int = 150
## Walking speed (px/s; Rin walks 95).
@export var walk_speed: float = 80.0
@export var clean_seconds: float = 0.6
## Extra tip share while they work (0.1 = +10% of the bill).
@export var tip_bonus: float = 0.0
@export var body_color: Color = Color(0.6, 0.4, 0.7)
## Their line when applying.
@export var pitch: String = ""
## Comes asking for the job by themselves on this day (0 = only via an ad).
@export var arrives_on_day: int = 0
## Conversations while they work here (E next to them; "!" when new), and
## small talk once those are used up.
@export var dialogues: Array[Dialogue] = []
@export_multiline var idle_lines: Array[String] = []
## Small talk after this story flag is set (Vy warming up: "vy_warmed").
@export var later_flag: String = ""
@export_multiline var later_idle_lines: Array[String] = []


## "đi nhanh · dọn nhanh · tip +10%" from the numbers.
func skill_text() -> String:
	var parts: PackedStringArray = []
	parts.append("đi nhanh" if walk_speed >= 100.0 else ("đi chậm" if walk_speed < 75.0 else "đi vừa"))
	parts.append("dọn nhanh" if clean_seconds <= 0.4 else ("dọn chậm" if clean_seconds >= 0.7 else "dọn vừa"))
	if tip_bonus > 0.0:
		parts.append("tip +%d%%" % roundi(tip_bonus * 100.0))
	return " · ".join(parts)
