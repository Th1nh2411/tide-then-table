class_name DishBook
extends RefCounted
## Which seafood dishes Rin's restaurant can make: a dish is *known* once
## every seafood it needs has been caught at least once (GameState
## caught_species, the Dex), and *cookable* when the kitchen upgrade reaches
## its `kitchen_level` (boiled / grilled from the start, steamed at 1,
## stir-fried at 2). Newly cookable dishes are announced once on the rest card
## (story flag "dish_<id>"). Pure logic, no nodes.

const KITCHEN_ID := "kitchen"
const SEEN_PREFIX := "dish_"


static func kitchen_level() -> int:
	return GameState.get_upgrade_level(KITCHEN_ID)


## Every seafood it needs has been caught at least once.
static func is_known(dish: DishData) -> bool:
	for fish_id in dish.ingredients:
		if int(GameState.caught_species.get(fish_id, 0)) <= 0:
			return false
	return true


static func is_cookable(dish: DishData, level: int = kitchen_level()) -> bool:
	return dish.kitchen_level <= level and is_known(dish)


## Seafood dishes now cookable that the player hasn't been told about yet.
static func new_dishes(menu: Array[DishData], level: int = kitchen_level()) -> Array[DishData]:
	var result: Array[DishData] = []
	for dish in menu:
		if not dish.ingredients.is_empty() and is_cookable(dish, level) \
				and not GameState.has_flag(SEEN_PREFIX + dish.id):
			result.append(dish)
	return result


static func mark_seen(dishes: Array[DishData]) -> void:
	for dish in dishes:
		GameState.set_flag(SEEN_PREFIX + dish.id)


## The dish a regular eats for `fish_id`: the priciest one the kitchen can make.
static func best_for(fish_id: String, menu: Array[DishData], level: int = kitchen_level()) -> DishData:
	var best: DishData = null
	for dish in menu:
		if dish.ingredients.has(fish_id) and dish.kitchen_level <= level \
				and (best == null or dish.base_price > best.base_price):
			best = dish
	return best
