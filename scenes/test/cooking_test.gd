extends Control
## Standalone test for the kitchen (run with F6).
## 1. Runs KitchenLogic checks (ingredients, price formula) and prints PASS/FAIL.
## 2. Number keys 1-5 open the cooking minigame for that dish.

@export var menu: DishCatalog
@export var fish_catalog: FishCatalog

var _failures: int = 0
var _log: PackedStringArray = []

@onready var _cooking: CookingOverlay = $CookingOverlay
@onready var _info_label: Label = %InfoLabel


func _ready() -> void:
	_run_logic_tests()
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

	# Market dish: costs money instead of storage, no slot, auto never buys it.
	var rau := _dish("rau_muong_xao_toi")
	_check("auto fill skips market dish", auto.get_portion_count(rau) == 0)
	var market := MenuPlan.new(0, 25)  # zero seafood slots, 25k budget
	_check("market dish ignores slots", market.add_portion(rau, storage))
	_check("second portion within budget", market.add_portion(rau, storage) and market.market_spent == 20)
	_check("budget limit", not market.add_portion(rau, storage))
	market.remove_portion(rau, storage)
	_check("remove refunds market cost", market.market_spent == 10)
	_check("market portion servable", market.take_portion(rau).is_empty() and market.is_sold_out())
	market.return_portion(rau, [] as Array[InventoryItem])
	_check("market portion returns", market.get_portion_count(rau) == 1)
	_check("market price = base × cook", KitchenLogic.calc_price(rau, 1.3, [] as Array[InventoryItem]) == 39)


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
