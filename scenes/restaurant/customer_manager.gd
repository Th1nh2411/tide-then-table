class_name CustomerManager
extends Node
## Runs the street restaurant during a shift (Dave the Diver style service):
## customers ride in on motorbikes (CustomerBikes; some walk in along the
## pavement) to free tables; after reading the menu each orders a dish that
## can still be served (menu portions + plates on the plate table, minus
## orders already waiting); Bảo cooks (ChefBao) and Rin grills / pours
## (KitchenStation); plates go on the plate table, and Rin — the waiter —
## carries them out and cleans the tables. Customers eat, pay (+ tip if they didn't wait long), walk back to
## their bike (or off the pavement) and leave a dirty table.
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
## Chance a customer orders a side (rau muống, beer) while seafood is left.
@export var side_order_chance: float = 0.25
## Patience multiplier while the restaurant cat is around ("mèo chiêu tài").
@export var cat_patience_scale: float = 1.1
@export var pass_capacity: int = 5

## The plate table (cooked dishes waiting to be carried out).
var shelf: DishShelf
## Customers who ordered and wait for food, in order of ordering.
var waiting: Array[Customer] = []
## Regular visits for today: [{"order", "item", "dish", "cooked"?}].
var regular_visits: Array[Dictionary] = []
## Table states (StreetRoom.dining).
var tables: DiningTables

var _customers: Array[Customer] = []
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
	for customer in waiting:
		if customer.seat == seat and customer.dish == plate.dish and customer.visit == plate.visit:
			waiting.erase(customer)
			_give_plate(customer, plate)
			return true
	return false


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


func _give_plate(customer: Customer, plate: DishShelf.Plate) -> void:
	customer.serve(plate)
	tables.put_plate(customer.seat, plate)


## `visit` = a regular's visit, or {} for a walk-in customer.
func _spawn(visit: Dictionary) -> void:
	var free := tables.free_seats()
	var customer := Customer.new()
	customer.seat = free[_rng.randi() % free.size()]
	if visit.is_empty():
		customer.rich = _rng.randf() < _by_decor(rich_chance_by_decor)
		if customer.rich:
			customer.patience_seconds *= rich_patience_scale
	else:
		customer.visit = visit
		customer.dish = visit["dish"]
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
		customer.bike = bikes.arrive()
	if customer.bike == null:
		_walk_in(customer, _entrance())


func _walk_in(customer: Customer, from: Vector2i) -> void:
	customer.position = room.grid.to_world(from)
	people_layer.add_child(customer)
	customer.go_to_seat(room.grid.path(from, room.tables[customer.seat]["chair"]))


func _on_bike_parked(bike: CustomerBikes.Bike) -> void:
	for customer in _customers:
		if customer.bike == bike:
			_walk_in(customer, bike.parking)


func _on_ordered(customer: Customer) -> void:
	if customer.dish == null:
		customer.dish = _pick_order()
	if customer.dish == null:
		_send_away(customer, false)
		return
	waiting.append(customer)


## A seafood dish that can still be served, or a side dish (sometimes by
## choice, always once the seafood is gone; always orderable: Rin buys its
## produce at the stall). Null only if there is nothing at all.
func _pick_order() -> DishData:
	var dishes: Array[DishData] = []
	for dish in _plan.get_dishes():
		if _servable(dish) > 0:
			dishes.append(dish)
	var wants_side := dishes.is_empty() or _rng.randf() < side_order_chance
	if wants_side and not _sides.is_empty():
		return _sides[_rng.randi() % _sides.size()]
	if dishes.is_empty():
		return null
	return dishes[_rng.randi() % dishes.size()]


## Portions not yet promised to a waiting customer.
func _servable(dish: DishData) -> int:
	var promised := waiting.filter(func(c: Customer) -> bool: return c.dish == dish and c.visit.is_empty()).size()
	return _plan.get_portion_count(dish) + shelf.count(dish) - promised


func _anything_to_order() -> bool:
	return not _sides.is_empty() or _plan.get_dishes().any(func(d: DishData) -> bool: return _servable(d) > 0)


func _on_finished_eating(customer: Customer) -> void:
	if customer.state != Customer.State.EATING:
		return
	var plate := customer.plate
	var price := 0
	var tip := 0
	if customer.regular_name:
		price = roundi(int(customer.visit["order"]["reward"]) * plate.cook_multiplier)
		FishOrders.complete(customer.visit["order"])
		regular_served.emit(customer.regular_name, price)
	else:
		price = roundi(KitchenLogic.calc_price(plate.dish, plate.cook_multiplier, plate.ingredients)
			* _variety_multiplier * (rich_price_scale if customer.rich else 1.0))
		tip = roundi(price * tip_ratio) if customer.patience > tip_patience_threshold else 0
	GameState.add_money(price + tip)
	_float_text(customer.position, "+%dk" % (price + tip) + (" (tip)" if tip > 0 else ""))
	tables.make_dirty(customer.seat)
	_leave(customer)
	customer_served.emit(price, tip)


## Leaves without eating: the order is dropped, the table stays clean.
func _send_away(customer: Customer, angry: bool) -> void:
	if customer.state == Customer.State.LEAVING:
		return
	waiting.erase(customer)
	tables.release(customer.seat)
	if angry:
		_float_text(customer.position, "Bỏ đi!")
		customer_left_angry.emit()
	_leave(customer)


## Walks back to the bike (which rides off) or off the pavement.
func _leave(customer: Customer) -> void:
	var exit := customer.bike.parking if customer.bike else _entrance()
	await customer.leave(room.grid.path(room.grid.to_cell(customer.position), exit))
	_customers.erase(customer)
	if customer.bike:
		bikes.depart(customer.bike)
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
