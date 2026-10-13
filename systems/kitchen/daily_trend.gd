class_name DailyTrend
extends RefCounted
## "Món nổi trong ngày" (like Dave the Diver's trending dish): each day one
## seafood dish Rin can really serve (seafood caught before, kitchen can
## cook it; the first night: near-shore seafood) is what everyone craves — it sells for
## PRICE_SCALE and guests pick it PICK_WEIGHT times as often. Rolled when the
## night starts (so the trip has a goal), announced by NEO at sea and in the
## restaurant. Kept in story flags (saved): "trend_dish", "trend_day".
## Pure logic, no nodes.

const MENU_PATH := "res://data/dishes/menu.tres"
const PRICE_SCALE := 1.5
const PICK_WEIGHT := 3.0
## Before anything is caught (the first night), only dishes from seafood
## living here, which the first boat reaches.
const STARTER_ZONE := FishData.Zone.NEARSHORE
const FISH_CATALOG_PATH := "res://data/fish/fish_catalog.tres"


## Rolls today's dish once per day. True if it was rolled now.
static func ensure(rng: RandomNumberGenerator = null, menu: DishCatalog = null) -> bool:
	if int(GameState.story_flags.get("trend_day", 0)) == GameState.day:
		return false
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if menu == null:
		menu = load(MENU_PATH)
	# Only what Rin can really serve: seafood he has caught, a kitchen that
	# cooks it (DishBook.is_cookable).
	var pool: Array[DishData] = []
	for dish in menu.dishes:
		if not dish.ingredients.is_empty() and DishBook.is_cookable(dish):
			pool.append(dish)
	if pool.is_empty():
		pool = _starter_dishes(menu)
	if pool.is_empty():
		return false
	GameState.set_flag("trend_dish", pool[rng.randi() % pool.size()].id)
	GameState.set_flag("trend_day", GameState.day)
	return true


## Nothing caught yet: dishes the kitchen can cook from seafood that lives
## near the shore (non-aberrant).
static func _starter_dishes(menu: DishCatalog) -> Array[DishData]:
	var catalog: FishCatalog = load(FISH_CATALOG_PATH)
	var nearby: Array[String] = []
	for fish in catalog.fish:
		if not fish.is_aberrant and fish.zones.has(STARTER_ZONE):
			nearby.append(fish.id)
	var result: Array[DishData] = []
	for dish in menu.dishes:
		if dish.ingredients.is_empty() or dish.kitchen_level > DishBook.kitchen_level():
			continue
		if dish.ingredients.keys().all(func(id: Variant) -> bool: return nearby.has(str(id))):
			result.append(dish)
	return result


## Today's dish id ("" if none).
static func dish_id() -> String:
	if int(GameState.story_flags.get("trend_day", 0)) != GameState.day:
		return ""
	return str(GameState.story_flags.get("trend_dish", ""))


static func is_hot(dish: DishData) -> bool:
	return dish != null and dish.id == dish_id()


static func price_scale(dish: DishData) -> float:
	return PRICE_SCALE if is_hot(dish) else 1.0


static func pick_weight(dish: DishData) -> float:
	return PICK_WEIGHT if is_hot(dish) else 1.0


## NEO's line about it, e.g. "NEO: Hôm nay khách đang thèm Mực nướng..."
static func announcement(menu: DishCatalog = null) -> String:
	var id := dish_id()
	if id == "":
		return ""
	if menu == null:
		menu = load(MENU_PATH)
	for dish in menu.dishes:
		if dish.id == id:
			return "NEO: Hôm nay khách đang thèm %s, bán được giá x%s." % [dish.display_name, str(PRICE_SCALE)]
	return ""
