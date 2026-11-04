extends Node
## Global game state: current day, story flags, hull, catch records.
## Autoloaded as `GameState`. Other systems read/write here and listen to signals
## instead of holding their own copies of this data.

signal day_changed(new_day: int)

const STARTING_DAY: int = 1
## Rating assumed before the first shift (affects day-1 customer frequency).
const STARTING_RATING: int = 3

var day: int = STARTING_DAY:
	set(value):
		day = value
		day_changed.emit(day)

## flag_name -> value: story, loop count, notebook ("note_*").
var story_flags: Dictionary = {}

## Stars (1-5) from the last shift; drives customer frequency the next day.
var last_rating: int = STARTING_RATING
## Hull condition 0..100 (see BoatCondition). Carries over between days.
var boat_hp: float = 100.0
## fish_id -> how many caught in total (fish names, NEW card, ending card).
var caught_species: Dictionary = {}
## Species id -> biggest size caught (CatchRoll size, 1.0 = average).
var best_sizes: Dictionary = {}
## One Dictionary per finished shift: day, earned, rating, served, left.
## Money is no longer a currency; `earned` is only counted for the ending card.
var day_history: Array = []
## Where "Continue" resumes ("home" in the horror build).
var resume_at: String = "home"
## Extra lines about this trip (night events).
var trip_notes: Array[String] = []
## Seconds spent in the game itself (not the main menu / ending), saved.
## Shown on the ending's thank-you card.
var play_seconds: float = 0.0
## History entries kept (older ones are dropped).
const MAX_HISTORY: int = 14


## Reset everything to a fresh game. Called by "New Game".
func reset() -> void:
	day = STARTING_DAY
	story_flags.clear()
	last_rating = STARTING_RATING
	boat_hp = 100.0
	caught_species.clear()
	best_sizes.clear()
	day_history.clear()
	resume_at = "home"
	trip_notes.clear()
	play_seconds = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # cutscenes / phone count as play


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene and not scene.scene_file_path.contains("main_menu") and not scene.scene_file_path.contains("ending"):
		play_seconds += delta / maxf(Engine.time_scale, 0.001)


## Next day of the loop (LoopCalendar). Nothing spoils any more.
func advance_day(_freshness_loss: float = 0.0) -> void:
	day += 1


func record_catch(fish: FishData, count: int, size: float = 1.0) -> void:
	caught_species[fish.id] = int(caught_species.get(fish.id, 0)) + count
	if count > 0 and size > best_size(fish):
		best_sizes[fish.id] = size


## Biggest size caught for this species (0 if never caught).
func best_size(fish: FishData) -> float:
	return float(best_sizes.get(fish.id, 0.0))


func add_day_record(record: Dictionary) -> void:
	day_history.append(record)
	while day_history.size() > MAX_HISTORY:
		day_history.pop_front()


## Day 1 = tutorial day: in-game hint texts only show then (the rest is in
## the Hướng dẫn screen).
func is_first_day() -> bool:
	return day == STARTING_DAY


func set_flag(flag_name: String, value: Variant = true) -> void:
	story_flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return story_flags.get(flag_name, false) == true
