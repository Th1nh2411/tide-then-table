extends Node
## Native restaurant workflow regression: cooking, pickup, eating, cleaning and stock.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	var tom: FishData = load("res://data/fish/tom.tres")
	var dish: DishData = load("res://data/dishes/tom_luoc.tres")
	GameState.caught_species[tom.id] = 1
	GameState.storage.append(InventoryItem.new(tom))
	GameState.storage.append(InventoryItem.new(tom))
	var packed: PackedScene = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn")
	var room = packed.instantiate()
	room.arrival_cutscenes.clear()
	add_child(room)
	await get_tree().process_frame
	assert(room.plan.add_portion(dish, GameState.storage))
	var before_walk: Vector3 = room.player.position
	Input.action_press("turn_right")
	for i: int in range(20):
		await get_tree().physics_frame
	Input.action_release("turn_right")
	if room.player.position.distance_to(before_walk) > 0.3:
		print("PASS Rin moves before shift")
	else:
		print("FAIL Rin moves before shift")
	room.player.position = room.BOARD_POSITION + Vector3(0, 0, 1.0)
	room._interact()
	print("PASS board opens menu" if room.planning_panel.visible else "FAIL board opens menu")
	print("PASS HUD menu button before shift" if room.hud.menu_button.visible and not room.hud.close_button.visible else "FAIL HUD menu button before shift")
	room._open_shift()
	await get_tree().process_frame
	await get_tree().process_frame
	print("PASS Dong som button during shift" if room.hud.close_button.visible and not room.hud.menu_button.visible else "FAIL Dong som button during shift")
	room._spawn_order()
	room.hud.close_button.pressed.emit()
	room.hud.close_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	print("PASS early close stops spawns" if room.seconds_left <= 0.0 and not room.hud.close_button.visible else "FAIL early close stops spawns")
	room.seconds_left = 100.0
	var table: int = -1
	for i: int in range(room.orders.size()):
		if not room.orders[i].is_empty():
			table = i
	assert(table >= 0)
	var money: int = GameState.money
	room.carrying_table = table
	room._serve(table)
	assert(room.served == 0 and not room.orders[table].get("phase", "waiting") == "eating", "Uncooked dish served")
	room.carrying_table = -1
	room._tick_bao(0.0)
	room._tick_bao(10.0)
	assert(room.orders[table]["cooked"], "Bảo did not cook")
	assert(room.carrying_table == -1, "Plate teleported into Rin's hands")
	assert(room._pickup_ready(), "Pickup bench empty after cooking")
	room._serve(table)
	assert(GameState.money == money and room.served == 0, "Paid before guest finished meal")
	assert(room.orders[table]["phase"] == "eating")
	room._finish_meal(table)
	assert(GameState.money > money and room.served == 1)
	assert(room.dirty_tables[table], "Meal did not leave dirty table")
	var paid: int = GameState.money
	room._finish_meal(table)
	assert(GameState.money == paid and room.served == 1, "Meal paid twice")
	GameState.storage.append(InventoryItem.new(tom))
	GameState.storage.append(InventoryItem.new(tom))
	assert(room.plan.add_portion(dish, GameState.storage))
	room.dirty_tables.fill(true)
	room._spawn_order()
	assert(room.orders.all(func(order: Dictionary) -> bool: return order.is_empty()), "Guests sat at dirty table")
	room.dirty_tables.fill(false)
	room.dirty_tables[table] = true
	room._clean_table(table)
	assert(not room.dirty_tables[table])
	room._spawn_order()
	var drain_table: int = -1
	for i: int in range(room.orders.size()):
		if not room.orders[i].is_empty():
			drain_table = i
	assert(drain_table >= 0)
	room.seconds_left = 0.0
	room._process(0.0)
	assert(room.shift_running, "Closing discarded a waiting guest")
	room._tick_bao(0.0)
	room._tick_bao(10.0)
	assert(room._pickup_ready())
	room._serve(drain_table)
	room._process(1.0)
	assert(room.shift_running, "Closing discarded a guest still eating")
	room._process(5.0)
	assert(room.shift_over and not GameState.day_history.is_empty())
	await get_tree().process_frame
	var after_walk: Vector3 = room.player.position
	Input.action_press("turn_left")
	for i: int in range(20):
		await get_tree().physics_frame
	Input.action_release("turn_left")
	print("PASS Rin moves after summary" if room.player.position.distance_to(after_walk) > 0.3 else "FAIL Rin moves after summary")
	print("PASS evening buttons" if room.hud.sail_button.visible and room.hud.renovate_button.visible else "FAIL evening buttons")
	var ledger_size: int = GameState.day_history.size()
	var closing_money: int = GameState.money
	room._end_shift()
	assert(GameState.day_history.size() == ledger_size and GameState.money == closing_money, "Duplicate closure charged wages/ledger twice")
	room.queue_free()
	await get_tree().process_frame
	GameState.reset()
	GameState.day = 4
	var rau: DishData = load("res://data/dishes/rau_muong_xao_toi.tres")
	room = packed.instantiate()
	room.arrival_cutscenes.clear()
	add_child(room)
	await get_tree().process_frame
	GameState.set_flag("vy_hire_now")
	room._apply_arrival_choice()
	assert(room.staff_roster.hired().any(func(person: StaffData) -> bool: return person.id == "vy"), "Vy arrival choice did not hire her")
	assert(not GameState.story_flags.has("vy_hire_now"))
	room.market_stock.add(rau, rau.portion_units)
	assert(room.plan.is_sold_out() and room._has_stock(), "Pantry-only menu blocked")
	room._open_shift()
	assert(room.shift_running)
	room.market_stock.add(rau, rau.portion_units * 4)
	room._spawn_order()
	var pt: int = -1
	for i: int in range(room.orders.size()):
		if not room.orders[i].is_empty():
			pt = i
	assert(pt >= 0 and room.orders[pt].has("party"), "Walk-in has no party")
	var party := PartyOrders3D.new()
	party.guests = 2
	party.lines_total = 2
	room.market_stock.take(rau)
	party.queue.append({"dish": rau, "items": [] as Array[InventoryItem], "freshness": 100.0})
	room.orders[pt]["party"] = party
	room.orders[pt]["cooked"] = true
	room.orders[pt]["phase"] = "eating"
	room.orders[pt]["multiplier"] = 1.0
	room.orders[pt]["meal_left"] = 1.0
	var party_cash: int = GameState.money
	var served_party0: int = room.served
	room._finish_meal(pt)
	assert(not room.orders[pt].is_empty() and GameState.money == party_cash and room.served == served_party0, "Table paid party_cash all lines eaten")
	assert(str(room.orders[pt]["phase"]) == "waiting" and not bool(room.orders[pt]["cooked"]), "Second line not queued")
	room.orders[pt]["cooked"] = true
	room.orders[pt]["phase"] = "eating"
	party.more_rounds = 0
	room._finish_meal(pt)
	assert(room.orders[pt].is_empty() and room.served == served_party0 + 1, "Party not closed once")
	assert(GameState.money - party_cash >= party.bill and party.bill > 0, "Bill is not the whole table's sum")
	assert(party.bill > 0)
	# leaving early returns queued stock and pays eaten lines
	var stock: int = room.market_stock.portions(rau)
	var leaver := PartyOrders3D.new()
	leaver.queue.append({"dish": rau, "items": [] as Array[InventoryItem], "freshness": 100.0})
	leaver.bill = 10
	room.dirty_tables[pt] = false
	room.orders[pt] = {"dish": rau, "items": [] as Array[InventoryItem], "freshness": 100.0, "patience": 0.0, "initial_patience": 38.0,
		"visit": {}, "cooked": false, "staff_claimed": false, "multiplier": 1.0, "rich": false, "party": leaver}
	var cash: int = GameState.money
	room._lose_order(pt)
	assert(GameState.money - cash == 10 and room.market_stock.portions(rau) > stock, "Early leave: bill/stock wrong")
	print("PASS 3D party: multi-line table, one bill, early leave")
	# Bag flow: shift purchases wait in the bag until stored at the fridge.
	var rau_before: int = room.market_stock.portions(rau)
	GameState.money = 500
	room._buy_market(rau, false)
	assert(room.bag.has_goods() and room.market_stock.portions(rau) == rau_before, "Bought goods skipped the bag")
	room.player.position = MarketBag3D.FRIDGE_POSITION + Vector3(0.5, 0, 1.0)
	room._interact()
	assert(not room.bag.has_goods() and room.market_stock.portions(rau) > rau_before, "Fridge did not take the bag")
	print("PASS bag -> fridge")
	room.queue_free()
	await get_tree().process_frame
	GameState.reset()
	GameState.money = 5000
	room = packed.instantiate()
	room.arrival_cutscenes.clear()
	add_child(room)
	await get_tree().process_frame
	var seats: UpgradeData = room.seats_upgrade
	var reno: RenovationPreview3D = RenovationPreview3D.new()
	room.add_child(reno)
	var ups: Array[UpgradeData] = [room.seats_upgrade, room.decor_upgrade, room.kitchen_upgrade, room.fridge_upgrade]
	var spots: Array[Vector3] = []
	spots.assign(room.TABLES)
	reno.setup(room, spots, ups, null)
	reno.open()
	reno.set_level(seats, 2)
	var cost: int = reno.total_cost()
	assert(cost > 0 and reno.ghosts.get_child_count() > 0, "No preview ghosts")
	reno.cancel()
	assert(GameState.get_upgrade_level(seats.id) == 0 and GameState.money == 5000, "Cancel changed state")
	reno.open()
	reno.set_level(seats, 2)
	assert(reno.apply() and GameState.get_upgrade_level(seats.id) == 2 and GameState.money == 5000 - cost, "Confirm failed")
	print("PASS renovation preview cancel/confirm")
	print("PASS native restaurant cook/pickup/eat/pay/clean + pantry-only menu")
	get_tree().quit()
