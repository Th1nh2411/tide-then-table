class_name MarketStock
extends RefCounted
## Grocery goods Rin has on hand, in units (a portion of water spinach, a
## litre of draft beer); one serving uses `DishData.portion_units`. Works on
## a shared dictionary (dish id -> units): the fridge works on
## GameState.pantry so goods that keep (beer) are saved, perishable ones (rau)
## are thrown away at closing; Rin's shopping bag is a separate stock.
## Pure logic, no nodes.

signal changed

var _counts: Dictionary  # dish id -> units on hand (shared, not copied)


func _init(counts: Dictionary = {}) -> void:
	_counts = counts


## Units on hand (litres of beer, portions of rau).
func count(dish: DishData) -> int:
	var n: int = _counts.get(dish.id, 0)
	return n


## Servings the units on hand still make (beer: 3 litres a tower).
func portions(dish: DishData) -> int:
	return count(dish) / maxi(dish.portion_units, 1)


func total() -> int:
	var sum := 0
	for id: Variant in _counts:
		var n: int = _counts[id]
		sum += n
	return sum


func add(dish: DishData, amount: int = 1) -> void:
	_counts[dish.id] = count(dish) + amount
	changed.emit()


## Uses one serving; false if there isn't enough for it.
func take(dish: DishData) -> bool:
	if portions(dish) <= 0:
		return false
	_counts[dish.id] = count(dish) - maxi(dish.portion_units, 1)
	changed.emit()
	return true


## Moves everything of `dishes` into `target` (bag -> fridge). Returns how
## many units moved.
func move_into(target: MarketStock, dishes: Array[DishData]) -> int:
	var moved := 0
	for dish in dishes:
		var n := count(dish)
		if n > 0:
			target.add(dish, n)
			_counts.erase(dish.id)
			moved += n
	if moved > 0:
		changed.emit()
	return moved


## End of the day: goods that don't keep overnight are wasted. Returns how
## many units were thrown away.
func discard_perishable(dishes: Array[DishData]) -> int:
	var wasted := 0
	for dish in dishes:
		if not dish.keeps_overnight and _counts.has(dish.id):
			wasted += count(dish)
			_counts.erase(dish.id)
	changed.emit()
	return wasted
