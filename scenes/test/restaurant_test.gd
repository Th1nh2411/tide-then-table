extends Control
## Standalone test for restaurant service logic (run with F6): the kitchen
## shelf (capacity, regular plates), arrival-order matching for the waiter,
## plate table slots and table states (free -> taken -> dirty -> cleaned).

@export var menu: DishCatalog

var _failures: int = 0


func _ready() -> void:
	var a: DishData = menu.dishes[0]
	var b: DishData = menu.dishes[1]
	var shelf := DishShelf.new(3)
	var plate_a := DishShelf.Plate.new(a)
	var plate_b := DishShelf.Plate.new(b)
	_check("shelf add", shelf.add(plate_a) and shelf.add(plate_b) and shelf.plates.size() == 2)
	var visit := {"order": {"who": "Chú Ba"}}
	var regular_plate := DishShelf.Plate.new(a, [], 1.3, visit)
	shelf.add(regular_plate)
	_check("shelf full", shelf.is_full() and not shelf.add(DishShelf.Plate.new(a)))
	_check("count skips regular plates", shelf.count(a) == 1)
	_check("normal order gets normal plate", shelf.find_for(a, {}) == plate_a)
	_check("regular gets their plate", shelf.find_for(a, visit) == regular_plate)

	# Arrival order: the first customer whose dish is on the shelf.
	var first := _order(b, {})       # arrived first, has a plate
	var second := _order(a, {})
	var no_plate := _order(menu.dishes[2], {})
	var found := shelf.next_delivery([no_plate, first, second])
	_check("oldest order with a plate", found.get("order") == first and found.get("plate") == plate_b)
	shelf.remove(plate_b)
	_check("then the next one", shelf.next_delivery([no_plate, first, second]).get("order") == second)
	_check("nothing matches -> {}", shelf.next_delivery([no_plate]).is_empty())

	# Plate table slots: put on a chosen cell, take that one back.
	var pass_table := DishShelf.new(5)
	pass_table.add(plate_a, 3)
	_check("plate on chosen slot", pass_table.plate_at(3) == plate_a and pass_table.plate_at(0) == null)
	_check("slot taken", not pass_table.add(plate_b, 3))
	pass_table.remove(plate_a)
	_check("slot freed", pass_table.plate_at(3) == null and pass_table.plates.is_empty())

	# Tables.
	var tables := DiningTables.new()
	tables.setup(3)
	tables.take(tables.free_seat())
	_check("taken seat skipped", tables.free_seat() == 1)
	tables.make_dirty(0)
	_check("dirty listed", tables.dirty_seats() == [0] and tables.free_seat() == 1)
	tables.clean(0)
	_check("cleaned -> free", tables.free_seat() == 0 and tables.dirty_seats().is_empty())
	tables.take(1)
	tables.release(1)
	_check("left without eating -> free", tables.states[1] == DiningTables.State.FREE)
	_test_picker_and_bill()
	var guest := Customer.new()
	guest.state = Customer.State.DINING
	guest.add_order(TableOrder.new(menu.dishes[0]))
	Customer.patience_paused = true
	guest._process(5.0)
	var kept := guest.patience == 1.0
	Customer.patience_paused = false
	guest._process(5.0)
	_check("patience waits while a guide pointer shows", kept and guest.patience < 1.0)
	guest.free()
	# The restaurant has no camera; nothing (e.g. the cutscene camera) may
	# become current by itself, or the view shifts to the top-left corner.
	var room: Node = load("res://scenes/restaurant/restaurant_scene.tscn").instantiate()
	add_child(room)
	await get_tree().process_frame
	_check("restaurant view not moved by a camera", get_viewport().get_camera_2d() == null)
	room.queue_free()
	print("Restaurant: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _test_picker_and_bill() -> void:
	var seafood: DishData
	var side: DishData
	for dish in menu.dishes:
		if dish.always_available and side == null:
			side = dish
		elif not dish.is_market_dish() and seafood == null:
			seafood = dish
	var plan := MenuPlan.new(3)
	plan._portions[seafood] = [[] as Array[InventoryItem], [] as Array[InventoryItem]]
	var shelf := DishShelf.new(3)
	var picker := OrderPicker.new(shelf, [side] as Array[DishData])
	picker.plan = plan
	var waiting: Array = [_order(seafood, {})]
	_check("servable = portions - waiting lines", picker.servable(seafood, waiting) == 1)
	shelf.add(DishShelf.Plate.new(seafood))
	_check("plates on the pass count too", picker.servable(seafood, waiting) == 2)
	_check("no side chance -> seafood", picker.pick(0.0, waiting) == seafood)
	_check("side chance 1 -> side", picker.pick(1.0, waiting) == side)
	waiting.append_array([_order(seafood, {}), _order(seafood, {})])
	_check("seafood all promised -> side", picker.pick(0.0, waiting) == side)
	_check("order size: 1 guest, no extra", picker.first_order_size(1, 0.0, 3) == 1)
	_check("order size: 2 guests + extra, capped", picker.first_order_size(2, 1.0, 2) == 2)
	var plate := DishShelf.Plate.new(side, [] as Array[InventoryItem], 1.0)
	var regular := DishShelf.Plate.new(seafood, [] as Array[InventoryItem], 1.5, {"order": {"reward": 100}})
	var plates: Array[DishShelf.Plate] = [plate, regular]
	_check("bill: market dish × variety × rich, regular by reward", TableBill.total(plates, 1.0, 1.0)
		== side.base_price + 150 and TableBill.plate_price(plate, 0.5, 2.0) == side.base_price)
	var stages: Array[ServiceTuning] = []
	for day: int in [1, 2, 5]:
		var stage := ServiceTuning.new()
		stage.from_day = day
		stages.append(stage)
	_check("stage by day", CustomerManager.stage_for(stages, 1) == stages[0]
		and CustomerManager.stage_for(stages, 4) == stages[1] and CustomerManager.stage_for(stages, 9) == stages[2])
	var shipped: Array[ServiceTuning] = []
	for day: int in [1, 2, 3, 5]:
		shipped.append(load("res://data/restaurant/service_day%d.tres" % day))
	var day1 := CustomerManager.stage_for(shipped, 1)
	_check("day 1 is simple: one guest, one dish, no extra round", day1.pair_chance == 0.0
		and day1.extra_dish_chance == 0.0 and day1.max_more_rounds == 0)
	_check("tip only above the threshold", TableBill.tip(100, 0.6, 0.5, 0.2) == 20 and TableBill.tip(100, 0.4, 0.5, 0.2) == 0)


func _order(dish: DishData, visit: Dictionary) -> TableOrder:
	return TableOrder.new(dish, visit)


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
