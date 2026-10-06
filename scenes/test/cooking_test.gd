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

	var rng := RandomNumberGenerator.new()
	_check("order prefers cookable dish", KitchenLogic.pick_order(menu.dishes, storage, rng) == oc_dish)

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
