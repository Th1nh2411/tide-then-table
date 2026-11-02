extends Node3D
## Standalone test for đêm rằm (F6): RamNight's ending table, the tea flag,
## ông Tư's line by clue count, the lines data, and the rằm-only nodes
## (no anh Út / sea node / errand on other days).


func _ready() -> void:
	var failures := 0
	GameState.reset()
	var E := RamNight.Ending
	failures += _check("home -> loop", RamNight.ending(false, false, false) == E.LOOP)
	failures += _check("drank + home -> loop", RamNight.ending(true, false, false) == E.LOOP)
	failures += _check("drank + out -> drowned", RamNight.ending(true, true, false) == E.DROWNED)
	failures += _check("drank + out, even seen -> drowned", RamNight.ending(true, true, true) == E.DROWNED)
	failures += _check("refused + out + raft seen -> true", RamNight.ending(false, true, true) == E.TRUE)
	failures += _check("refused + out, came back early -> loop", RamNight.ending(false, true, false) == E.LOOP)
	failures += _check("only the last night is rằm", RamNight.is_ram(LoopCalendar.NIGHTS) and not RamNight.is_ram(LoopCalendar.NIGHTS - 1))
	failures += _check("no tea answer = not drank", not RamNight.drank() and not RamNight.tea_answered())
	RamNight.set_tea(true)
	failures += _check("tea drunk is stored", RamNight.drank() and RamNight.tea_answered())
	RamNight.set_tea(false)
	failures += _check("tea refused is stored", not RamNight.drank() and RamNight.tea_answered())
	GameState.day = LoopCalendar.NIGHTS
	failures += _check("current: refused, out, unseen -> loop", RamNight.current(true) == E.LOOP)
	RamNight.finish(E.TRUE)
	failures += _check("finish true marks the recording + ending", GameState.has_flag(RamNight.EXPOSED_FLAG) and RamNight.ending_id() == "true")
	failures += _check("current after the raft -> true", RamNight.current(true) == E.TRUE)
	RamNight.finish(E.DROWNED)
	failures += _check("finish drowned", RamNight.ending_id() == "drowned")
	failures += _check("ông Tư speaks with enough clues", RamNight.grandpa_speaks(RamNight.CLUES_FOR_GRANDPA)
		and not RamNight.grandpa_speaks(RamNight.CLUES_FOR_GRANDPA - 1))
	RamNight.speed = 4.0
	failures += _check("speed scales seconds", is_equal_approx(RamNight.secs(2.0), 0.5))
	RamNight.speed = 1.0
	var lines: RamLinesData = RamFx3D.LINES
	failures += _check("lines: offer, answers, endings", not lines.ut_offer.is_empty() and not lines.ut_drank.is_empty()
		and not lines.ut_refused.is_empty() and not lines.dawn.is_empty() and not lines.drowned.is_empty()
		and lines.grandpa.begins_with("Ông Tư:") and not lines.card_true.is_empty() and not lines.card_drowned.is_empty())
	var parsed := RamLinesData.parse(lines.ut_offer)
	failures += _check("offer lines are anh Út's", parsed.size() == lines.ut_offer.size() and str(parsed[0]["speaker"]) == "Anh Út")
	failures += _check("no NEO / phone on rằm", not "\n".join(lines.dawn + lines.ut_seen + lines.whispers_trail).contains("NEO"))
	GameState.day = 3
	failures += _check("no rằm shore before rằm", RamShore3D.attach(self) == null)
	GameState.day = LoopCalendar.NIGHTS
	var shore := RamShore3D.attach(self)
	failures += _check("rằm shore has lanterns", shore != null and shore.lanterns.size() > 0)
	if shore:
		shore.release()
		failures += _check("a lantern is released", shore.lanterns.size() > 8)
		shore.queue_free()
	GameState.reset()
	print("RAM NIGHT TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
