extends Node
## Standalone test for LoopCalendar (run with F6): lunar dates, the right
## street end with and without an omen, the 3-fish rule on calm nights (and
## what it leaves for the next day), reset to mùng 9 keeping only Rin's
## notebook / tips / loop count, and rằm judged by RamNight.


func _ready() -> void:
	var failures := 0
	GameState.reset()
	failures += _check("day 1 = mùng 9", LoopCalendar.date_text(1) == "Mùng 9 tháng Bảy")
	failures += _check("day 3 = 11", LoopCalendar.date_text(3) == "11 tháng Bảy")
	failures += _check("day 7 = rằm", LoopCalendar.date_text(7) == "Rằm tháng Bảy")
	failures += _check("no choice -> none", LoopCalendar.take_result() == LoopCalendar.Result.NONE)
	failures += _check("the rule is 3 fish", LoopCalendar.MIN_FISH == 3)
	LoopCalendar.choose(true, 3)
	failures += _check("calm night, out with 3 fish -> next", LoopCalendar.take_result() == LoopCalendar.Result.NEXT
		and not LoopCalendar.last_calm_miss)
	failures += _check("the 3 fish go to the restaurant tomorrow", LoopCalendar.shop_fish() == 3
		and not GameState.has_flag(LoopCalendar.NO_FISH_FLAG))
	failures += _check("choice is read once", LoopCalendar.take_result() == LoopCalendar.Result.NONE)
	LoopCalendar.choose(true, 5)
	failures += _check("calm night, out with 5 fish -> next", LoopCalendar.take_result() == LoopCalendar.Result.NEXT
		and LoopCalendar.shop_fish() == 5)
	LoopCalendar.choose(true, 2)
	failures += _check("calm night, out with 2 fish -> reset (ghosts visit)", LoopCalendar.take_result() == LoopCalendar.Result.RESET
		and LoopCalendar.last_calm_miss)
	LoopCalendar.choose(true)
	failures += _check("calm night, out with nothing -> reset", LoopCalendar.take_result() == LoopCalendar.Result.RESET
		and LoopCalendar.last_calm_miss)
	LoopCalendar.choose(false, 9)
	failures += _check("calm night, home -> reset (ghosts visit)", LoopCalendar.take_result() == LoopCalendar.Result.RESET
		and LoopCalendar.last_calm_miss)
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	LoopCalendar.choose(false)
	failures += _check("omen, home -> next", LoopCalendar.take_result() == LoopCalendar.Result.NEXT
		and not LoopCalendar.last_calm_miss)
	failures += _check("omen, home -> no fish tomorrow, Bảo grumbles", LoopCalendar.shop_fish() == 0
		and GameState.has_flag(LoopCalendar.NO_FISH_FLAG))
	LoopCalendar.choose(true, 4)
	failures += _check("omen, out -> reset even with fish (no ghosts at the door)", LoopCalendar.take_result() == LoopCalendar.Result.RESET
		and not LoopCalendar.last_calm_miss)
	LoopCalendar.next_day()
	failures += _check("next day clears the omen", GameState.day == 2 and not GameState.has_flag(LoopCalendar.OMEN_FLAG))
	LoopCalendar.choose(true, 3)
	LoopCalendar.take_result()
	failures += _check("a right calm night stops the grumble", not GameState.has_flag(LoopCalendar.NO_FISH_FLAG))
	GameState.day = LoopCalendar.NIGHTS
	LoopCalendar.choose(true, 5)
	failures += _check("rằm, out without the recording -> reset (fish don't help)", LoopCalendar.take_result() == LoopCalendar.Result.RESET)
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
	failures += _check("rằm ignores the fish count", LoopCalendar.shop_fish() == 3)
	GameState.boat_hp = 10.0
	GameState.play_seconds = 120.0
	GameState.set_flag("note_paper_1")
	GameState.set_flag("tip_menu3d")
	GameState.set_flag("omen_seen")
	LoopCalendar.reset_loop()
	failures += _check("reset: back to mùng 9, hull reset", GameState.day == 1 and GameState.boat_hp == 100.0)
	failures += _check("reset keeps notes, tips, play time", GameState.has_flag("note_paper_1")
		and GameState.has_flag("tip_menu3d") and is_equal_approx(GameState.play_seconds, 120.0))
	failures += _check("reset forgets the rest, counts loops", not GameState.has_flag("omen_seen") and LoopCalendar.loops() == 1
		and LoopCalendar.shop_fish() == 0)
	failures += _check("reset forgets the tea and the recording", not RamNight.tea_answered() and not GameState.has_flag(RamNight.EXPOSED_FLAG))
	LoopCalendar.reset_loop()
	failures += _check("loop count grows", LoopCalendar.loops() == 2)
	GameState.reset()
	print("LOOP CALENDAR TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
