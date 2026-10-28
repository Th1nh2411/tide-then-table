extends Node
## Headless smoke test: run restaurant_3d_smoke.tscn as a scene.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	GameState.day = 3
	GameState.staff = {"hired": ["vy"], "candidates": [], "seen": ["vy"], "ad_day": 0}
	var tom: FishData = load("res://data/fish/tom.tres")
	GameState.caught_species[tom.id] = 3
	GameState.orders.append({"who": "Chú Ba", "fish": tom.id, "min_kg": 0.0,
		"reward": 300, "due_day": GameState.day + 1})
	for i in range(3):
		GameState.storage.append(InventoryItem.new(tom))
	var room = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	add_child(room)
	await get_tree().process_frame
	room.plan.auto_fill(room.menu.dishes, GameState.storage)
	assert(room.plan.total_portions() > 0, "3D menu did not reserve seafood")
	room._open_shift()
	room._spawn_order()
	var table := -1
	for i in range(room.orders.size()):
		if not room.orders[i].is_empty():
			table = i
			break
	assert(table >= 0, "3D guest did not order")
	assert(room.orders[table]["visit"]["order"]["who"] == "Chú Ba", "3D regular did not arrive")
	room.orders[table]["dish"] = load("res://data/dishes/tom_luoc.tres")
	room._tick_bao(0.0)
	room._tick_bao(10.0)
	assert(room.orders[table]["cooked"], "3D Bảo did not cook regular meal")
	room._move_staff(10.0)
	room._move_staff(10.0)
	assert(room.orders[table].get("phase", "") == "eating", "3D regular did not receive cooked plate")
	room._finish_meal(table)
	room.player.position = room.TABLES[table] + Vector3(0, 0, 1.2)
	assert(room.served == 1 and GameState.money > GameState.STARTING_MONEY, "3D service did not pay")
	assert(GameState.orders.is_empty(), "3D regular order was not completed")
	assert(room.staff_workers.size() == 1, "3D hired staff did not appear")
	var market_dish: DishData = load("res://data/dishes/rau_muong_xao_toi.tres")
	room._buy_market(market_dish, false)
	room.player.position = MarketBag3D.FRIDGE_POSITION + Vector3(0.5, 0, 1.0)
	room._interact()
	assert(room.market_stock.portions(market_dish) > 0 and room.market_spent > 0,
		"3D Cô Năm purchase did not reach persistent pantry")
	room.plan.clear(GameState.storage)
	room._spawn_order()
	var market_table := -1
	for i in range(room.orders.size()):
		if not room.orders[i].is_empty():
			market_table = i
			break
	assert(market_table >= 0 and room.orders[market_table]["dish"].id == market_dish.id,
		"3D market stock did not create a grocery dish order")
	room._tick_bao(0.0)
	room._tick_bao(10.0)
	assert(room.orders[market_table]["cooked"], "3D Bảo did not cook grocery meal")
	room._dispatch_ready()
	assert(room.staff_workers[0]["table"] == market_table, "3D staff did not claim cooked plate")
	room._move_staff(10.0)
	room._move_staff(10.0)
	assert(room.orders[market_table].get("phase", "") == "eating")
	room._finish_meal(market_table)
	assert(room.served == 2, "3D staff did not deliver grocery dish")
	room._end_shift()
	assert(room.shift_over and not GameState.day_history.is_empty(), "3D shift did not record results")
	assert(room.wages_paid > 0, "3D staff wages were not paid")
	GameState.money = 1000
	room._buy_upgrade(room.kitchen_upgrade)
	assert(GameState.get_upgrade_level("kitchen") == 1, "3D kitchen renovation did not persist")
	print("RESTAURANT 3D SMOKE PASS")
	get_tree().quit()
