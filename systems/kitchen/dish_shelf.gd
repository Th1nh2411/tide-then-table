class_name DishShelf
extends RefCounted
## The pass (plate table): cooked dishes (Plates) waiting to be carried
## out, one per fixed slot, up to `capacity`. Also the matching rule for service: go through the waiting
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
## Plates in the order they were put down (oldest first).
var plates: Array[Plate] = []
## Fixed spots on the table: slot index -> Plate (null = empty).
var slots: Array[Plate] = []


func _init(p_capacity: int = 4) -> void:
	capacity = p_capacity
	slots.resize(capacity)


func is_full() -> bool:
	return plates.size() >= capacity


## Puts the plate on `slot` (or the first empty one when -1).
func add(plate: Plate, slot: int = -1) -> bool:
	if is_full():
		return false
	if slot < 0:
		slot = slots.find(null)
	if slot < 0 or slot >= capacity or slots[slot] != null:
		return false
	slots[slot] = plate
	plates.append(plate)
	return true


func remove(plate: Plate) -> void:
	plates.erase(plate)
	var slot := slots.find(plate)
	if slot >= 0:
		slots[slot] = null


func plate_at(slot: int) -> Plate:
	return slots[slot] if slot >= 0 and slot < capacity else null


func clear() -> void:
	plates.clear()
	slots.fill(null)


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
## any objects with `dish` and `visit` properties (TableOrder lines). Returns
## {"order": <order>, "plate": Plate} or {}.
func next_delivery(orders: Array) -> Dictionary:
	for order: Object in orders:
		var plate := find_for(order.get("dish"), order.get("visit"))
		if plate:
			return {"order": order, "plate": plate}
	return {}
