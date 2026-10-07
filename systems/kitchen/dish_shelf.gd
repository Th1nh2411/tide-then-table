class_name DishShelf
extends RefCounted
## The kitchen shelf: cooked dishes (Plates) waiting to be carried out, up to
## `capacity`. Also the matching rule for service: go through the waiting
## customers in arrival order and take the oldest plate of the dish the first
## one ordered. A regular's plate (cooked from their reserved fish) only goes
## to that regular. Pure logic, no nodes.


## One cooked dish.
class Plate:
	extends RefCounted
	var dish: DishData
	## The menu portion's ingredients (price uses their quality/size/freshness).
	var ingredients: Array[InventoryItem] = []
	## Cooking result multiplier (perfect 1.3, ok 1.0, burnt 0.5).
	var cook_multiplier: float = 1.0
	## The regular visit this was cooked for ({} for a normal dish).
	var visit: Dictionary = {}

	func _init(p_dish: DishData = null, p_ingredients: Array[InventoryItem] = [], p_multiplier: float = 1.0,
			p_visit: Dictionary = {}) -> void:
		dish = p_dish
		ingredients = p_ingredients
		cook_multiplier = p_multiplier
		visit = p_visit


var capacity: int = 4
var plates: Array[Plate] = []


func _init(p_capacity: int = 4) -> void:
	capacity = p_capacity


func is_full() -> bool:
	return plates.size() >= capacity


func add(plate: Plate) -> bool:
	if is_full():
		return false
	plates.append(plate)
	return true


func remove(plate: Plate) -> void:
	plates.erase(plate)


## Plates of `dish` free for anyone (not a regular's).
func count(dish: DishData) -> int:
	return plates.filter(func(p: Plate) -> bool: return p.dish == dish and p.visit.is_empty()).size()


## Oldest plate this order can take: same dish, and the same regular visit
## (or none on both sides). Null if there is none.
func find_for(dish: DishData, visit: Dictionary) -> Plate:
	for plate in plates:
		if plate.dish == dish and plate.visit == visit:
			return plate
	return null


## First waiting order (arrival order) that has a plate. `orders` items are
## any objects with `dish` and `visit` properties (Customers). Returns
## {"order": <order>, "plate": Plate} or {}.
func next_delivery(orders: Array) -> Dictionary:
	for order: Object in orders:
		var plate := find_for(order.get("dish"), order.get("visit"))
		if plate:
			return {"order": order, "plate": plate}
	return {}
