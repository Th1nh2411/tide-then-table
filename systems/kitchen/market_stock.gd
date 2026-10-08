class_name MarketStock
extends RefCounted
## Produce Rin bought at the stall today (one unit = one portion of a market
## dish, e.g. a bunch of water spinach). Lives for the restaurant day only:
## whatever is left at closing is thrown away. Pure logic, no nodes.

signal changed

var _counts: Dictionary[String, int] = {}  # dish id -> portions on hand


func count(dish: DishData) -> int:
	return _counts.get(dish.id, 0)


func total() -> int:
	var sum := 0
	for id in _counts:
		sum += _counts[id]
	return sum


func add(dish: DishData, amount: int = 1) -> void:
	_counts[dish.id] = count(dish) + amount
	changed.emit()


## Uses one portion; false if there is none.
func take(dish: DishData) -> bool:
	if count(dish) <= 0:
		return false
	_counts[dish.id] = count(dish) - 1
	changed.emit()
	return true


## End of the day: everything left is wasted. Returns how many portions.
func clear() -> int:
	var wasted := total()
	_counts.clear()
	changed.emit()
	return wasted
