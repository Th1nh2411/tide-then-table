class_name PartyOrders3D
extends RefCounted
## A 3D table's party: 1-2 guests, 1-3 order lines, extra rounds, one bill.
## The table's order dict holds the current line; the rest wait in `queue`
## (stock already taken) and eaten lines add to `bill`.

var guests: int = 1
var queue: Array[Dictionary] = []
var more_rounds: int = 0
var bill: int = 0
var lines_total: int = 1
var _rng := RandomNumberGenerator.new()


## Dishes with stock left right now (menu portions + market goods).
static func available(plan: MenuPlan, menu: DishCatalog, market: MarketStock) -> Array[DishData]:
	var out: Array[DishData] = plan.available_dishes()
	for dish in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day and market.portions(dish) > 0:
			out.append(dish)
	return out


## Takes the stock for one more line; {} if nothing is left.
func _take_line(plan: MenuPlan, menu: DishCatalog, market: MarketStock) -> Dictionary:
	var dishes := available(plan, menu, market)
	if dishes.is_empty():
		return {}
	var dish: DishData = dishes[_rng.randi() % dishes.size()]
	var items: Array[InventoryItem] = []
	var fresh := 100.0
	if dish.is_market_dish():
		market.take(dish)
		fresh = market.last_freshness
	else:
		items = plan.take_portion(dish)
	return {"dish": dish, "items": items, "freshness": fresh}


## Builds the party of a new walk-in whose first line is already taken.
static func start(tuning: ServiceTuning, plan: MenuPlan, menu: DishCatalog, market: MarketStock) -> PartyOrders3D:
	var party := PartyOrders3D.new()
	party._rng.randomize()
	if party._rng.randf() < tuning.pair_chance:
		party.guests = 2
	var wanted: int = mini(party.guests + (1 if party._rng.randf() < tuning.extra_dish_chance else 0), tuning.max_lines)
	for i in range(wanted - 1):
		var line := party._take_line(plan, menu, market)
		if line.is_empty():
			break
		party.queue.append(line)
	party.lines_total = 1 + party.queue.size()
	party.more_rounds = tuning.max_more_rounds
	return party


## After a line is eaten: loads the next line (or a new round) into `order`.
## False means the table is done and pays `bill`.
func advance(order: Dictionary, tuning: ServiceTuning, plan: MenuPlan, menu: DishCatalog, market: MarketStock) -> bool:
	var line: Dictionary = {}
	if not queue.is_empty():
		line = queue.pop_front()
	elif more_rounds > 0:
		more_rounds -= 1
		if _rng.randf() < tuning.more_round_chance:
			line = _take_line(plan, menu, market)
			if not line.is_empty():
				lines_total += 1
	if line.is_empty():
		return false
	order["dish"] = line["dish"]
	order["items"] = line["items"]
	order["freshness"] = line["freshness"]
	order["cooked"] = false
	order["staff_claimed"] = false
	order["multiplier"] = 1.0
	order["phase"] = "waiting"
	order["patience"] = order["initial_patience"]
	return true


## The party leaves early: queued stock goes back, eaten lines are paid.
func abandon(plan: MenuPlan, market: MarketStock) -> int:
	for line in queue:
		var dish: DishData = line["dish"]
		if dish.is_market_dish():
			market.add(dish, dish.portion_units, float(line["freshness"]))
		else:
			var items: Array[InventoryItem] = line["items"]
			plan.return_portion(dish, items)
	queue.clear()
	return bill


func label(dish: DishData) -> String:
	var head := "%d khách · " % guests if guests > 1 else ""
	return "%s%s%s" % [head, dish.display_name, " (+%d món)" % (lines_total - 1) if lines_total > 1 else ""]
