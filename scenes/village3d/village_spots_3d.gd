class_name VillageSpots3D
extends RefCounted
## What E does on the village map outside the restaurant's own stations:
## in Rin's room the thing he looks at (the door, the morning paper, the
## "Những điều kiêng" note, the bed once the shift is over), and down on the
## pier ông Tư's thúng (evening, if he has not been out yet tonight).

const NEWS: NewsData = preload("res://data/story/news.tres")
const KIENG: NoteData = preload("res://data/story/kieng_note.tres")
const REACH := 1.3
const BED_REACH := 1.7
const THUNG_REACH := 2.2
const LOOK_DOT := 0.55
const PROMPTS := {"paper": "E  Đọc báo", "note": "E  Đọc giấy", "bed": "E  Ngủ", "thung": "E  Xuống thúng"}

var host: VillageScene3D


func _init(owner: VillageScene3D) -> void:
	host = owner


## Eye-level points E can aim at, by name.
func points() -> Dictionary:
	var found := {
		"door": host.door.aim_point(),
		"paper": VillageLayout3D.room_point(BedroomBuilder3D.PAPER),
		"note": VillageLayout3D.room_point(BedroomBuilder3D.NOTE),
	}
	if host.shift_over:
		found["bed"] = VillageLayout3D.room_point(BedroomBuilder3D.BED + Vector3(0, 0.5, 0))
	return found


## The thing E acts on now: "door", "paper", "note", "bed", "thung" or "".
func target() -> String:
	if host.player == null or host.demo_camera == null:
		return ""
	if thung_ready() and Walker3D.near(host.player, thung_point(), THUNG_REACH):
		return "thung"
	var best := ""
	var best_dot := LOOK_DOT
	var eye := host.demo_camera.global_position
	var forward := -host.demo_camera.global_basis.z
	var spots := points()
	for what: String in spots:
		var at: Vector3 = spots[what]
		if not Walker3D.near(host.player, at, BED_REACH if what == "bed" else REACH):
			continue
		var dot := forward.dot((at - eye).normalized())
		if dot > best_dot:
			best = what
			best_dot = dot
	return best


func prompt(what: String) -> String:
	if what == "door":
		return "E  Đóng cửa" if host.door.is_open else "E  Mở cửa"
	return PROMPTS.get(what, "")


func act(what: String) -> void:
	match what:
		"door":
			host.door.toggle()
		"paper":
			read_paper()
		"note":
			PaperReader.read(host, "note", KIENG.title, KIENG.body())
		"bed":
			VillageDay3D.sleep(host)
		"thung":
			VillageDay3D.to_sea(host)


## After the shift, before tonight's choice is made.
func thung_ready() -> bool:
	return host.shift_over and not GameState.story_flags.has(LoopCalendar.CHOICE_FLAG)


static func thung_point() -> Vector3:
	return VillageLayout3D.waterfront_point(WaterfrontBuilder3D.THUNG)


## The morning paper; on mùng 9 after a wrong night, one vague line more.
func read_paper() -> void:
	var page := "%s — %s" % [LoopCalendar.date_text(GameState.day), NEWS.page(GameState.day)]
	PaperReader.read(host, "newspaper", NEWS.title, page, paper_hint())


## The boxed line on the mùng 9 paper after a wrong night ("" otherwise).
static func paper_hint() -> String:
	return NEWS.hint(LoopCalendar.missed()) if GameState.day == 1 else ""
