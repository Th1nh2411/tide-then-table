class_name CustomerManager
extends Node
## Runs the street restaurant during a shift (Dave the Diver style service):
## parties of 1-2 ride in on motorbikes (CustomerBikes, the second guest on
## the back; some walk in along the pavement) to free tables; after reading
## the menu the party orders one dish per guest, sometimes one more
## (TableOrder lines: dishes that can still be served = menu portions +
## plates on the plate table, minus lines already waiting); Bảo cooks
## (ChefBao) and Rin grills / pours (KitchenStation); plates go on the plate
## table, and Rin — the waiter — carries them out and cleans the tables.
## They eat plate by plate as they come; with everything eaten they may
## order another round (often beer), else pay for all of it at once (+ tip
## if they kept their patience), walk back to their bike (or off the
## pavement) and leave a dirty table.
## Upgrades: seats (tables), decor (more often + well-off customers).
## Regulars with a fish order (FishOrders) come early in the shift.

signal customer_served(price: int, tip: int)
signal customer_left_angry
signal message_requested(text: String)
## A regular ate their order dish.
signal regular_served(who: String, price: int)

## Full dish catalog; always-available side dishes are taken from here.
@export var menu: DishCatalog
@export var room: StreetRoom
@export var bikes: CustomerBikes
## Y-sorted layer for customer nodes (and floating money text).
@export var people_layer: Node2D
## Seats upgrade: its value is the number of tables (default 4 without it).
@export var seats_upgrade: UpgradeData
## Decor upgrade: its value (0, 1, 2...) indexes the arrays below.
@export var decor_upgrade: UpgradeData
@export var decor_interval_scale: Array[float] = [1.0, 0.85, 0.72]
@export var rich_chance_by_decor: Array[float] = [0.0, 0.15, 0.3]
@export var rich_price_scale: float = 1.5
@export var rich_patience_scale: float = 0.75
## Regulars wait longer, and come this many seconds into the shift.
@export var regular_patience_scale: float = 2.0
@export var regular_delay: float = 6.0
## Share of customers who come on foot instead of by motorbike.
@export var walk_in_chance: float = 0.2
@export var first_spawn_delay: float = 1.5
@export var min_spawn_interval: float = 6.0
@export var max_spawn_interval: float = 11.0
## Tip = price × tip_ratio, only if served with patience above the threshold.
@export var tip_ratio: float = 0.2
@export var tip_patience_threshold: float = 0.5
## Spawn interval multiplier by yesterday's rating (index = stars, 0 unused).
@export var interval_scale_by_rating: Array[float] = [1.0, 1.3, 1.15, 1.0, 0.85, 0.7]
## Chance a line is a side (rau muống, beer) while seafood is left; extra
## rounds pick a side more often.
@export var side_order_chance: float = 0.25
@export var round_side_chance: float = 0.6
## Chance a party is two guests (regulars come alone).
@export var pair_chance: float = 0.45
## Chance of one more dish than guests in the first order (max 3 lines).
@export var extra_dish_chance: float = 0.35
@export var max_lines: int = 3
## Chance to order another round once everything is eaten, and how many.
@export var more_round_chance: float = 0.35
@export var max_more_rounds: int = 1
## Patience multiplier while the restaurant cat is around ("mèo chiêu tài").
@export var cat_patience_scale: float = 1.1
@export var pass_capacity: int = 5

## The plate table (cooked dishes waiting to be carried out).
var shelf: DishShelf
## Ordered dishes still to bring, in order of ordering.
var waiting: Array[TableOrder] = []
## Regular visits for today: [{"order", "item", "dish", "cooked"?}].
var regular_visits: Array[Dictionary] = []
## Table states (StreetRoom.dining).
var tables: DiningTables

var _customers: Array[Customer] = []  # party leaders
var _regulars_to_spawn: Array[Dictionary] = []
var _shift_time: float = 0.0
var _decor_level: int = 0
var _plan: MenuPlan
var _sides: Array[DishData] = []
var _variety_multiplier: float = 1.0
var _interval_scale: float = 1.0
var _accepting: bool = false
var _spawn_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	shelf = DishShelf.new(pass_capacity)
	room.shelf = shelf
	refresh_upgrades()
	bikes.parked.connect(_on_bike_parked)
	for dish in menu.dishes:
		if dish.always_available:
			_sides.append(dish)


func decor_level() -> int:
	return _decor_level


## Reads the seats and decor levels (also after renovating, nobody inside).
func refresh_upgrades() -> void:
	room.setup_tables(int(GameState.get_upgrade_value(seats_upgrade)) if seats_upgrade else 4)
	tables = room.dining
	_decor_level = int(GameState.get_upgrade_value(decor_upgrade)) if decor_upgrade else 0
	room.decor_level = _decor_level


## `visits` from FishOrders.reserve_for_shift() (fish already set aside).
func start_shift(plan: MenuPlan, variety_multiplier: float = 1.0, visits: Array[Dictionary] = []) -> void:
	_plan = plan
	_variety_multiplier = variety_multiplier
	_interval_scale = interval_scale_by_rating[clampi(GameState.last_rating, 0, interval_scale_by_rating.size() - 1)]
	_interval_scale *= _by_decor(decor_interval_scale)
	regular_visits = visits
	_regulars_to_spawn = visits.duplicate()
	_shift_time = 0.0
	_accepting = true
	_spawn_left = first_spawn_delay


## No new customers; those already here are still served and eat (or run
## out of patience) before the shop really closes.
func stop_shift() -> void:
	_accepting = false
	_regulars_to_spawn.clear()


## Nobody here.
func is_idle() -> bool:
	return _customers.is_empty()


## Regular visits whose fish was never cooked (it goes back to storage).
func uncooked_regular_visits() -> Array[Dictionary]:
	return regular_visits.filter(func(v: Dictionary) -> bool: return not v.get("cooked", false))


## A plate Rin carried to `seat`: serve it if that table ordered this dish.
func serve_at(seat: int, plate: DishShelf.Plate) -> bool:
	for order in waiting:
		if order.seat == seat and order.dish == plate.dish and order.visit == plate.visit:
			waiting.erase(order)
			order.party.serve(order, plate)
			tables.put_plate(seat, plate)
			return true
	return false


## Party leaders with lines still waiting, oldest line first.
func waiting_parties() -> Array[Customer]:
	var result: Array[Customer] = []
	for order in waiting:
		if order.party not in result:
			result.append(order.party)
	return result


func _process(delta: float) -> void:
	if not _accepting:
		return
	_shift_time += delta
	if not _regulars_to_spawn.is_empty() and _shift_time >= regular_delay and tables.free_seat() != -1:
		_spawn(_regulars_to_spawn.pop_front())
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = _rng.randf_range(min_spawn_interval, max_spawn_interval) * _interval_scale
		if tables.free_seat() != -1 and _anything_to_order():
			_spawn({})


## `visit` = a regular's visit, or {} for a walk-in customer.
func _spawn(visit: Dictionary) -> void:
	var free := tables.free_seats()
	var customer := Customer.new()
	customer.seat = free[_rng.randi() % free.size()]
	if visit.is_empty():
		customer.rich = _rng.randf() < _by_decor(rich_chance_by_decor)
		if customer.rich:
			customer.patience_seconds *= rich_patience_scale
		if _rng.randf() < pair_chance:
			customer.companion = Customer.new()
			customer.companion.leader = customer
			customer.companion.seat = customer.seat
		customer.more_rounds = max_more_rounds
	else:
		customer.visit = visit
		customer.regular_name = visit["order"]["who"]
		customer.patience_seconds *= regular_patience_scale
		message_requested.emit("%s tới ăn món đã đặt!" % customer.regular_name)
	if PetCat.is_present():
		customer.patience_seconds *= cat_patience_scale
	customer.ordered.connect(_on_ordered)
	customer.patience_ran_out.connect(_send_away.bind(true))
	customer.finished_eating.connect(_on_finished_eating)
	tables.take(customer.seat)
	_customers.append(customer)
	if _rng.randf() >= walk_in_chance:
		customer.bike = bikes.arrive(customer.companion != null)
	if customer.bike == null:
		_walk_in(customer, _entrance())


func _walk_in(customer: Customer, from: Vector2i) -> void:
	var table: Dictionary = room.tables[customer.seat]
	customer.position = room.grid.to_world(from)
	people_layer.add_child(customer)
	customer.go_to_seat(room.grid.path(from, table["chair"]))
	if customer.companion:
		var guest := customer.companion
		guest.position = customer.position + Vector2(-6, 2)
		people_layer.add_child(guest)
		guest.go_to_seat(room.grid.path(from, table["spare"]))


func _on_bike_parked(bike: CustomerBikes.Bike) -> void:
	for customer in _customers:
		if customer.bike == bike:
			_walk_in(customer, bike.parking)


func _on_ordered(customer: Customer) -> void:
	if not customer.visit.is_empty():
		_add_line(customer, customer.visit["dish"], customer.visit)
		return
	var guests := 2 if customer.companion else 1
	var lines := mini(guests + (1 if _rng.randf() < extra_dish_chance else 0), max_lines)
	for i in lines:
		var dish := _pick_order(side_order_chance)
		if dish:
			_add_line(customer, dish)
	if customer.orders.is_empty():
		_send_away(customer, false)


func _add_line(customer: Customer, dish: DishData, visit: Dictionary = {}) -> void:
	var order := TableOrder.new(dish, visit, customer)
	customer.add_order(order)
	waiting.append(order)


## A seafood dish that can still be served, or a side dish (sometimes by
## choice, always once the seafood is gone; always orderable: Rin buys its
## produce at the stall). Null only if there is nothing at all.
func _pick_order(side_chance: float) -> DishData:
	var dishes: Array[DishData] = []
	for dish in _plan.get_dishes():
		if _servable(dish) > 0:
			dishes.append(dish)
	var wants_side := dishes.is_empty() or _rng.randf() < side_chance
	if wants_side and not _sides.is_empty():
		return _sides[_rng.randi() % _sides.size()]
	if dishes.is_empty():
		return null
	return dishes[_rng.randi() % dishes.size()]


## Portions not yet promised to a waiting customer.
func _servable(dish: DishData) -> int:
	var promised := waiting.filter(func(o: TableOrder) -> bool: return o.dish == dish and o.visit.is_empty()).size()
	return _plan.get_portion_count(dish) + shelf.count(dish) - promised


func _anything_to_order() -> bool:
	return not _sides.is_empty() or _plan.get_dishes().any(func(d: DishData) -> bool: return _servable(d) > 0)


func _on_finished_eating(customer: Customer) -> void:
	if customer.state != Customer.State.DINING:
		return
	if customer.more_rounds > 0 and _accepting and _rng.randf() < more_round_chance:
		customer.more_rounds -= 1
		var dish := _pick_order(round_side_chance)
		if dish:
			_add_line(customer, dish)
			_float_text(customer.position, "Thêm món!")
			return
	_pay(customer, true)
	_leave(customer)


## Pays for every plate eaten (tip only if `tip_ok` and still patient);
## leaves the table dirty, or free if nothing was eaten.
func _pay(customer: Customer, tip_ok: bool) -> void:
	if customer.eaten.is_empty():
		tables.release(customer.seat)
		return
	var price := 0
	for plate in customer.eaten:
		if not plate.visit.is_empty():
			var reward := roundi(int(plate.visit["order"]["reward"]) * plate.cook_multiplier)
			FishOrders.complete(plate.visit["order"])
			regular_served.emit(customer.regular_name, reward)
			price += reward
		else:
			price += roundi(KitchenLogic.calc_price(plate.dish, plate.cook_multiplier, plate.ingredients)
				* _variety_multiplier * (rich_price_scale if customer.rich else 1.0))
	var tip := roundi(price * tip_ratio) if tip_ok and customer.patience > tip_patience_threshold \
		and customer.regular_name.is_empty() else 0
	GameState.add_money(price + tip)
	_float_text(customer.position, "+%dk" % (price + tip) + (" (tip)" if tip > 0 else ""))
	tables.make_dirty(customer.seat)
	customer_served.emit(price, tip)


## Leaves before everything came: lines still waiting are dropped; what was
## eaten is paid for (no tip).
func _send_away(customer: Customer, angry: bool) -> void:
	if customer.state == Customer.State.LEAVING:
		return
	for order in customer.orders:
		waiting.erase(order)
	customer.orders.clear()
	customer.eaten.append_array(customer.queued)
	if customer.plate:
		customer.eaten.append(customer.plate)
	if angry:
		_float_text(customer.position, "Bỏ đi!")
		customer_left_angry.emit()
	_pay(customer, false)
	_leave(customer)


## Walks back to the bike (which rides off) or off the pavement.
func _leave(customer: Customer) -> void:
	var exit := customer.bike.parking if customer.bike else _entrance()
	var guest := customer.companion
	if guest:
		guest.leave(room.grid.path(room.grid.to_cell(guest.position), exit))
	await customer.leave(room.grid.path(room.grid.to_cell(customer.position), exit))
	while guest and guest.is_walking():
		await get_tree().process_frame
	_customers.erase(customer)
	if customer.bike:
		bikes.depart(customer.bike)
	if guest:
		guest.queue_free()
	customer.queue_free()


func _entrance() -> Vector2i:
	var doors := room.grid.cells_of("D")
	return doors[_rng.randi() % doors.size()]


func _by_decor(table: Array[float]) -> float:
	if table.is_empty():
		return 1.0
	return table[clampi(_decor_level, 0, table.size() - 1)]


func _float_text(at: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 30
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = at + Vector2(-10, -50)
	people_layer.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 20, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(label.queue_free)
