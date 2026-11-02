class_name LoopCalendar
extends RefCounted
## The horror build's day loop (pure): GameState.day 1..NIGHTS is mùng 9 ..
## rằm tháng Bảy. Each night Rin picks a street end; with no omen tonight the
## right pick is the dock (a fisherman goes out), with an omen it is home.
## Right = next day (or the ending after the last night); wrong = back to
## mùng 9 with only Rin's notebook ("note_*"), first-time tips ("tip_*") and
## the loop count kept.

const FIRST_LUNAR := 9
const NIGHTS := 7
## Set by the street end / the dock: "out" or "home". Read once in the bedroom.
const CHOICE_FLAG := "night_choice"
## Set by the omen system (H5) for tonight.
const OMEN_FLAG := "omen_tonight"
const LOOP_FLAG := "loop_count"
const KEPT_PREFIXES: Array[String] = ["note_", "tip_"]

enum Result { NONE, NEXT, RESET, END }

## The last choice take_result() judged ("out" / "home" / ""), so the bedroom
## can tell how the night went wrong.
static var last_choice := ""


static func lunar_day(day: int) -> int:
	return FIRST_LUNAR + clampi(day, 1, NIGHTS) - 1


## "Mùng 9 tháng Bảy", "11 tháng Bảy", "Rằm tháng Bảy".
static func date_text(day: int) -> String:
	var lunar := lunar_day(day)
	if lunar == 15:
		return "Rằm tháng Bảy"
	return ("Mùng %d" if lunar <= 10 else "%d") % lunar + " tháng Bảy"


static func loops() -> int:
	return int(GameState.story_flags.get(LOOP_FLAG, 0))


static func choose(went_out: bool) -> void:
	GameState.set_flag(CHOICE_FLAG, "out" if went_out else "home")


## Judges last night's choice, if one is pending, and clears it.
static func take_result() -> Result:
	var choice: Variant = GameState.story_flags.get(CHOICE_FLAG, "")
	GameState.story_flags.erase(CHOICE_FLAG)
	last_choice = str(choice)
	if choice != "out" and choice != "home":
		return Result.NONE
	var omen := GameState.has_flag(OMEN_FLAG)
	if (choice == "out") == omen:
		return Result.RESET
	return Result.END if GameState.day >= NIGHTS else Result.NEXT


static func next_day() -> void:
	GameState.story_flags.erase(OMEN_FLAG)
	GameState.story_flags.erase(NewsData.MISSING_FLAG)
	GameState.advance_day(0.0)


## Back to mùng 9: everything resets except what Rin remembers.
static func reset_loop() -> void:
	var kept: Dictionary = {}
	for key: String in GameState.story_flags:
		for prefix in KEPT_PREFIXES:
			if key.begins_with(prefix):
				kept[key] = GameState.story_flags[key]
	var count := loops() + 1
	var played := GameState.play_seconds
	GameState.reset()
	GameState.play_seconds = played
	GameState.story_flags.merge(kept, true)
	GameState.set_flag(LOOP_FLAG, count)
