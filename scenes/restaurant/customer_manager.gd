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
## Day 1 is simple (one guest, one dish, fewer customers, no beer yet);
## parties, extra dishes and extra rounds come in over the first days
## (`stages`). Upgrades: seats (tables), decor (more often + well-off customers).
## Regulars with a fish order (FishOrders) come early in the shift.
## Helpers: OrderPicker (what they order), TableBill (what they pay),
## PartyWalker (walking in and out), FloatingText.

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
var _regulars_to_spawn: Array[Dictionary] = []
var _shift_time: float = 0.0
var _decor_level: int = 0
var _picker: OrderPicker
var _walker: PartyWalker
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
	tuning = stage_for(stages, GameState.day)
	_picker = OrderPicker.new(shelf)
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


## `visits` from FishOrders.reserve_for_shift() (fish already set aside).
func start_shift(plan: MenuPlan, variety_multiplier: float = 1.0, visits: Array[Dictionary] = []) -> void:
	_picker.plan = plan
	_picker.sides.assign(menu.dishes.filter(func(d: DishData) -> bool: return d.on_menu_today()))
	_variety_multiplier = variety_multiplier
	_interval_scale = tuning.interval_scale_by_rating[clampi(GameState.last_rating, 0, tuning.interval_scale_by_rating.size() - 1)]
	_interval_scale *= _by_decor(tuning.decor_interval_scale)
	regular_visits = visits
	_regulars_to_spawn = visits.duplicate()
	_shift_time = 0.0
	_accepting = true
	_spawn_left = tuning.first_spawn_delay


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


## Free plates of `dish` on the way (plate table + staff hands).
func plates_ready(dish: DishData) -> int:
	return shelf.count(dish) + in_hands.filter(func(p: DishShelf.Plate) -> bool:
		return p.dish == dish and p.visit.is_empty()).size()


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
	if not _regulars_to_spawn.is_empty() and _shift_time >= tuning.regular_delay and tables.free_seat() != -1:
		_spawn(_regulars_to_spawn.pop_front())
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = _rng.randf_range(tuning.min_spawn_interval, tuning.max_spawn_interval) * _interval_scale
		if tables.free_seat() != -1 and _picker.anything_to_order(waiting):
			_spawn({})


## `visit` = a regular's visit, or {} for a walk-in customer.
func _spawn(visit: Dictionary) -> void:
	var free := tables.free_seats()
	var customer := Customer.new()
	customer.seat = free[_rng.randi() % free.size()]
	if visit.is_empty():
		customer.rich = _rng.randf() < _by_decor(tuning.rich_chance_by_decor)
		if customer.rich:
			customer.patience_seconds *= tuning.rich_patience_scale
		if _rng.randf() < tuning.pair_chance:
			customer.companion = Customer.new()
			customer.companion.leader = customer
			customer.companion.seat = customer.seat
		customer.more_rounds = tuning.max_more_rounds
	else:
		customer.visit = visit
		customer.regular_name = visit["order"]["who"]
		customer.patience_seconds *= tuning.regular_patience_scale
		message_requested.emit("%s tới ăn món đã đặt!" % customer.regular_name)
	if PetCat.is_present():
		customer.patience_seconds *= tuning.cat_patience_scale
	customer.ordered.connect(_on_ordered)
	customer.patience_ran_out.connect(_send_away.bind(true))
	customer.finished_eating.connect(_on_finished_eating)
	tables.take(customer.seat)
	_customers.append(customer)
	if _rng.randf() >= tuning.walk_in_chance:
		customer.bike = bikes.arrive(customer.companion != null)
	if customer.bike == null:
		_walker.walk_in(customer, _walker.entrance())


func _on_bike_parked(bike: CustomerBikes.Bike) -> void:
	for customer in _customers:
		if customer.bike == bike:
			_walker.walk_in(customer, bike.parking)


func _on_ordered(customer: Customer) -> void:
	if not customer.visit.is_empty():
		_add_line(customer, customer.visit["dish"], customer.visit)
		return
	for i in _picker.first_order_size(2 if customer.companion else 1, tuning.extra_dish_chance, tuning.max_lines):
		var dish := _picker.pick(tuning.side_order_chance, waiting)
		if dish:
			_add_line(customer, dish)
	if customer.orders.is_empty():
		_send_away(customer, false)


func _add_line(customer: Customer, dish: DishData, visit: Dictionary = {}) -> void:
	var order := TableOrder.new(dish, visit, customer)
	customer.add_order(order)
	waiting.append(order)


func _on_finished_eating(customer: Customer) -> void:
	if customer.state != Customer.State.DINING:
		return
	if customer.more_rounds > 0 and _accepting and _rng.randf() < tuning.more_round_chance:
		customer.more_rounds -= 1
		var dish := _picker.pick(tuning.round_side_chance, waiting)
		if dish:
			_add_line(customer, dish)
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
	var price := TableBill.total(customer.eaten, _variety_multiplier, tuning.rich_price_scale if customer.rich else 1.0)
	for plate in customer.eaten:
		if not plate.visit.is_empty():
			FishOrders.complete(plate.visit["order"])
			regular_served.emit(customer.regular_name, TableBill.plate_price(plate, 1.0, 1.0))
	var tip := 0
	if tip_ok and customer.regular_name.is_empty():
		tip = TableBill.tip(price, customer.patience, tuning.tip_patience_threshold, tuning.tip_ratio + tip_bonus)
	GameState.add_money(price + tip)
	FloatingText.spawn(people_layer, customer.position, "+%dk" % (price + tip) + (" (tip)" if tip > 0 else ""))
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
		FloatingText.spawn(people_layer, customer.position, "Bỏ đi!")
		customer_left_angry.emit()
	_pay(customer, false)
	_leave(customer)


func _leave(customer: Customer) -> void:
	await _walker.walk_out(customer)
	_customers.erase(customer)


func _by_decor(table: Array[float]) -> float:
	if table.is_empty():
		return 1.0
	return table[clampi(_decor_level, 0, table.size() - 1)]
