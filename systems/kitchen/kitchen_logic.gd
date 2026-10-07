class_name KitchenLogic
extends RefCounted
## Pure kitchen rules (no nodes): ingredient checks, taking ingredients out of
## storage, freshness multiplier and the selling price formula.

## Freshness above this sells at full price.
const FRESH_THRESHOLD: float = 60.0
## Freshness from this up to FRESH_THRESHOLD sells at STALE_MULTIPLIER.
const STALE_THRESHOLD: float = 30.0
const FRESH_MULTIPLIER: float = 1.0
const STALE_MULTIPLIER: float = 0.7
const OLD_MULTIPLIER: float = 0.4


## fish_id -> number of items in `storage`.
static func count_by_fish(storage: Array) -> Dictionary:
	var counts := {}
	for item: InventoryItem in storage:
		counts[item.fish.id] = counts.get(item.fish.id, 0) + 1
	return counts


static func can_cook(dish: DishData, storage: Array) -> bool:
	var counts := count_by_fish(storage)
	for fish_id in dish.ingredients:
		if counts.get(fish_id, 0) < dish.ingredients[fish_id]:
			return false
	return true


## Removes and returns the ingredients for `dish`, oldest (least fresh) first.
## Returns an empty array and removes nothing if storage doesn't have enough.
static func take_ingredients(dish: DishData, storage: Array) -> Array[InventoryItem]:
	var taken: Array[InventoryItem] = []
	if not can_cook(dish, storage):
		return taken
	for fish_id in dish.ingredients:
		var matching: Array[InventoryItem] = []
		for item: InventoryItem in storage:
			if item.fish.id == fish_id:
				matching.append(item)
		matching.sort_custom(func(a: InventoryItem, b: InventoryItem) -> bool: return a.freshness < b.freshness)
		for i in dish.ingredients[fish_id]:
			taken.append(matching[i])
			storage.erase(matching[i])
	return taken


static func freshness_multiplier(freshness: float) -> float:
	if freshness <= 0.0:
		return 0.0
	if freshness > FRESH_THRESHOLD:
		return FRESH_MULTIPLIER
	if freshness >= STALE_THRESHOLD:
		return STALE_MULTIPLIER
	return OLD_MULTIPLIER


## base_price × cook result × average (quality × size) × average freshness multiplier.
## Market dishes (no items) count as full quality and fresh.
static func calc_price(dish: DishData, cook_multiplier: float, items: Array[InventoryItem]) -> int:
	if items.is_empty():
		return roundi(dish.base_price * cook_multiplier)
	var quality_sum := 0.0
	var fresh_sum := 0.0
	for item in items:
		quality_sum += item.quality * item.size
		fresh_sum += freshness_multiplier(item.freshness)
	var avg_quality := quality_sum / items.size()
	var avg_fresh := fresh_sum / items.size()
	return roundi(dish.base_price * cook_multiplier * avg_quality * avg_fresh)
