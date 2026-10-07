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
	# Cutscene scripts.
	var tokens := CutsceneScript.tokenize('speak Rin "Ê! Con đó tao định bán mà!"')
	_check("tokenize keeps quoted text", tokens.size() == 3 and tokens[2] == "Ê! Con đó tao định bán mà!")
	_check("tokenize empty quotes", CutsceneScript.tokenize('speak "" "a b"') == PackedStringArray(["speak", "", "a b"]))
	var commands := CutsceneScript.parse("# comment\nfade_in 1.0\n\nchoice \"A\" yes \"B\" no\nlabel yes\nlabel no")
	_check("parse skips comments/blank", commands.size() == 4 and commands[0]["cmd"] == "fade_in")
	_check("labels map", CutsceneScript.labels(commands) == {"yes": 2, "no": 3})
	GameState.set_flag("pet_name", "Bơ")
	_check("fill {pet}", CutsceneScript.fill("{pet}: Meo.") == "Bơ: Meo.")
	GameState.reset()
	_check("pet default name", CutsceneScript.pet_name() == "Mèo")
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
