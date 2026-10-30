class_name RestaurantService3D
extends RefCounted
## Table orders of a shift: spawn, serve, bill, lose, close. State lives on the host
## (RestaurantScene3D: orders, dirty_tables, carrying_table, counters); this holds the rules.

var host: Node3D

func _init(owner: Node3D) -> void:
	host = owner

func spawn_order() -> void:
	var available: Array = host.plan.available_dishes()
	for dish in host.menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day and host.market_stock.portions(dish) > 0:
			available.append(dish)
	if available.is_empty() and host.regular_queue.is_empty():
		return
	var free: Array[int] = []
	for i in range(host.orders.size()):
		if host.orders[i].is_empty() and not host.dirty_tables[i]:
			free.append(i)
	if free.is_empty():
		return
	var table := free[host.rng.randi_range(0, free.size() - 1)]
	if not host.regular_queue.is_empty():
		var visit: Dictionary = host.regular_queue.pop_front()
		var regular_dish: DishData = visit["dish"]
		var reserved: Array[InventoryItem] = [visit["item"]]
		host.orders[table] = {"dish": regular_dish, "items": reserved, "freshness": 100.0,
			"patience": 38.0 * host.tuning.regular_patience_scale, "initial_patience": 38.0 * host.tuning.regular_patience_scale, "visit": visit,
			"cooked": false, "staff_claimed": false, "multiplier": 1.0, "rich": false}
		host.guests[table].call("set_variant", "guest_regular")
		host.guests[table].visible = true
		host.order_labels[table].text = "%s\n%s" % [visit["order"]["who"], regular_dish.display_name]
		host._show_note("%s tới nhận món đặt ở bàn %d." % [visit["order"]["who"], table + 1])
		return
	var dish: DishData = available[host.rng.randi_range(0, available.size() - 1)]
	var items: Array[InventoryItem] = []
	var freshness := 100.0
	if dish.is_market_dish():
		host.market_stock.take(dish)
		freshness = host.market_stock.last_freshness
	else:
		items = host.plan.take_portion(dish)
	var decor_level := GameState.get_upgrade_level("decor")
	var rich_chance: float = host.tuning.rich_chance_by_decor[clampi(decor_level, 0, host.tuning.rich_chance_by_decor.size() - 1)]
	var rich: bool = host.rng.randf() < rich_chance
	var patience: float = 38.0 * (host.tuning.rich_patience_scale if rich else 1.0)
	if PetCat.is_present():
		patience *= host.tuning.cat_patience_scale
	host.orders[table] = {"dish": dish, "items": items, "freshness": freshness, "patience": patience, "initial_patience": patience,
		"visit": {}, "cooked": false, "staff_claimed": false, "multiplier": 1.0, "rich": rich,
		"party": PartyOrders3D.start(host.tuning, host.plan, host.menu, host.market_stock)}
	host.guests[table].call("set_variant", "guest_rich" if rich else "guest_%d" % (1 + table % 3))
	host.guests[table].visible = true
	host.order_labels[table].text = ("KHÁCH SANG\n" if rich else "") + host.orders[table]["party"].label(dish)
	host._show_note("Bàn %d gọi %s." % [table + 1, dish.display_name])

func serve(table: int) -> void:
	var order: Dictionary = host.orders[table]
	if order.is_empty() or not bool(order.get("cooked", false)) or str(order.get("phase", "waiting")) != "waiting":
		return
	if host.carrying_table != table and not bool(order.get("staff_claimed", false)):
		return
	order["phase"] = "eating"
	order["meal_left"] = host.MEAL_SECONDS
	if host.carrying_table == table:
		host.carrying_table = -1
	host.order_labels[table].text = "Bàn %d • đang ăn" % (table + 1)
	host._show_note("Mời bàn %d dùng món!" % (table + 1))
	host._dispatch_ready()

func finish_meal(table: int) -> void:
	var order: Dictionary = host.orders[table]
	if order.is_empty() or str(order.get("phase", "")) != "eating":
		return
	var dish: DishData = order["dish"]
	var ingredients: Array[InventoryItem] = order["items"]
	var visit: Dictionary = order.get("visit", {})
	var plate := DishShelf.Plate.new(dish, ingredients, float(order["multiplier"]), visit)
	var variety := MenuPlan.variety_multiplier(host.opening_variety, MenuPanel3D.VARIETY_TABLE)
	var price := TableBill.plate_price(plate, variety, DailyTrend.price_scale(dish))
	if bool(order.get("rich", false)):
		price = roundi(float(price) * host.tuning.rich_price_scale)
	if dish.is_market_dish():
		price = roundi(float(price) * KitchenLogic.freshness_multiplier(float(order["freshness"])))
	var fresh: float = float(order["freshness"]) if dish.is_market_dish() else _items_freshness(ingredients)
	host.shift_log.record_dish(dish, price, DailyTrend.is_hot(dish), fresh)
	var party: PartyOrders3D = order.get("party")
	if party:
		party.bill += price
		if party.advance(order, host.tuning, host.plan, host.menu, host.market_stock):
			host.order_labels[table].text = party.label(order["dish"])
			host._show_note("Bàn %d gọi tiếp %s." % [table + 1, order["dish"].display_name])
			host._dispatch_ready()
			return
		price = party.bill
	var patience_ratio: float = float(order["patience"]) / float(order.get("initial_patience", 38.0))
	var tip: int = roundi(price * (host.tuning.tip_ratio + host.staff_roster.tip_bonus())) if visit.is_empty() and patience_ratio > host.tuning.tip_patience_threshold else 0
	GameState.add_money(price + tip)
	host.earned += price + tip
	host.shift_log.record_party(price, tip, patience_ratio, not visit.is_empty(), dish.id, fresh)
	if not visit.is_empty():
		FishOrders.complete(visit["order"])
		GameState.set_flag("regular_served_once")
		visit["served"] = true
	host.served += 1
	if host.carrying_table == table:
		host.carrying_table = -1
	host.orders[table] = {}
	host.dirty_tables[table] = true
	host.guests[table].visible = false
	host.order_labels[table].text = "Bàn %d • E dọn" % (table + 1)
	host._show_note("%s: +%dk. Cảm ơn khách bàn %d!" % [dish.display_name, price + tip, table + 1])
	Sfx.play("coins")
	host._dispatch_ready()

func lose_order(table: int) -> void:
	var already_cooked: bool = bool(host.orders[table].get("cooked", false))
	var wanted: DishData = host.orders[table].get("dish")
	var left_party: PartyOrders3D = host.orders[table].get("party")
	var part_paid: int = 0
	if left_party:
		part_paid = left_party.abandon(host.plan, host.market_stock)
		GameState.add_money(part_paid)
		host.earned += part_paid
	if table == host.cooking_table:
		host.cooking_table = -1
	if table == host.carrying_table:
		host.carrying_table = -1
	if not already_cooked:
		var dish: DishData = host.orders[table]["dish"]
		var visit: Dictionary = host.orders[table].get("visit", {})
		if not visit.is_empty():
			FishOrders.release(visit)
			visit["released"] = true
		elif dish.is_market_dish():
			host.market_stock.add(dish, dish.portion_units, float(host.orders[table]["freshness"]))
		else:
			var ingredients: Array[InventoryItem] = host.orders[table]["items"]
			host.plan.return_portion(dish, ingredients)
	host.orders[table] = {}
	host.guests[table].visible = false
	host.order_labels[table].text = ""
	host.lost += 1
	host.shift_log.record_lost(part_paid, wanted.id if wanted else "")
	host._show_note("Khách bàn %d đợi lâu quá nên bỏ về." % (table + 1))
	host._dispatch_ready()

func pickup_ready() -> bool:
	if host.carrying_table >= 0:
		return false
	for i: int in range(host.orders.size()):
		if host.orders[i].is_empty() or not bool(host.orders[i].get("cooked", false)) or bool(host.orders[i].get("staff_claimed", false)) or str(host.orders[i].get("phase", "waiting")) != "waiting":
			continue
		host.carrying_table = i
		host._show_note("Đem %s tới bàn %d." % [host.orders[i]["dish"].display_name, i + 1])
		return true
	host._show_note("Bảo: Chưa có món trên bàn nhận.")
	return false

func clean_table(table: int) -> void:
	if table < 0 or table >= host.dirty_tables.size() or not host.dirty_tables[table]:
		return
	host.dirty_tables[table] = false
	host.table_plates[table].visible = false
	host.order_labels[table].text = ""
	Sfx.play("ok")
	host._show_note("Đã dọn bàn %d." % (table + 1))

func end_shift() -> void:
	if host.shift_over:
		return
	host.shift_running = false
	host.shift_over = true
	DayClock.set_progress(1.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	var leftover: int = host.plan.total_portions()
	var limited_variety: bool = host.opening_variety < 2
	host.plan.clear(GameState.storage)
	for visit in host.regular_visits:
		if not bool(visit.get("cooked", false)) and not bool(visit.get("released", false)) and not bool(visit.get("served", false)):
			FishOrders.release(visit)
			visit["released"] = true
	FishOrders.expire_after_shift(host.fish_catalog)
	for person in host.staff_roster.hired():
		GameState.set_flag("worked_" + person.id)
	host.wages_paid = mini(host.staff_roster.wages(), GameState.money)
	GameState.add_money(-host.wages_paid)
	var stars := DayRating.stars(host.served, host.lost, limited_variety)
	GameState.last_rating = stars
	host.shift_results = host.goals.finish_shift(stars)
	var bonus: int = int(host.shift_results.get("bonus", 0))
	GameState.add_day_record({"day": GameState.day, "earned": host.earned, "market": host.market_spent, "rating": stars, "served": host.served, "left": host.lost, "wages": host.wages_paid, "bonus": bonus})
	if host.social:
		host.social.close_shift()
	var goal_lines := RestaurantGoals3D.summary_lines(host.shift_results)
	host.panels.show_summary("HẾT CA • XÓM ĐÈN\nPhục vụ: %d  |  Bỏ về: %d\nThu: %dk  |  Chợ: %dk  |  Lương: %dk\nDư: %d phần  |  Đánh giá: %d sao" % [host.served, host.lost, host.earned, host.market_spent, host.wages_paid, leftover, stars]
		+ ("\n" + goal_lines if goal_lines != "" else ""))

## Average freshness (0-100) of a plate's seafood (100 when none).
static func _items_freshness(items: Array[InventoryItem]) -> float:
	if items.is_empty():
		return 100.0
	var total := 0.0
	for item in items:
		total += item.freshness
	return total / items.size()

func sync_food_visuals() -> void:
	for i: int in range(host.orders.size()):
		var order: Dictionary = host.orders[i]
		host.ready_plates[i].visible = not order.is_empty() and bool(order.get("cooked", false)) and str(order.get("phase", "waiting")) == "waiting" and host.carrying_table != i and not bool(order.get("staff_claimed", false))
		host.table_plates[i].visible = host.dirty_tables[i] or (not order.is_empty() and str(order.get("phase", "waiting")) == "eating")

		var displayed_dish: DishData = order.get("dish")
		var is_beer := displayed_dish != null and displayed_dish.id == "bia_con_meo"
		for plate: Node3D in [host.ready_plates[i], host.table_plates[i]]:
			for part: Node in plate.get_children():
				if part is Node3D:
					part.visible = is_beer if part.name == "BeerTower" else not is_beer
