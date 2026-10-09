extends Control
## Standalone test for the kitchen (run with F6).
## 1. Runs KitchenLogic checks (ingredients, price formula) and prints PASS/FAIL.
## 2. Number keys 1-5 open the cooking minigame for that dish.

@export var menu: DishCatalog
@export var fish_catalog: FishCatalog

## Beer pour bot: `pour` decides whether the tap is open each frame.
class PourBot:
	extends BeerPourGame
	var pour: Callable
	func _pouring() -> bool:
		return pour.call(self)


var _failures: int = 0
var _log: PackedStringArray = []

@onready var _cooking: CookingOverlay = $CookingOverlay
@onready var _info_label: Label = %InfoLabel


func _ready() -> void:
	_run_logic_tests()
	_run_pour_bots()
	_cooking.finished.connect(_on_cooking_finished)
	for i in menu.dishes.size():
		var dish := menu.dishes[i]
		_log.append("%d: %s (%s)" % [i + 1, dish.display_name, DishData.CookType.keys()[dish.cook_type]])
	_info_label.text = "\n".join(_log)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _cooking.is_running():
		return
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < menu.dishes.size():
		_cooking.start(menu.dishes[index])


func _on_cooking_finished(dish: DishData, result: CookingGameBase.Result, multiplier: float) -> void:
	_log.append("→ %s: %s x%.1f" % [dish.display_name, CookingGameBase.Result.keys()[result], multiplier])
	_info_label.text = "\n".join(_log)


func _run_logic_tests() -> void:
	var oc_dish := _dish("oc_huong_nuong_mo_hanh")  # 3 oc_huong, 70
	var cua_dish := _dish("cua_rang_me")             # 1 cua, 110
	var storage: Array = [_item("oc_huong", 1.0, 100), _item("oc_huong", 0.7, 50), _item("tom", 1.0, 100)]

	_check("can't cook with 2/3 ốc", not KitchenLogic.can_cook(oc_dish, storage))
	storage.append(_item("oc_huong", 1.0, 20))
	_check("can cook with 3 ốc", KitchenLogic.can_cook(oc_dish, storage))
	_check("can't cook cua without cua", not KitchenLogic.can_cook(cua_dish, storage))

	_test_menu_plan(oc_dish, cua_dish)

	var taken := KitchenLogic.take_ingredients(oc_dish, storage)
	_check("took 3 ốc", taken.size() == 3)
	_check("storage keeps the tôm", storage.size() == 1 and storage[0].fish.id == "tom")
	_check("take fails without stock", KitchenLogic.take_ingredients(oc_dish, storage).is_empty())

	_check("fresh x1.0", KitchenLogic.freshness_multiplier(80) == 1.0)
	_check("stale x0.7", KitchenLogic.freshness_multiplier(45) == 0.7)
	_check("old x0.4", KitchenLogic.freshness_multiplier(10) == 0.4)
	_check("spoiled x0", KitchenLogic.freshness_multiplier(0) == 0.0)

	# 70 × 1.3 × avg quality (1+0.7+1)/3=0.9 × avg fresh (1+0.7+0.4)/3=0.7 = 57.33 -> 57
	var price := KitchenLogic.calc_price(oc_dish, 1.3, taken)
	_check("price formula (got %d, want 57)" % price, price == 57)
	_log.insert(0, "KitchenLogic: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _test_menu_plan(oc_dish: DishData, cua_dish: DishData) -> void:
	var storage: Array = []
	for i in 7:
		storage.append(_item("oc_huong", 1.0, 100))
	storage.append(_item("cua", 1.0, 100))
	var plan := MenuPlan.new(1)
	_check("max portions 7 ốc -> 2", MenuPlan.max_portions(oc_dish, storage) == 2)
	_check("add portion", plan.add_portion(oc_dish, storage) and storage.size() == 5)
	_check("slot limit blocks 2nd dish", not plan.add_portion(cua_dish, storage))
	plan.add_portion(oc_dish, storage)
	_check("no stock for 3rd portion", not plan.add_portion(oc_dish, storage))
	plan.remove_portion(oc_dish, storage)
	_check("remove returns ingredients", storage.size() == 5 and plan.get_portion_count(oc_dish) == 1)
	var portion := plan.take_portion(oc_dish)
	_check("take portion", portion.size() == 3 and plan.is_sold_out())
	plan.return_portion(oc_dish, portion)
	_check("return portion", plan.get_portion_count(oc_dish) == 1)
	plan.clear(storage)
	_check("clear returns all", storage.size() == 8 and plan.total_portions() == 0)
	var auto := MenuPlan.new(3)
	auto.auto_fill(menu.dishes, storage)
	_check("auto fill uses stock (cua + 2 ốc)", auto.get_portion_count(cua_dish) == 1 and auto.get_portion_count(oc_dish) == 2 and storage.size() == 1)

	# Rau muống: always on the menu, never planned; produce bought at the stall.
	var rau := _dish("rau_muong_xao_toi")
	_check("rau is an always-on market dish", rau.always_available and rau.is_market_dish())
	_check("auto fill skips rau", auto.get_portion_count(rau) == 0)
	_check("rau can't be planned", not MenuPlan.new(3).can_add(rau, storage))
	_check("market price = base × cook", KitchenLogic.calc_price(rau, 1.3, [] as Array[InventoryItem]) == 39)
	var beer := _dish("bia_con_meo")
	_check("beer: always on, bought, no cooking", beer.always_available and beer.is_market_dish() and beer.instant_serve)
	_check("beer can't be planned", not MenuPlan.new(3).can_add(beer, storage))
	_check("no peanuts any more", menu.dishes.all(func(d: DishData) -> bool: return d.id != "dau_phong_rang"))
	var pantry: Dictionary = {}
	var stock := MarketStock.new(pantry)
	_check("stock starts empty", stock.count(rau) == 0 and not stock.take(rau))
	stock.add(rau)
	stock.add(rau)
	_check("bought 2 portions", stock.count(rau) == 2 and stock.total() == 2)
	_check("cooking takes one", stock.take(rau) and stock.count(rau) == 1)
	_check("bulk is cheaper per unit", rau.has_bulk() and beer.has_bulk()
		and rau.buy_cost(true) * rau.buy_units(false) < rau.buy_cost(false) * rau.buy_units(true)
		and beer.buy_cost(true) * beer.buy_units(false) < beer.buy_cost(false) * beer.buy_units(true))
	_check("price texts", rau.market_text() == "1 phần 10k · 10 phần 80k" and beer.buy_text(true) == "10 tháp 200k")
	stock.add(beer, beer.buy_units(true))
	_check("bulk beer = 30 litres = 10 towers", stock.count(beer) == 30 and stock.portions(beer) == 10)
	for k in 10:
		stock.take(beer)
	stock.add(beer, 2)
	_check("2 litres left: not enough for a tower", stock.count(beer) == 2 and not stock.take(beer))
	_check("stock writes the shared pantry", int(pantry.get("bia_con_meo", 0)) == 2)
	var both: Array[DishData] = [rau, beer]
	_check("closing wastes rau only", stock.discard_perishable(both) == 1 and stock.count(rau) == 0)
	_check("beer keeps overnight", MarketStock.new(pantry).count(beer) == 2)
	var bag := MarketStock.new({})
	bag.add(rau, 3)
	var fridge := MarketStock.new({})
	_check("bag -> fridge", bag.move_into(fridge, both) == 3 and fridge.count(rau) == 3 and bag.total() == 0)

	# Variety.
	var table: Array[float] = [0.8, 0.8, 0.9, 1.0]
	_check("variety 1 dish x0.8", MenuPlan.variety_multiplier(1, table) == 0.8)
	_check("variety 2 dishes x0.9", MenuPlan.variety_multiplier(2, table) == 0.9)
	_check("variety 5 dishes x1.0", MenuPlan.variety_multiplier(5, table) == 1.0)


func _run_pour_bots() -> void:
	var beer := _dish("bia_con_meo")
	# Perfect info, short bursts: let the head settle before it gets thick.
	var state := {"settling": false}
	var pulse := func(g: BeerPourGame) -> bool:
		if state["settling"]:
			state["settling"] = g.foam() > 0.01
			return false
		if g.top() >= 0.9:
			return false
		if g.foam() >= 0.1 and g.top() < 0.74:  # pause well below the band
			state["settling"] = true
			return false
		return true
	var r := _pour(beer, pulse)
	_check("pour bot: short bursts = PERFECT (%s, %.1fs)" % [r[0], r[1]], r[0] == "PERFECT" and r[1] < 6.0)
	var steady := func(g: BeerPourGame) -> bool: return g.top() < 0.9
	r = _pour(beer, steady)
	_check("pour bot: one long pour = OK (too much foam) (%s)" % r[0], r[0] == "OK")
	var greedy := func(g: BeerPourGame) -> bool: return g.spills == 0
	r = _pour(beer, greedy)
	_check("pour bot: never letting go spills once, then runs short (%s, spills %d)" % [r[0], r[2]],
		r[2] == 1 and r[0] == "BURNT")
	var game := BeerPourGame.new()
	_check("judge: thick head in band = OK", game.judge_pour(0.9, 0.25) == CookingGameBase.Result.OK)
	_check("judge: over the rim band = OK edge", game.judge_pour(1.0, 0.0) == CookingGameBase.Result.OK)
	game.free()
	var fridge := MarketStock.new({"bia_con_meo": 3})
	_check("spill wastes litres, never below 0", fridge.spill(beer, 1) == 1 and fridge.spill(beer, 5) == 2
		and fridge.count(beer) == 0)


## Runs a pour with `pour` deciding the tap; returns [result name, seconds, spills].
func _pour(beer: DishData, pour: Callable) -> Array:
	var bot := PourBot.new()
	bot.pour = pour
	bot.setup(beer)
	bot._time = 1.0  # past the input delay
	var result: Array[String] = ["NONE"]
	bot.completed.connect(func(res: CookingGameBase.Result) -> void: result[0] = CookingGameBase.Result.keys()[res])
	var seconds := 0.0
	while result[0] == "NONE" and seconds < 60.0:
		bot._update(1.0 / 60.0)
		seconds += 1.0 / 60.0
	var spills := bot.spills
	bot.free()
	return [result[0], seconds, spills]


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])


func _item(fish_id: String, quality: float, freshness: float) -> InventoryItem:
	for f in fish_catalog.fish:
		if f.id == fish_id:
			var item := InventoryItem.new(f, quality)
			item.freshness = freshness
			return item
	push_error("Unknown fish %s" % fish_id)
	return null


func _dish(id: String) -> DishData:
	for d in menu.dishes:
		if d.id == id:
			return d
	push_error("Unknown dish %s" % id)
	return null
