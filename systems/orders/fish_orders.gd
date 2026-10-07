class_name FishOrders
extends RefCounted
## Fish orders from regulars (Dave the Diver style requests): "bring me a
## grouper of at least 4kg within 2 nights for 300k". Orders live in
## GameState.orders as Dictionaries:
##   {"who": String, "fish": fish id, "min_kg": float, "reward": int, "due_day": int}
## New orders arrive at the start of a day; they are delivered automatically
## on the rest screen (after the night trip) if storage has a big enough fish,
## and expire after the rest screen of `due_day`. Pure logic, no nodes.

const MAX_ACTIVE: int = 2
## Chance of a new order each morning (when below MAX_ACTIVE).
const NEW_ORDER_CHANCE: float = 0.7
## Nights to deliver, including the night the order arrives.
const NIGHTS_TO_DELIVER: int = 2
## Reward = base_price × required size × this, rounded to 10k.
const REWARD_MULTIPLIER: float = 2.5
## Required sizes (before snapping to a round weight) and their weights.
const SIZE_STEPS: Array[float] = [1.0, 1.2, 1.4]
const SIZE_WEIGHTS: Array[float] = [0.5, 0.35, 0.15]
const NAMES: Array[String] = ["Chú Ba", "Cô Tư", "Anh Sáu", "Bà Năm", "Ông Bảy", "Chị Hai"]


## Maybe adds a new order for GameState.day. Returns it, or {} if none.
static func roll_new_order(rng: RandomNumberGenerator, catalog: FishCatalog) -> Dictionary:
	if GameState.orders.size() >= MAX_ACTIVE or rng.randf() >= NEW_ORDER_CHANCE:
		return {}
	var order := make_order(rng, catalog, GameState.day)
	if not order.is_empty():
		GameState.orders.append(order)
	return order


## Builds an order for a rod fish the player has caught before (any shallow
## rod fish if the Dex is empty), from someone without an active order.
static func make_order(rng: RandomNumberGenerator, catalog: FishCatalog, day: int) -> Dictionary:
	var known: Array[FishData] = []
	var fallback: Array[FishData] = []
	for fish in catalog.fish:
		if fish.catch_method != FishData.CatchMethod.ROD or fish.is_aberrant:
			continue
		if int(GameState.caught_species.get(fish.id, 0)) > 0:
			known.append(fish)
		elif fish.lives_in(FishData.Zone.NEARSHORE):
			fallback.append(fish)
	var pool := known if not known.is_empty() else fallback
	var names: Array[String] = []
	for who in NAMES:
		if not GameState.orders.any(func(o: Dictionary) -> bool: return o.get("who") == who):
			names.append(who)
	if pool.is_empty() or names.is_empty():
		return {}
	var fish: FishData = pool[rng.randi() % pool.size()]
	var size := CatchRoll.snap_size(SIZE_STEPS[rng.rand_weighted(PackedFloat32Array(SIZE_WEIGHTS))], fish.typical_kg)
	return {
		"who": names[rng.randi() % names.size()],
		"fish": fish.id,
		"min_kg": fish.weight_kg(size),
		"reward": maxi(roundi(fish.base_price * size * REWARD_MULTIPLIER / 10.0) * 10, 10),
		"due_day": day + NIGHTS_TO_DELIVER - 1,
	}


## Rest screen: delivers what storage can fill (smallest fish that is big
## enough, paid at once), then drops orders whose last night has passed.
## Returns player-facing lines.
static func settle(catalog: FishCatalog) -> PackedStringArray:
	var lines: PackedStringArray = []
	var kept: Array = []
	for order: Dictionary in GameState.orders:
		var item := _best_item_for(order)
		if item:
			GameState.storage.erase(item)
			GameState.add_money(int(order["reward"]))
			lines.append("Giao %s %s cho %s: +%dk" % [item.fish.display_name,
				item.fish.weight_text(item.size), order["who"], order["reward"]])
		elif GameState.day >= int(order["due_day"]):
			lines.append("%s hủy đơn %s (quá hạn)" % [order["who"], fish_name(order, catalog)])
		else:
			kept.append(order)
	GameState.orders = kept
	return lines


## "Chú Ba: Cá mú từ 4kg · 300k · còn 2 đêm"
static func describe(order: Dictionary, catalog: FishCatalog) -> String:
	var nights := int(order["due_day"]) - GameState.day + 1
	return "%s: %s từ %s · %dk · %s" % [order["who"], fish_name(order, catalog),
		_kg_text(float(order["min_kg"])), order["reward"],
		"đêm cuối" if nights <= 1 else "còn %d đêm" % nights]


static func fish_name(order: Dictionary, catalog: FishCatalog) -> String:
	for fish in catalog.fish:
		if fish.id == order.get("fish"):
			return fish.display_name
	return "???"


## Validated copy of a saved order, or {} if it's malformed.
static func from_save(data: Variant, catalog: FishCatalog) -> Dictionary:
	if not data is Dictionary:
		return {}
	var who: Variant = data.get("who")
	var fish_id: Variant = data.get("fish")
	var min_kg: Variant = data.get("min_kg")
	var reward: Variant = data.get("reward")
	var due: Variant = data.get("due_day")
	if not (who is String and fish_id is String and _is_number(min_kg) and _is_number(reward) and _is_number(due)):
		return {}
	if not catalog.fish.any(func(f: FishData) -> bool: return f.id == fish_id):
		return {}
	return {"who": who, "fish": fish_id, "min_kg": maxf(float(min_kg), 0.0),
		"reward": maxi(int(reward), 0), "due_day": int(due)}


static func _best_item_for(order: Dictionary) -> InventoryItem:
	var best: InventoryItem = null
	for item: InventoryItem in GameState.storage:
		if item.fish.id != order["fish"]:
			continue
		var kg := item.fish.weight_kg(item.size)
		# Small tolerance: snapped sizes can land a hair under the round weight.
		if kg + 0.005 >= float(order["min_kg"]) and (best == null or kg < best.fish.weight_kg(best.size)):
			best = item
	return best


static func _kg_text(kg: float) -> String:
	return "%dkg" % roundi(kg) if kg >= 0.995 else "%dg" % (roundi(kg * 100.0) * 10)


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
