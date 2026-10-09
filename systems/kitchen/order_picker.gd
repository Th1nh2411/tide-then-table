class_name OrderPicker
extends RefCounted
## What a table orders: seafood still servable (menu portions + plates on the
## plate table, minus lines already waiting), or a side dish (rau muống,
## beer: sometimes by choice, always once the seafood is gone; always
## orderable since Rin buys its goods at the grocery). Pure logic, no nodes.

var plan: MenuPlan
var shelf: DishShelf
var sides: Array[DishData] = []
var rng := RandomNumberGenerator.new()


func _init(p_shelf: DishShelf = null, p_sides: Array[DishData] = []) -> void:
	shelf = p_shelf
	sides = p_sides
	rng.randomize()


## One dish, or null if there is nothing at all. `waiting` items are any
## objects with `dish` and `visit` (TableOrder lines).
func pick(side_chance: float, waiting: Array) -> DishData:
	var dishes: Array[DishData] = []
	for dish in plan.get_dishes():
		if servable(dish, waiting) > 0:
			dishes.append(dish)
	var wants_side := dishes.is_empty() or rng.randf() < side_chance
	if wants_side and not sides.is_empty():
		return sides[rng.randi() % sides.size()]
	if dishes.is_empty():
		return null
	return dishes[rng.randi() % dishes.size()]


## Portions of `dish` not yet promised to a waiting line.
func servable(dish: DishData, waiting: Array) -> int:
	var promised := 0
	for order: Object in waiting:
		var visit: Dictionary = order.get("visit")
		if order.get("dish") == dish and visit.is_empty():
			promised += 1
	return plan.get_portion_count(dish) + shelf.count(dish) - promised


func anything_to_order(waiting: Array) -> bool:
	return not sides.is_empty() or plan.get_dishes().any(func(d: DishData) -> bool: return servable(d, waiting) > 0)


## Lines in a party's first order: one per guest, sometimes one more.
func first_order_size(guests: int, extra_chance: float, max_lines: int) -> int:
	return mini(guests + (1 if rng.randf() < extra_chance else 0), max_lines)
