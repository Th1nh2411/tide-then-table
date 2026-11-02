class_name RamNight
extends RefCounted
## Đêm rằm, the loop's last night (pure, PLAN §10 H7). Anh Út's ginger tea
## at the restaurant (TEA_FLAG) + the evening choice (out / home) + whether
## Rin's camera caught him at the raft (EXPOSED_FLAG) pick the ending:
## - drank + out: Rin is drowned at sea, one more trapped soul (DROWNED);
## - refused + out + reached the raft: the truth comes out (TRUE);
## - anything else (stayed home, or came back without the recording): the
##   gate closes for a year, back to mùng 9 (LOOP).

enum Ending { LOOP, DROWNED, TRUE }

## "drank" / "refused"; unset = never talked to anh Út (counts as refused).
const TEA_FLAG := "ram_tea"
const EXPOSED_FLAG := "ram_exposed"
## "drowned" / "true": which epilogue + ending card to play.
const ENDING_FLAG := "ram_ending"
## Notebook clues (NightErrand3D) for ông Tư to speak to Rin at the end.
const CLUES_FOR_GRANDPA := 4

## > 1 plays the rằm sequences faster (bot, tests).
static var speed := 1.0


static func is_ram(day: int = GameState.day) -> bool:
	return day >= LoopCalendar.NIGHTS


static func drank() -> bool:
	return str(GameState.story_flags.get(TEA_FLAG, "")) == "drank"


static func tea_answered() -> bool:
	return GameState.story_flags.has(TEA_FLAG)


static func set_tea(drink: bool) -> void:
	GameState.set_flag(TEA_FLAG, "drank" if drink else "refused")


static func ending(drink: bool, went_out: bool, exposed: bool) -> Ending:
	if not went_out:
		return Ending.LOOP
	if drink:
		return Ending.DROWNED
	return Ending.TRUE if exposed else Ending.LOOP


## Tonight's ending from the story flags and the night's choice.
static func current(went_out: bool) -> Ending:
	return ending(drank(), went_out, GameState.has_flag(EXPOSED_FLAG))


static func grandpa_speaks(clues: int) -> bool:
	return clues >= CLUES_FOR_GRANDPA


## Marks the ending for the epilogue and the ending card.
static func finish(which: Ending) -> void:
	if which == Ending.TRUE:
		GameState.set_flag(EXPOSED_FLAG)
	GameState.set_flag(ENDING_FLAG, "true" if which == Ending.TRUE else "drowned")


static func ending_id() -> String:
	return str(GameState.story_flags.get(ENDING_FLAG, ""))


## Seconds scaled by `speed`.
static func secs(seconds: float) -> float:
	return seconds / maxf(speed, 0.01)
