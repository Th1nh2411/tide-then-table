extends Control
## Standalone test for FishOrders (run with F6): order creation, delivery
## from storage, expiry, phone text and save validation.

@export var fish_catalog: FishCatalog

var _failures: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	GameState.reset()
	GameState.day = 3
	var order := FishOrders.make_order(_rng, fish_catalog, GameState.day)
	_check("empty dex -> shallow rod fish", not order.is_empty()
		and _fish(order["fish"]).lives_in(FishData.Zone.NEARSHORE))
	_check("due after 2 nights", int(order["due_day"]) == 4)
	GameState.record_catch(_fish("ca_mu"), 1)
	order = FishOrders.make_order(_rng, fish_catalog, GameState.day)
	_check("known fish ordered", order.get("fish") == "ca_mu")
	_check("min weight is round", is_equal_approx(float(order["min_kg"]), roundf(float(order["min_kg"]))))
	_check("reward rounded to 10k", int(order["reward"]) % 10 == 0 and int(order["reward"]) > 0)

	# Delivery: picks the smallest fish that is big enough.
	GameState.orders = [{"who": "Chú Ba", "fish": "ca_mu", "min_kg": 4.0, "reward": 300, "due_day": 4}]
	var small := InventoryItem.new(_fish("ca_mu"), 1.0, 1.0)  # 3kg
	var ok_fish := InventoryItem.new(_fish("ca_mu"), 1.0, 4.0 / 3.0)  # 4kg
	var huge := InventoryItem.new(_fish("ca_mu"), 1.0, 5.0 / 3.0)  # 5kg
	GameState.storage.append_array([small, huge, ok_fish])
	var money := GameState.money
	var lines := FishOrders.settle(fish_catalog)
	_check("delivered smallest big-enough fish", not GameState.storage.has(ok_fish)
		and GameState.storage.has(huge) and GameState.storage.has(small))
	_check("paid reward", GameState.money == money + 300 and GameState.orders.is_empty())
	_check("delivery line", lines.size() == 1 and lines[0].contains("Chú Ba") and lines[0].contains("4kg"))

	# Not delivered: kept until its last night, then cancelled.
	GameState.orders = [{"who": "Cô Tư", "fish": "cua", "min_kg": 0.5, "reward": 120, "due_day": 4}]
	FishOrders.settle(fish_catalog)
	_check("kept before due day", GameState.orders.size() == 1)
	_check("describe nights left", FishOrders.describe(GameState.orders[0], fish_catalog).contains("còn 2 đêm"))
	GameState.day = 4
	lines = FishOrders.settle(fish_catalog)
	_check("expired on due day", GameState.orders.is_empty() and lines[0].contains("hủy đơn"))

	# Limits and phone.
	GameState.orders = [
		{"who": "Chú Ba", "fish": "cua", "min_kg": 0.5, "reward": 1, "due_day": 9},
		{"who": "Cô Tư", "fish": "cua", "min_kg": 0.5, "reward": 1, "due_day": 9}]
	_check("max active orders", FishOrders.roll_new_order(_rng, fish_catalog).is_empty())
	_check("phone lists orders", PhoneReports.orders_report(fish_catalog).contains("[MSG] Chú Ba"))

	# Save validation.
	_check("save: good order", not FishOrders.from_save(GameState.orders[0], fish_catalog).is_empty())
	_check("save: unknown fish dropped", FishOrders.from_save({"who": "x", "fish": "ca_rong",
		"min_kg": 1, "reward": 1, "due_day": 1}, fish_catalog).is_empty())
	_check("save: junk dropped", FishOrders.from_save(5, fish_catalog).is_empty()
		and FishOrders.from_save({"who": "x"}, fish_catalog).is_empty())
	GameState.reset()
	print("FishOrders: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])


func _fish(id: String) -> FishData:
	for f in fish_catalog.fish:
		if f.id == id:
			return f
	return null
