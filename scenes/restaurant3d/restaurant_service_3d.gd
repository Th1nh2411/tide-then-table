class_name RestaurantService3D
extends RefCounted
## Table orders of a shift: spawn, serve, bill, lose, close. State lives on the host
## (RestaurantScene3D: orders, dirty_tables, carrying_table, counters); this holds the rules.
## Horror build: guests order from FIXED_MENU, always available (no planning, no stock).
## Bills are not money any more: they only add up `earned` for the ending card.

const FIXED_MENU: FixedMenuData = preload("res://data/restaurant/fixed_menu.tres")
const PATIENCE := 38.0

var host: Node3D

func _init(owner: Node3D) -> void:
	host = owner

func spawn_order() -> void:
	var free: Array[int] = []
	for i in range(host.orders.size()):
		if host.orders[i].is_empty() and not host.dirty_tables[i]:
			free.append(i)
	if free.is_empty():
		return
	var table := free[host.rng.randi_range(0, free.size() - 1)]
	var party := PartyOrders3D.start(host.tuning, FIXED_MENU.dishes)
	var dish: DishData = party.next_dish()
	host.orders[table] = {"dish": dish, "patience": PATIENCE, "initial_patience": PATIENCE,
		"cooked": false, "party": party}
	host.guests[table].call("set_variant", PersonRig3D.next_guest_variant())
	var partner := (host.guests[table] as Node).get_meta("seating_partner", null) as PersonRig3D
	if partner:
		partner.set_variant(PersonRig3D.next_guest_variant())
	host.guests[table].visible = true
	host.order_labels[table].text = party.label(dish)
	host._show_note("Bàn %d gọi %s." % [table + 1, dish.display_name])

func serve(table: int) -> void:
	var order: Dictionary = host.orders[table]
	if order.is_empty() or not bool(order.get("cooked", false)) or str(order.get("phase", "waiting")) != "waiting":
		return
	if host.carrying_table != table:
		return
	order["phase"] = "eating"
	order["meal_left"] = host.MEAL_SECONDS
	host.carrying_table = -1
	host.order_labels[table].text = "Bàn %d • đang ăn" % (table + 1)
	host._show_note("Mời bàn %d dùng món!" % (table + 1))

func finish_meal(table: int) -> void:
	var order: Dictionary = host.orders[table]
	if order.is_empty() or str(order.get("phase", "")) != "eating":
		return
	var dish: DishData = order["dish"]
	var party: PartyOrders3D = order["party"]
	party.bill += dish.base_price
	if party.advance(order, host.tuning):
		host.order_labels[table].text = party.label(order["dish"])
		host._show_note("Bàn %d gọi tiếp %s." % [table + 1, order["dish"].display_name])
		return
	host.earned += party.bill
	host.served += 1
	if host.carrying_table == table:
		host.carrying_table = -1
	host.orders[table] = {}
	host.dirty_tables[table] = true
	host.guests[table].visible = false
	host.order_labels[table].text = "Bàn %d • chưa dọn" % (table + 1)
	host._show_note("Cảm ơn khách bàn %d!" % (table + 1))
	Sfx.play("coins")

func lose_order(table: int) -> void:
	var party: PartyOrders3D = host.orders[table].get("party")
	if party:
		host.earned += party.bill
	if table == host.carrying_table:
		host.carrying_table = -1
	host.orders[table] = {}
	host.guests[table].visible = false
	host.order_labels[table].text = ""
	host.lost += 1
	host._show_note("Khách bàn %d đợi lâu quá nên bỏ về." % (table + 1))

func pickup_ready() -> bool:
	if host.carrying_table >= 0:
		return false
	var i := next_ready()
	if i >= 0:
		host.carrying_table = i
		host._show_note("%s của bàn %d." % [host.orders[i]["dish"].display_name, i + 1])
		return true
	host._show_note("Bảo: Chưa có món trên bàn nhận.")
	return false


## First cooked plate on the bench Rin may take (not Vy's), else -1.
func next_ready() -> int:
	for i: int in range(host.orders.size()):
		var order: Dictionary = host.orders[i]
		if order.is_empty() or not bool(order.get("cooked", false)) or str(order.get("phase", "waiting")) != "waiting":
			continue
		if not bool(order.get("staff", false)) and host.carrying_table != i:
			return i
	return -1


## The plate Vy should take: cooked, waiting, unclaimed, least patience left.
func staff_pick() -> int:
	var best := -1
	for i: int in range(host.orders.size()):
		var order: Dictionary = host.orders[i]
		if order.is_empty() or not bool(order.get("cooked", false)) or str(order.get("phase", "waiting")) != "waiting":
			continue
		if host.carrying_table == i or bool(order.get("staff", false)):
			continue
		if best < 0 or float(order["patience"]) < float(host.orders[best]["patience"]):
			best = i
	return best

## Vy set the plate she carried (order["staff"]) down; she says nothing.
func staff_serve(table: int) -> void:
	var order: Dictionary = host.orders[table]
	if order.is_empty() or not bool(order.get("staff", false)) or str(order.get("phase", "waiting")) != "waiting":
		return
	order.erase("staff")
	order["phase"] = "eating"
	order["meal_left"] = host.MEAL_SECONDS
	host.order_labels[table].text = "Bàn %d • đang ăn" % (table + 1)


## `quiet`: Vy wiped it (no note).
func clean_table(table: int, quiet := false) -> void:
	if table < 0 or table >= host.dirty_tables.size() or not host.dirty_tables[table]:
		return
	host.dirty_tables[table] = false
	host.table_plates[table].visible = false
	host.order_labels[table].text = ""
	if quiet:
		return
	Sfx.play("ok")
	host._show_note("Đã dọn bàn %d." % (table + 1))

func end_shift() -> void:
	if host.shift_over:
		return
	host.shift_running = false
	host.shift_over = true
	DayClock.set_progress(1.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	var stars := DayRating.stars(host.served, host.lost, false)
	GameState.last_rating = stars
	GameState.add_day_record({"day": GameState.day, "earned": host.earned, "rating": stars, "served": host.served, "left": host.lost})
	host._show_note("Bảo: Hết ca rồi. Rin về nghỉ đi.")

func sync_food_visuals() -> void:
	for i: int in range(host.orders.size()):
		var order: Dictionary = host.orders[i]
		host.ready_plates[i].visible = not order.is_empty() and bool(order.get("cooked", false)) and str(order.get("phase", "waiting")) == "waiting" and host.carrying_table != i and not bool(order.get("staff", false))
		host.table_plates[i].visible = host.dirty_tables[i] or (not order.is_empty() and str(order.get("phase", "waiting")) == "eating")

		var displayed_dish: DishData = order.get("dish")
		ServedFoodVisual3D.show_dish(host.ready_plates[i], displayed_dish, true)
		if not order.is_empty() or not host.dirty_tables[i]:
			ServedFoodVisual3D.show_dish(host.table_plates[i], displayed_dish, false, true)
	# What Rin carries: a beer tower or a plate.
	var held: Node3D = host.body.plate
	var carried: DishData = host.orders[host.carrying_table].get("dish") if host.carrying_table >= 0 else null
	ServedFoodVisual3D.show_dish(held, carried)


static func _show_beer(plate: Node3D, is_beer: bool) -> void:
	ServedFoodVisual3D.show_kind(plate, "beer_tower" if is_beer else "dish_plate_fish")
