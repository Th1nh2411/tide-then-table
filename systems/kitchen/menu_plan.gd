class_name MenuPlan
extends RefCounted
## Today's menu, prepared before opening (Dave the Diver style): up to `slots`
## dishes, each with a number of portions. Ingredients for every portion are
## taken out of storage when the portion is added, so customers only order
## what can really be served. Leftover portions go back to storage at closing.
## Always-available dishes (rau muống) are never planned: they're always on
## the menu and cooked from produce bought at the stall (MarketStock).

signal changed

var slots: int = 3
## Kitchen upgrade level: dishes above it can't be planned (DishData.kitchen_level).
var kitchen_level: int = 99
## DishData -> Array of portions; each portion is an Array[InventoryItem].
## Insertion order = order the player added dishes.
var _portions: Dictionary = {}


func _init(p_slots: int = 3) -> void:
	slots = p_slots


## Menu slots taken.
func used_slots() -> int:
	return _portions.size()


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


## Distinct planned dishes (always-available ones never count).
func variety_count() -> int:
	return _portions.size()


## Price multiplier for a menu with `count` distinct dishes. `table[i]` is the
## multiplier for i dishes; counts past the end use the last entry.
static func variety_multiplier(count: int, table: Array[float]) -> float:
	if table.is_empty():
		return 1.0
	return table[clampi(count, 0, table.size() - 1)]


## True if one more portion of `dish` can be added: a free slot + enough
## stock. Always-available dishes are never planned.
func can_add(dish: DishData, storage: Array) -> bool:
	if dish.always_available or dish.ingredients.is_empty() or dish.kitchen_level > kitchen_level:
		return false
	if not _portions.has(dish) and used_slots() >= slots:
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


## Fill free slots with the most expensive seafood dishes storage can make,
## as many portions as possible each.
func auto_fill(menu: Array[DishData], storage: Array) -> void:
	var by_price := menu.filter(func(d: DishData) -> bool: return not d.ingredients.is_empty() and not d.always_available)
	by_price.sort_custom(func(a: DishData, b: DishData) -> bool: return a.base_price > b.base_price)
	for dish: DishData in by_price:
		while add_portion(dish, storage):
			pass


## Return every portion's ingredients to storage.
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
	if not _portions.has(dish):
		_portions[dish] = []
	_portions[dish].append(items.duplicate())
	changed.emit()
