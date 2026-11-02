extends Control
## Standalone test for the dialogue base (run with F6): script parsing,
## conditions (day, flag, once), priority and the seen/sets flags.

var _failures: int = 0


func _ready() -> void:
	GameState.reset()
	var lines := DialogueLibrary.parse("Bảo: Ê Rin!\n\n  Rin: ...Bảo?  \nGió thổi qua bến, mùi muối mặn: buổi sáng yên ắng lạ thường.")
	_check("parse: 3 lines, empty skipped", lines.size() == 3)
	_check("parse: speaker + text", lines[0]["speaker"] == "Bảo" and lines[0]["text"] == "Ê Rin!")
	_check("parse: trims", lines[1]["speaker"] == "Rin" and lines[1]["text"] == "...Bảo?")
	_check("parse: long prefix = narration", lines[2]["speaker"] == "")

	var intro := _dialogue("intro", 1, "", true, 10)
	var later := _dialogue("later", 3, "", true, 5)
	var omen := _dialogue("omen", 1, "seen_omen", true, 20)
	var chat := _dialogue("chat", 1, "", false, 0)
	var all: Array[Dialogue] = [chat, later, intro, omen]
	_check("pick highest priority eligible", DialogueLibrary.pick(all) == intro)
	DialogueLibrary.mark_done(intro)
	_check("once: not again", not DialogueLibrary.can_play(intro) and DialogueLibrary.pick(all) == chat)
	GameState.day = 3
	_check("min_day unlocks", DialogueLibrary.pick(all) == later)
	GameState.set_flag("seen_omen")
	_check("flag unlocks, priority wins", DialogueLibrary.pick(all) == omen)
	omen.sets_flag = "talked_omen"
	DialogueLibrary.mark_done(omen)
	_check("sets_flag on finish", GameState.has_flag("talked_omen"))
	DialogueLibrary.mark_done(chat)
	_check("repeatable stays", DialogueLibrary.can_play(chat))
	var early := _dialogue("early", 1, "", true, 50)
	early.blocked_by_flag = "grown_up"
	_check("blocked_by_flag: plays before", DialogueLibrary.can_play(early))
	GameState.set_flag("grown_up")
	_check("blocked_by_flag: not after", not DialogueLibrary.can_play(early))
	GameState.reset()
	print("Dialogue: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _dialogue(id: String, min_day: int, flag: String, once: bool, priority: int) -> Dialogue:
	var d := Dialogue.new()
	d.id = id
	d.min_day = min_day
	d.requires_flag = flag
	d.once = once
	d.priority = priority
	d.script_text = "Bảo: %s" % id
	return d


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
