extends Node
## Global game state: money, current day, storage, upgrades and story flags.
## Autoloaded as `GameState`. Other systems read/write here and listen to signals
## instead of holding their own copies of this data.

signal money_changed(new_amount: int)
signal day_changed(new_day: int)

const STARTING_MONEY: int = 100
const STARTING_DAY: int = 1
## Rating assumed before the first shift (affects day-1 customer frequency).
const STARTING_RATING: int = 3

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

# Result of tonight's sea trip, shown on the rest screen.
## Displayed time (minutes since midnight) the boat got back to the dock.
var return_minutes: float = 0.0
## True if the boat was towed home by a rescue (broken hull / no oil).
var was_towed: bool = false
## Items unloaded from the hold this trip (already added to storage).
var last_catch: Array = []

## Stars (1-5) from the last shift; drives customer frequency the next day.
var last_rating: int = STARTING_RATING
## Storage items that spoiled at the last day change (shown at sea).
var last_spoiled_count: int = 0
## Hull condition 0..100 (see BoatCondition). Carries over between days.
var boat_hp: float = 100.0
## fish_id -> how many caught in total (the phone's Dex).
var caught_species: Dictionary = {}
## One Dictionary per finished shift: day, earned, market, rating, served, left.
var day_history: Array = []
## History entries kept (older ones are dropped).
const MAX_HISTORY: int = 14


## Reset everything to a fresh game. Called by "New Game".
func reset() -> void:
	money = STARTING_MONEY
	day = STARTING_DAY
	storage.clear()
	upgrade_levels.clear()
	story_flags.clear()
	return_minutes = 0.0
	was_towed = false
	last_catch.clear()
	last_rating = STARTING_RATING
	last_spoiled_count = 0
	boat_hp = 100.0
	caught_species.clear()
	day_history.clear()


## Called when the night trip ends: records the return and moves the catch into storage.
func finish_sea_day(returned_at: float, towed: bool, hold_items: Array) -> void:
	return_minutes = returned_at
	was_towed = towed
	last_catch = hold_items.duplicate()
	storage.append_array(hold_items)


## Move to the next day: storage loses `freshness_loss` freshness and
## anything at 0 spoils and is thrown away. Returns how many spoiled.
func advance_day(freshness_loss: float) -> int:
	var kept: Array = []
	for item: InventoryItem in storage:
		item.freshness = maxf(item.freshness - freshness_loss, 0.0)
		if item.freshness > 0.0:
			kept.append(item)
	last_spoiled_count = storage.size() - kept.size()
	storage = kept
	day += 1
	return last_spoiled_count


func record_catch(fish: FishData, count: int) -> void:
	caught_species[fish.id] = int(caught_species.get(fish.id, 0)) + count


func add_day_record(record: Dictionary) -> void:
	day_history.append(record)
	while day_history.size() > MAX_HISTORY:
		day_history.pop_front()


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


## The upgrade's effect at the player's current level.
func get_upgrade_value(upgrade: UpgradeData) -> Variant:
	return upgrade.value_at(get_upgrade_level(upgrade.id))


## Buys the next level if affordable. Takes effect from the next day.
func buy_upgrade(upgrade: UpgradeData) -> bool:
	var level := get_upgrade_level(upgrade.id)
	var cost := upgrade.next_cost(level)
	if cost < 0 or not spend_money(cost):
		return false
	upgrade_levels[upgrade.id] = level + 1
	return true


func set_flag(flag_name: String, value: Variant = true) -> void:
	story_flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return story_flags.get(flag_name, false) == true
