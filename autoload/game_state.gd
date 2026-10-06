extends Node
## Global game state: money, current day, storage, upgrades and story flags.
## Autoloaded as `GameState`. Other systems read/write here and listen to signals
## instead of holding their own copies of this data.

signal money_changed(new_amount: int)
signal day_changed(new_day: int)

const STARTING_MONEY: int = 100
const STARTING_DAY: int = 1

var money: int = STARTING_MONEY:
	set(value):
		money = value
		money_changed.emit(money)

var day: int = STARTING_DAY:
	set(value):
		day = value
		day_changed.emit(day)

## Items moved from the boat hold after docking. Holds InventoryItem objects (Phase 5+).
var storage: Array = []

## upgrade_id -> current level (0 = not upgraded).
var upgrade_levels: Dictionary = {}

## flag_name -> value. Used by the ending trigger in Phase 9.
var story_flags: Dictionary = {}

# Result of today's sea trip, read by the restaurant scene.
## In-game time (minutes since midnight) the boat got back to the dock.
var return_minutes: float = 0.0
## 0..1 multiplier for the selling shift length (1.0 = on time).
var shift_ratio: float = 1.0
## True if the boat was towed home at the deadline.
var was_towed: bool = false


## Reset everything to a fresh game. Called by "New Game".
func reset() -> void:
	money = STARTING_MONEY
	day = STARTING_DAY
	storage.clear()
	upgrade_levels.clear()
	story_flags.clear()
	return_minutes = 0.0
	shift_ratio = 1.0
	was_towed = false


## Called when the sea day ends: records the return and moves the catch into storage.
func finish_sea_day(returned_at: float, ratio: float, towed: bool, hold_items: Array) -> void:
	return_minutes = returned_at
	shift_ratio = ratio
	was_towed = towed
	storage.append_array(hold_items)


func add_money(amount: int) -> void:
	money += amount


## Returns false (and changes nothing) if the player can't afford it.
func spend_money(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	return true


func get_upgrade_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)


func set_flag(flag_name: String, value: Variant = true) -> void:
	story_flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return story_flags.get(flag_name, false) == true
