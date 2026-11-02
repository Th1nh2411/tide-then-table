class_name PartyOrders3D
extends RefCounted
## A 3D table's party: 1-2 guests, 1-3 order lines from the fixed menu,
## maybe one more round, one bill. The table's order dict holds the current
## line; the rest wait in `queue`, eaten lines add to `bill`.

var guests: int = 1
var queue: Array[DishData] = []
var more_rounds: int = 0
var bill: int = 0
var lines_total: int = 1
var dishes: Array[DishData] = []
var _rng := RandomNumberGenerator.new()


## Builds the party of a new walk-in (lines picked from `menu`).
static func start(tuning: ServiceTuning, menu: Array[DishData]) -> PartyOrders3D:
	var party := PartyOrders3D.new()
	party.dishes = menu
	party._rng.randomize()
	if party._rng.randf() < tuning.pair_chance:
		party.guests = 2
	var wanted: int = mini(party.guests + (1 if party._rng.randf() < tuning.extra_dish_chance else 0), tuning.max_lines)
	for i in range(maxi(wanted, 1)):
		party.queue.append(party._pick())
	party.lines_total = party.queue.size()
	party.more_rounds = tuning.max_more_rounds
	return party


func _pick() -> DishData:
	return dishes[_rng.randi() % dishes.size()]


## The first line (call once, right after start).
func next_dish() -> DishData:
	return queue.pop_front()


## After a line is eaten: loads the next line (or a new round) into `order`.
## False means the table is done and pays `bill`.
func advance(order: Dictionary, tuning: ServiceTuning) -> bool:
	var dish: DishData = null
	if not queue.is_empty():
		dish = queue.pop_front()
	elif more_rounds > 0:
		more_rounds -= 1
		if _rng.randf() < tuning.more_round_chance:
			dish = _pick()
			lines_total += 1
	if dish == null:
		return false
	order["dish"] = dish
	order["cooked"] = false
	order["phase"] = "waiting"
	order["patience"] = order["initial_patience"]
	return true


func label(dish: DishData) -> String:
	var head := "%d khách · " % guests if guests > 1 else ""
	return "%s%s%s" % [head, dish.display_name, " (+%d món)" % (lines_total - 1) if lines_total > 1 else ""]
