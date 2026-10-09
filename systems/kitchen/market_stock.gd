class_name MarketStock
extends RefCounted
## Grocery goods Rin has on hand, in units (a portion of water spinach, a
## litre of draft beer); one serving uses `DishData.portion_units`. Works on
## a shared dictionary: the fridge works on GameState.pantry (saved), Rin's
## shopping bag is a separate stock.
## Goods that keep (`keeps_overnight`, beer) are a plain unit count. Fresh
## goods (rau) are batches [{"units", "fresh"}] like the fish in storage:
## bought at 100, losing freshness every night (`age`, same loss as the
## fish), thrown away at 0; cooking takes the oldest batch first and its
## freshness sets the price (`last_freshness`, KitchenLogic).
## Pure logic, no nodes.

signal changed

const FULL_FRESHNESS := 100.0

## Freshness of the units the last take() used (100 for goods that keep).
var last_freshness: float = FULL_FRESHNESS

var _counts: Dictionary  # dish id -> units (int) or batches (Array), shared


func _init(counts: Dictionary = {}) -> void:
	_counts = counts


## Units on hand (litres of beer, portions of rau).
func count(dish: DishData) -> int:
	return _units(_counts.get(dish.id, 0))


## Servings the units on hand still make (beer: 3 litres a tower).
func portions(dish: DishData) -> int:
	return count(dish) / maxi(dish.portion_units, 1)


func total() -> int:
	var sum := 0
	for id: Variant in _counts:
		sum += _units(_counts[id])
	return sum


## Lowest freshness on hand (100 for goods that keep, or nothing on hand).
func freshness(dish: DishData) -> float:
	var entry: Variant = _counts.get(dish.id, 0)
	if not entry is Array or (entry as Array).is_empty():
		return FULL_FRESHNESS
	return float((entry as Array)[0]["fresh"])


func add(dish: DishData, amount: int = 1, fresh: float = FULL_FRESHNESS) -> void:
	if dish.keeps_overnight:
		_counts[dish.id] = count(dish) + amount
	else:
		_add_batch(_batches(dish), amount, fresh)
	changed.emit()


## Uses one serving (oldest goods first); false if there isn't enough.
func take(dish: DishData) -> bool:
	if portions(dish) <= 0:
		return false
	last_freshness = _remove(dish, maxi(dish.portion_units, 1))
	changed.emit()
	return true


## Wastes up to `amount` units (spilled beer). Returns how many were lost.
func spill(dish: DishData, amount: int) -> int:
	var lost := mini(amount, count(dish))
	if lost > 0:
		_remove(dish, lost)
		changed.emit()
	return lost


## Moves everything of `dishes` into `target` (bag -> fridge), keeping
## each batch's freshness. Returns how many units moved.
func move_into(target: MarketStock, dishes: Array[DishData]) -> int:
	var moved := 0
	for dish in dishes:
		var n := count(dish)
		if n <= 0:
			continue
		if dish.keeps_overnight:
			target.add(dish, n)
		else:
			for batch: Dictionary in _batches(dish):
				target.add(dish, int(batch["units"]), float(batch["fresh"]))
		_counts.erase(dish.id)
		moved += n
	if moved > 0:
		changed.emit()
	return moved


## A night passes: fresh goods lose `loss` freshness, spoiled batches are
## thrown away. Works on the raw dictionary (GameState.pantry). Returns the
## units thrown away.
static func age(counts: Dictionary, loss: float) -> int:
	var spoiled := 0
	for id: Variant in counts:
		var entry: Variant = counts[id]
		if not entry is Array:
			continue
		var kept: Array = []
		for batch: Dictionary in entry:
			batch["fresh"] = float(batch["fresh"]) - loss
			if float(batch["fresh"]) > 0.0:
				kept.append(batch)
			else:
				spoiled += int(batch["units"])
		counts[id] = kept
	return spoiled


func _batches(dish: DishData) -> Array:
	var entry: Variant = _counts.get(dish.id)
	if not entry is Array:  # old saves kept rau as a plain count
		var batches: Array = []
		if (entry is int or entry is float) and int(entry) > 0:
			batches.append({"units": int(entry), "fresh": FULL_FRESHNESS})
		_counts[dish.id] = batches
		return batches
	return entry


## Batches stay sorted oldest (least fresh) first; same freshness merges.
static func _add_batch(batches: Array, units: int, fresh: float) -> void:
	for batch: Dictionary in batches:
		if is_equal_approx(float(batch["fresh"]), fresh):
			batch["units"] = int(batch["units"]) + units
			return
	var at := 0
	while at < batches.size() and float(batches[at]["fresh"]) < fresh:
		at += 1
	batches.insert(at, {"units": units, "fresh": fresh})


## Takes `units` (oldest first). Returns the lowest freshness taken.
func _remove(dish: DishData, units: int) -> float:
	if dish.keeps_overnight:
		_counts[dish.id] = count(dish) - units
		return FULL_FRESHNESS
	var batches := _batches(dish)
	var lowest := FULL_FRESHNESS
	while units > 0 and not batches.is_empty():
		var batch: Dictionary = batches[0]
		lowest = minf(lowest, float(batch["fresh"]))
		var used := mini(units, int(batch["units"]))
		batch["units"] = int(batch["units"]) - used
		units -= used
		if int(batch["units"]) <= 0:
			batches.remove_at(0)
	return lowest


static func _units(entry: Variant) -> int:
	if entry is Array:
		var sum := 0
		for batch: Dictionary in entry:
			sum += int(batch["units"])
		return sum
	return int(entry) if entry is int or entry is float else 0
