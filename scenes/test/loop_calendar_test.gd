extends Node
## Standalone test for LoopCalendar (run with F6): lunar dates, the right
## street end with and without an omen, reset to mùng 9 keeping only Rin's
## notebook / tips / loop count, and rằm judged by RamNight.


func _ready() -> void:
	var failures := 0
	GameState.reset()
	failures += _check("day 1 = mùng 9", LoopCalendar.date_text(1) == "Mùng 9 tháng Bảy")
	failures += _check("day 3 = 11", LoopCalendar.date_text(3) == "11 tháng Bảy")
	failures += _check("day 7 = rằm", LoopCalendar.date_text(7) == "Rằm tháng Bảy")
	failures += _check("no choice -> none", LoopCalendar.take_result() == LoopCalendar.Result.NONE)
	LoopCalendar.choose(true)
	failures += _check("calm night, out -> next", LoopCalendar.take_result() == LoopCalendar.Result.NEXT)
	failures += _check("choice is read once", LoopCalendar.take_result() == LoopCalendar.Result.NONE)
	LoopCalendar.choose(false)
	failures += _check("calm night, home -> reset", LoopCalendar.take_result() == LoopCalendar.Result.RESET)
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	LoopCalendar.choose(false)
	failures += _check("omen, home -> next", LoopCalendar.take_result() == LoopCalendar.Result.NEXT)
	LoopCalendar.choose(true)
	failures += _check("omen, out -> reset", LoopCalendar.take_result() == LoopCalendar.Result.RESET)
	LoopCalendar.next_day()
	failures += _check("next day clears the omen", GameState.day == 2 and not GameState.has_flag(LoopCalendar.OMEN_FLAG))
	GameState.day = LoopCalendar.NIGHTS
	LoopCalendar.choose(true)
	failures += _check("rằm, out without the recording -> reset", LoopCalendar.take_result() == LoopCalendar.Result.RESET)
	LoopCalendar.choose(false)
	failures += _check("rằm, home -> reset (the gate closes)", LoopCalendar.take_result() == LoopCalendar.Result.RESET)
	RamNight.set_tea(true)
	LoopCalendar.choose(false)
	failures += _check("rằm, drank + home -> reset", LoopCalendar.take_result() == LoopCalendar.Result.RESET)
	LoopCalendar.choose(true)
	failures += _check("rằm, drank + out -> end", LoopCalendar.take_result() == LoopCalendar.Result.END)
	RamNight.set_tea(false)
	GameState.set_flag(RamNight.EXPOSED_FLAG)
	LoopCalendar.choose(true)
	failures += _check("rằm, refused + recorded -> end", LoopCalendar.take_result() == LoopCalendar.Result.END)
	GameState.money = 999
	GameState.play_seconds = 120.0
	GameState.set_flag("note_paper_1")
	GameState.set_flag("tip_menu3d")
	GameState.set_flag("wave_mark")
	LoopCalendar.reset_loop()
	failures += _check("reset: back to mùng 9, money reset", GameState.day == 1 and GameState.money == GameState.STARTING_MONEY)
	failures += _check("reset keeps notes, tips, play time", GameState.has_flag("note_paper_1")
		and GameState.has_flag("tip_menu3d") and is_equal_approx(GameState.play_seconds, 120.0))
	failures += _check("reset forgets the rest, counts loops", not GameState.has_flag("wave_mark") and LoopCalendar.loops() == 1)
	failures += _check("reset forgets the tea and the recording", not RamNight.tea_answered() and not GameState.has_flag(RamNight.EXPOSED_FLAG))
	LoopCalendar.reset_loop()
	failures += _check("loop count grows", LoopCalendar.loops() == 2)
	GameState.reset()
	print("LOOP CALENDAR TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
