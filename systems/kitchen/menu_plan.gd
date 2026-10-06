class_name MenuPlan
extends RefCounted
## Today's menu, prepared before opening (Dave the Diver style): up to `slots`
## dishes, each with a number of portions. Ingredients for every portion are
## taken out of storage when the portion is added, so customers only order
## what can really be served. Leftover portions go back to storage at closing.

signal changed

var slots: int = 3
## DishData -> Array of portions; each portion is an Array[InventoryItem].
## Insertion order = order the player added dishes.
var _portions: Dictionary = {}


func _init(p_slots: int = 3) -> void:
	slots = p_slots


func get_dishes() -> Array[DishData]:
	var result: Array[DishData] = []
	for dish: DishData in _portions:
		result.append(dish)
	return result


func get_portion_count(dish: DishData) -> int:
	return _portions[dish].size() if _portions.has(dish) else 0


func total_portions() -> int:
	var total := 0
	for dish: DishData in _portions:
		total += _portions[dish].size()
	return total


func is_sold_out() -> bool:
	return total_portions() == 0


## True if one more portion of `dish` can be added (free slot + enough stock).
func can_add(dish: DishData, storage: Array) -> bool:
	if not _portions.has(dish) and _portions.size() >= slots:
		return false
	return KitchenLogic.can_cook(dish, storage)


## How many more portions storage can still make (ignores slots).
static func max_portions(dish: DishData, storage: Array) -> int:
	var counts := KitchenLogic.count_by_fish(storage)
	var result := 999
	for fish_id in dish.ingredients:
		result = mini(result, counts.get(fish_id, 0) / dish.ingredients[fish_id])
	return result


func add_portion(dish: DishData, storage: Array) -> bool:
	if not can_add(dish, storage):
		return false
	var items := KitchenLogic.take_ingredients(dish, storage)
	if not _portions.has(dish):
		_portions[dish] = []
	_portions[dish].append(items)
	changed.emit()
	return true


## Undo one portion during planning: its ingredients go back to storage.
func remove_portion(dish: DishData, storage: Array) -> void:
	if get_portion_count(dish) == 0:
		return
	storage.append_array(_portions[dish].pop_back())
	if _portions[dish].is_empty():
		_portions.erase(dish)
	changed.emit()


## Fill free slots with the most expensive dishes storage can make, as many
## portions as possible each.
func auto_fill(menu: Array[DishData], storage: Array) -> void:
	var by_price := menu.duplicate()
	by_price.sort_custom(func(a: DishData, b: DishData) -> bool: return a.base_price > b.base_price)
	for dish: DishData in by_price:
		while add_portion(dish, storage):
			pass


## Return every portion to storage.
func clear(storage: Array) -> void:
	for dish: DishData in _portions:
		for portion: Array in _portions[dish]:
			storage.append_array(portion)
	_portions.clear()
	changed.emit()


# --- During service -------------------------------------------------------

## Dishes that still have at least one portion.
func available_dishes() -> Array[DishData]:
	var result: Array[DishData] = []
	for dish: DishData in _portions:
		if not _portions[dish].is_empty():
			result.append(dish)
	return result


## A customer ordered: hand over one portion's ingredients.
## The dish stays on the menu (with 0 left) so the HUD can show "hết".
func take_portion(dish: DishData) -> Array[InventoryItem]:
	var items: Array[InventoryItem] = []
	if get_portion_count(dish) > 0:
		items.assign(_portions[dish].pop_back())
		changed.emit()
	return items


## A customer left without eating: the portion goes back on the menu.
func return_portion(dish: DishData, items: Array[InventoryItem]) -> void:
	if items.is_empty():
		return
	if not _portions.has(dish):
		_portions[dish] = []
	_portions[dish].append(items.duplicate())
	changed.emit()
