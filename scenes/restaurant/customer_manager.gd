class_name CustomerManager
extends Node
## Runs the street restaurant during a shift (Dave the Diver style): parties
## of 1-2 come by motorbike or on foot to free tables and order (TableOrder
## lines in `waiting`); Bảo cooks (ChefBao), Rin grills / pours
## (KitchenStation) and carries the plates out; they eat plate by plate, may
## order another round, then pay for everything (+ tip if still patient) and
## leave a dirty table. Day 1 is simple; more comes in over the first days
## (`stages`). Upgrades: seats (tables), decor (more often + well-off).
## Helpers: PartyFactory (who comes, when), PartyOrders + OrderPicker (what
## they order), PartyCheckout + TableBill (what they pay), PartyWalker (in and out).

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
## Decor upgrade: its value (0, 1, 2...) indexes the tuning's decor arrays.
@export var decor_upgrade: UpgradeData
## Spawning, party / order chances, patience bonuses, tips: one
## ServiceTuning per stage of the game, the last one whose `from_day` has
## come is used (day 1 simple, more going on later).
@export var stages: Array[ServiceTuning] = []
@export var pass_capacity: int = 5

## Today's stage of `stages`.
var tuning: ServiceTuning
## The plate table (cooked dishes waiting to be carried out).
var shelf: DishShelf
## Plates staff are carrying out (StaffCrew), so the kitchen doesn't cook twice.
var in_hands: Array[DishShelf.Plate] = []
## Extra tip share from the staff working today.
var tip_bonus: float = 0.0
## Ordered dishes still to bring, in order of ordering.
var waiting: Array[TableOrder] = []
## Regular visits for today: [{"order", "item", "dish", "cooked"?}].
var regular_visits: Array[Dictionary] = []
## Table states (StreetRoom.dining).
var tables: DiningTables

var _customers: Array[Customer] = []  # party leaders
var _decor_level: int = 0
var _factory: PartyFactory
var _picker: OrderPicker
var _orders: PartyOrders
var _walker: PartyWalker
var _variety_multiplier: float = 1.0
var _accepting: bool = false


func _ready() -> void:
	shelf = DishShelf.new(pass_capacity)
	room.shelf = shelf
	_factory = PartyFactory.new()
	refresh_upgrades()
	tuning = stage_for(stages, GameState.day)
	_factory.tuning = tuning
	_picker = OrderPicker.new(shelf)
	_orders = PartyOrders.new(_picker, waiting)
	_walker = PartyWalker.new(room, bikes, people_layer)


## The last stage whose `from_day` has come (stages sorted by day).
static func stage_for(list: Array[ServiceTuning], day: int) -> ServiceTuning:
	var result: ServiceTuning = list[0] if not list.is_empty() else ServiceTuning.new()
	for stage in list:
		if stage.from_day <= day:
			result = stage
	return result


func decor_level() -> int:
	return _decor_level


## Reads the seats and decor levels (also after renovating, nobody inside).
func refresh_upgrades() -> void:
	room.setup_tables(int(GameState.get_upgrade_value(seats_upgrade)) if seats_upgrade else 4)
	tables = room.dining
	_decor_level = int(GameState.get_upgrade_value(decor_upgrade)) if decor_upgrade else 0
	room.decor_level = _decor_level
	_factory.decor_level = _decor_level


## `visits` from FishOrders.reserve_for_shift() (fish already set aside).
func start_shift(plan: MenuPlan, variety_multiplier: float = 1.0, visits: Array[Dictionary] = []) -> void:
	_picker.plan = plan
	_picker.sides.assign(menu.dishes.filter(func(d: DishData) -> bool: return d.on_menu_today()))
	_variety_multiplier = variety_multiplier
	regular_visits = visits
	_factory.start(visits)
	_accepting = true


## No new customers; those already here are still served and eat (or run
## out of patience) before the shop really closes.
func stop_shift() -> void:
	_accepting = false
	_factory.stop()


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
			(order.party as Customer).serve(order, plate)
			tables.put_plate(seat, plate)
			return true
	return false


## Free plates of `dish` on the way (plate table + staff hands).
func plates_ready(dish: DishData) -> int:
	return shelf.count(dish) + in_hands.filter(func(p: DishShelf.Plate) -> bool:
		return p.dish == dish and p.visit.is_empty()).size()


## Party leaders with lines still waiting, oldest line first.
func waiting_parties() -> Array[Customer]:
	var result: Array[Customer] = []
	for order in waiting:
		var leader := order.party as Customer
		if leader not in result:
			result.append(leader)
	return result


func _process(delta: float) -> void:
	if not _accepting:
		return
	var regular := _factory.regular_due(delta, tables.free_seat() != -1)
	if not regular.is_empty():
		_spawn(regular)
	if _factory.walk_in_due(delta) and tables.free_seat() != -1 and _picker.anything_to_order(waiting):
		_spawn({})


## `visit` = a regular's visit, or {} for a walk-in customer.
func _spawn(visit: Dictionary) -> void:
	var customer := _factory.create(visit, tables.free_seats())
	if not visit.is_empty():
		message_requested.emit("%s tới ăn món đã đặt!" % customer.regular_name)
	customer.ordered.connect(_on_ordered)
	customer.patience_ran_out.connect(_send_away.bind(true))
	customer.finished_eating.connect(_on_finished_eating)
	tables.take(customer.seat)
	_customers.append(customer)
	_walker.arrive(customer, tuning.walk_in_chance)


func _on_ordered(customer: Customer) -> void:
	if not _orders.take_first(customer, tuning):
		_send_away(customer, false)


func _on_finished_eating(customer: Customer) -> void:
	if customer.state != Customer.State.DINING:
		return
	if _accepting and _orders.take_another_round(customer, tuning):
		FloatingText.spawn(people_layer, customer.position, "Thêm món!")
		return
	_pay(customer, true)
	_leave(customer)


## Pays for every plate eaten (tip only if `tip_ok` and still patient);
## leaves the table dirty, or free if nothing was eaten.
func _pay(customer: Customer, tip_ok: bool) -> void:
	if customer.eaten.is_empty():
		tables.release(customer.seat)
		return
	var bill := PartyCheckout.bill(customer, _variety_multiplier, tuning, tip_ok, tip_bonus)
	for price in PartyCheckout.complete_regular_orders(customer):
		regular_served.emit(customer.regular_name, price)
	GameState.add_money(bill.x + bill.y)
	FloatingText.spawn(people_layer, customer.position, "+%dk" % (bill.x + bill.y) + (" (tip)" if bill.y > 0 else ""))
	tables.make_dirty(customer.seat)
	customer_served.emit(bill.x, bill.y)


## Leaves before everything came: lines still waiting are dropped; what was
## eaten is paid for (no tip).
func _send_away(customer: Customer, angry: bool) -> void:
	if customer.state == Customer.State.LEAVING:
		return
	PartyCheckout.drop_unserved(customer, waiting)
	if angry:
		FloatingText.spawn(people_layer, customer.position, "Bỏ đi!")
		customer_left_angry.emit()
	_pay(customer, false)
	_leave(customer)


func _leave(customer: Customer) -> void:
	await _walker.walk_out(customer)
	_customers.erase(customer)
