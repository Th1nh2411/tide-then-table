class_name Story
extends RefCounted
## Story rules for the MVP ending. The "omen" triggers on the first glowing
## mackerel catch OR when day OMEN_DAY starts; the fog zone (with the glowing
## whirlpool) opens from the day after the omen. State lives in
## GameState.story_flags so it is saved with the game.

## Flag holding the day number the omen happened on.
const OMEN_DAY_FLAG: String = "fog_omen_day"
const ENDING_SEEN_FLAG: String = "ending_seen"
const OMEN_DAY: int = 7
const OMEN_FISH_ID: String = "ca_thu_phat_sang"


## Records the omen once. Returns true only on the call that triggered it.
static func trigger_omen() -> bool:
	if GameState.story_flags.has(OMEN_DAY_FLAG):
		return false
	GameState.set_flag(OMEN_DAY_FLAG, GameState.day)
	return true


static func on_fish_caught(fish: FishData) -> bool:
	return fish.id == OMEN_FISH_ID and trigger_omen()


## Call at the start of each day.
static func check_day() -> bool:
	return GameState.day >= OMEN_DAY and trigger_omen()


static func is_fog_open() -> bool:
	var omen_day: Variant = GameState.story_flags.get(OMEN_DAY_FLAG)
	# JSON saves turn ints into floats, so accept both.
	return (omen_day is int or omen_day is float) and GameState.day > int(omen_day)
