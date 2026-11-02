class_name LoopCalendar
extends RefCounted
## The horror build's day loop (pure): GameState.day 1..NIGHTS is mùng 9 ..
## rằm tháng Bảy. Each night Rin picks a street end; with no omen tonight the
## right pick is the dock (a fisherman goes out), with an omen it is home.
## Right = next day; wrong = back to mùng 9 with only Rin's notebook
## ("note_*"), first-time tips ("tip_*") and the loop count kept. The last
## night (rằm) has no omen: RamNight judges it (anh Út's tea, the raft).

const FIRST_LUNAR := 9
const NIGHTS := 7
## Set by the street end / the dock: "out" or "home". Read once in the bedroom.
const CHOICE_FLAG := "night_choice"
## Set by the omen system (H5) for tonight.
const OMEN_FLAG := "omen_tonight"
const LOOP_FLAG := "loop_count"
## Fish in the basket when Rin docked (set with the "out" choice).
const CATCH_FLAG := "night_catch"
## A calm night is only right with this many fish brought home.
const MIN_FISH := 3
## For the day after a right night: the fish Bảo has (restaurant tray), and
## "stayed home on an omen night" (Bảo grumbles, no penalty).
const SHOP_FISH_FLAG := "shop_fish"
const NO_FISH_FLAG := "bao_no_fish"
const KEPT_PREFIXES: Array[String] = ["note_", "tip_"]
## What the last wrong night missed (kept through resets, "note_"): the omen
## id, or MISSED_CALM for a calm night at home / short of fish. The mùng 9
## paper prints a vague hint about it (NewsData.hint_for).
const MISSED_FLAG := "note_missed"
const MISSED_CALM := "calm"

enum Result { NONE, NEXT, RESET, END }

## The last choice take_result() judged ("out" / "home" / ""), so the bedroom
## can tell how the night went wrong.
static var last_choice := ""
## True when the last judged night was calm and went wrong (stayed home or
## came back short): the bedroom shows the ghosts' visit.
static var last_calm_miss := false


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


## `fish`: what the basket holds on docking (only counts when going out).
static func choose(went_out: bool, fish: int = 0) -> void:
	GameState.set_flag(CHOICE_FLAG, "out" if went_out else "home")
	GameState.set_flag(CATCH_FLAG, fish if went_out else 0)


static func shop_fish() -> int:
	return int(GameState.story_flags.get(SHOP_FISH_FLAG, 0))


## Judges last night's choice, if one is pending, and clears it. A right
## night also leaves SHOP_FISH_FLAG / NO_FISH_FLAG for the next day.
static func take_result() -> Result:
	var choice: Variant = GameState.story_flags.get(CHOICE_FLAG, "")
	var fish := int(GameState.story_flags.get(CATCH_FLAG, 0))
	GameState.story_flags.erase(CHOICE_FLAG)
	GameState.story_flags.erase(CATCH_FLAG)
	last_choice = str(choice)
	last_calm_miss = false
	if choice != "out" and choice != "home":
		return Result.NONE
	var went_out: bool = choice == "out"
	if RamNight.is_ram(GameState.day):
		return Result.RESET if RamNight.current(went_out) == RamNight.Ending.LOOP else Result.END
	var omen := GameState.has_flag(OMEN_FLAG)
	if omen and went_out:
		GameState.set_flag(MISSED_FLAG, str(GameState.story_flags.get(OmenPicker.ID_FLAG, "")))
		return Result.RESET
	if not omen and (not went_out or fish < MIN_FISH):
		last_calm_miss = true
		GameState.set_flag(MISSED_FLAG, MISSED_CALM)
		return Result.RESET
	GameState.set_flag(SHOP_FISH_FLAG, fish if went_out else 0)
	if omen:
		GameState.set_flag(NO_FISH_FLAG)
	else:
		GameState.story_flags.erase(NO_FISH_FLAG)
	return Result.NEXT


## 0..1 from the day (mùng 9 = 0, rằm = 1): how close the haunting may come
## (DarkNight3D, CalmNightSounds3D).
static func dread_level(day: int = -1) -> float:
	var d := GameState.day if day < 0 else day
	return clampf(float(d - 1) / float(NIGHTS - 1), 0.0, 1.0)


static func missed() -> String:
	return str(GameState.story_flags.get(MISSED_FLAG, ""))


static func next_day() -> void:
	GameState.story_flags.erase(OMEN_FLAG)
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
