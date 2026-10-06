class_name UpgradeData
extends Resource
## One upgrade track. Level 0 is the starting state.
## `levels[i]` = price to go from level i to level i+1.
## `values[i]` = the effect at level i (so values has one more entry than levels).
## Systems read the current value with GameState.get_upgrade_value(upgrade).

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var levels: Array[int] = []
## Effect per level: a number, a Resource (e.g. BoatData), etc.
@export var values: Array = []
## Player-facing text for each value, same length as `values`.
@export var value_labels: Array[String] = []


func max_level() -> int:
	return levels.size()


## Price of the next level, or -1 if already maxed.
func next_cost(current_level: int) -> int:
	return levels[current_level] if current_level < levels.size() else -1


func value_at(level: int) -> Variant:
	return values[clampi(level, 0, values.size() - 1)]


func label_at(level: int) -> String:
	if value_labels.is_empty():
		return str(value_at(level))
	return value_labels[clampi(level, 0, value_labels.size() - 1)]
