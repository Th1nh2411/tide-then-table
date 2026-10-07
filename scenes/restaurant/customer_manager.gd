class_name CustomerManager
extends Node
## Runs the customers during a shift: spawns them at random intervals into
## free seats and has them order from today's MenuPlan (taking one portion).
## Service (Dave the Diver style): clicking a waiting customer makes Rin cook
## their dish (Kitchen); finished dishes wait on the counter until Bảo (Waiter,
## automatic) carries them out — or the player clicks the customer again to
## have Rin carry it (the stove is unattended meanwhile). Paid on arrival.
## Snacks (DishData.always_available) are sometimes ordered instead, and are
## all customers can order once the menu is sold out. Every price is scaled
## by the menu variety multiplier.
## Upgrades: seats (how many tables), decor (customers come more often and
## some are well-off, paying more). Regulars with a fish order (FishOrders)
## come early in the shift and pay the order's price for their dish.

signal customer_served(price: int, tip: int)
signal customer_left_angry
signal message_requested(text: String)
## A regular ate their order dish.
signal regular_served(who: String, price: int)

@export var customer_scene: PackedScene
## Full dish catalog; snacks are taken from here.
@export var menu: DishCatalog
@export var kitchen: Kitchen
## Bảo, carrying dishes on their own.
@export var waiter: Waiter
## Rin's walk when helping to serve.
@export var rin_helper: Waiter
## Parent node for customer nodes (and floating money text).
@export var customer_layer: Control
## Seats are spread evenly over this x range at seat_y (top-left of the customer).
@export var seat_x_range: Vector2 = Vector2(180.0, 520.0)
@export var seat_y: float = 228.0
## Seats upgrade: its value is the number of seats (default 4 without it).
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
@export var door_position: Vector2 = Vector2(605, 226)
@export var first_spawn_delay: float = 1.5
@export var min_spawn_interval: float = 5.0
@export var max_spawn_interval: float = 10.0
## Tip = price × tip_ratio, only if served with patience above the threshold.
@export var tip_ratio: float = 0.2
@export var tip_patience_threshold: float = 0.5
## Spawn interval multiplier by yesterday's rating (index = stars, 0 unused).
## Good reviews bring customers more often.
@export var interval_scale_by_rating: Array[float] = [1.0, 1.3, 1.15, 1.0, 0.85, 0.7]
## Chance a customer orders a snack while the menu still has dishes.
@export var snack_order_chance: float = 0.15

## Where each seated customer stands (built from the seats upgrade).
var seat_positions: Array[Vector2] = []
var _seats: Array[Customer] = []
## Regulars still to come: [{"order", "item", "dish"}].
var _regulars_waiting: Array[Dictionary] = []
## Regular visits that didn't end with a meal (fish goes back to storage).
var _regulars_unserved: Array[Dictionary] = []
var _shift_time: float = 0.0
var _decor_level: int = 0
var _plan: MenuPlan
var _snacks: Array[DishData] = []
## Price multiplier from menu variety (set at the start of the shift).
var _variety_multiplier: float = 1.0
var _interval_scale: float = 1.0
var _accepting: bool = false
var _spawn_left: float = 0.0
var _rng := RandomNumberGenerator.new()


## Evenly spread seat positions for `count` tables.
static func layout_seats(count: int, x_range: Vector2, y: float) -> Array[Vector2]:
	var seats: Array[Vector2] = []
	for i in count:
		var t := 0.5 if count <= 1 else float(i) / (count - 1)
		seats.append(Vector2(roundf(lerpf(x_range.x, x_range.y, t)), y))
	return seats


func _ready() -> void:
	_rng.randomize()
	var seat_count := int(GameState.get_upgrade_value(seats_upgrade)) if seats_upgrade else 4
	seat_positions = layout_seats(seat_count, seat_x_range, seat_y)
	_seats.resize(seat_positions.size())
	_decor_level = int(GameState.get_upgrade_value(decor_upgrade)) if decor_upgrade else 0
	waiter.served.connect(_on_served)
	rin_helper.served.connect(_on_served)
	rin_helper.returned_home.connect(func() -> void: kitchen.rin_away = false)
	for dish in menu.dishes:
		if dish.always_available:
			_snacks.append(dish)


## `regular_visits` from FishOrders.reserve_for_shift() (fish already set aside).
func start_shift(plan: MenuPlan, variety_multiplier: float = 1.0, regular_visits: Array[Dictionary] = []) -> void:
	_plan = plan
	_variety_multiplier = variety_multiplier
	_interval_scale = interval_scale_by_rating[clampi(GameState.last_rating, 0, interval_scale_by_rating.size() - 1)]
	_interval_scale *= _by_decor(decor_interval_scale)
	_regulars_waiting = regular_visits.duplicate()
	_shift_time = 0.0
	_accepting = true
	_spawn_left = first_spawn_delay


## Stop spawning and send customers whose dish isn't cooking yet home (not
## counted as angry). Dishes on the stove or the counter still get served.
func stop_shift() -> void:
	_accepting = false
	_regulars_unserved.append_array(_regulars_waiting)
	_regulars_waiting.clear()
	for customer in _seats:
		if customer and customer.state == Customer.State.WAITING:
			_send_away(customer, false)


## Everyone still seated leaves now (closing up after the grace time).
func clear_room() -> void:
	for customer in _seats:
		if customer:
			_send_away(customer, false)


## No one seated (or walking in).
func is_idle() -> bool:
	return _seats.all(func(c: Customer) -> bool: return c == null)


## Regular visits that ended without a meal (call after the shift).
func unserved_regulars() -> Array[Dictionary]:
	return _regulars_unserved


func _process(delta: float) -> void:
	if not _accepting:
		return
	_shift_time += delta
	if not _regulars_waiting.is_empty() and _shift_time >= regular_delay and _seats.has(null):
		_spawn_regular(_regulars_waiting.pop_front())
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = _rng.randf_range(min_spawn_interval, max_spawn_interval) * _interval_scale
		_try_spawn()


func _try_spawn() -> void:
	var seat := _seats.find(null)
	var dish := _pick_order()
	if seat == -1 or dish == null:
		return
	var customer: Customer = customer_scene.instantiate()
	customer.dish = dish
	if not dish.always_available:
		customer.ingredients = _plan.take_portion(dish)
	customer.rich = _rng.randf() < _by_decor(rich_chance_by_decor)
	if customer.rich:
		customer.patience_seconds *= rich_patience_scale
	_seat_customer(customer, seat)


func _spawn_regular(visit: Dictionary) -> void:
	var customer: Customer = customer_scene.instantiate()
	customer.dish = visit["dish"]
	customer.ingredients.append(visit["item"])
	customer.order = visit
	customer.regular_name = visit["order"]["who"]
	customer.patience_seconds *= regular_patience_scale
	_seat_customer(customer, _seats.find(null))
	message_requested.emit("%s tới ăn món đã đặt!" % customer.regular_name)


func _seat_customer(customer: Customer, seat: int) -> void:
	customer.position = door_position
	customer.clicked.connect(_on_customer_clicked)
	customer.patience_ran_out.connect(_send_away.bind(true))
	_seats[seat] = customer
	customer_layer.add_child(customer)
	customer.walk_to(seat_positions[seat])


func _by_decor(table: Array[float]) -> float:
	if table.is_empty():
		return 1.0
	return table[clampi(_decor_level, 0, table.size() - 1)]


## A menu dish with portions left, or a snack (sometimes by choice, always
## once the menu is sold out). Null only if there is nothing at all.
func _pick_order() -> DishData:
	var dishes := _plan.available_dishes()
	var wants_snack := dishes.is_empty() or _rng.randf() < snack_order_chance
	if wants_snack and not _snacks.is_empty():
		return _snacks[_rng.randi() % _snacks.size()]
	if dishes.is_empty():
		return null
	return dishes[_rng.randi() % dishes.size()]


## Waiting customer: Rin cooks. Dish on the counter: Rin carries it out.
func _on_customer_clicked(customer: Customer) -> void:
	match customer.state:
		Customer.State.WAITING:
			if kitchen.rin_away:
				message_requested.emit("Rin đang đi bưng món")
			elif kitchen.is_cooking():
				message_requested.emit("Đang nấu món khác")
			elif kitchen.is_counter_full():
				message_requested.emit("Quầy đầy, chờ bưng bớt ra")
			else:
				kitchen.cook(customer)
		Customer.State.READY:
			if kitchen.is_cooking():
				message_requested.emit("Đang nấu, không rời bếp được")
			elif rin_helper.deliver(customer):
				kitchen.rin_away = true
			else:
				message_requested.emit("Bảo đang bưng món này rồi")


func _on_served(customer: Customer) -> void:
	if is_instance_valid(customer) and customer.state == Customer.State.READY:
		_serve(customer, customer.cook_multiplier)


func _serve(customer: Customer, cook_multiplier: float) -> void:
	if customer.regular_name:
		_serve_regular(customer, cook_multiplier)
		return
	var price := roundi(KitchenLogic.calc_price(customer.dish, cook_multiplier, customer.ingredients)
		* _variety_multiplier * (rich_price_scale if customer.rich else 1.0))
	var tip := roundi(price * tip_ratio) if customer.patience > tip_patience_threshold else 0
	customer.ingredients.clear()  # eaten
	GameState.add_money(price + tip)
	_float_text(customer.position, "+%dk" % (price + tip) + (" (tip)" if tip > 0 else ""))
	_free_seat(customer)
	customer.leave(door_position)
	customer_served.emit(price, tip)


## The order's price, scaled by how well it was cooked.
func _serve_regular(customer: Customer, cook_multiplier: float) -> void:
	var order: Dictionary = customer.order["order"]
	var price := roundi(int(order["reward"]) * cook_multiplier)
	FishOrders.complete(order)
	customer.ingredients.clear()
	GameState.add_money(price)
	_float_text(customer.position, "+%dk (đơn %s)" % [price, customer.regular_name])
	_free_seat(customer)
	customer.leave(door_position)
	customer_served.emit(price, 0)
	regular_served.emit(customer.regular_name, price)


## Customer leaves without being served; their portion goes back on the menu
## (a regular's reserved fish goes back to storage after the shift).
func _send_away(customer: Customer, angry: bool) -> void:
	if customer.state == Customer.State.LEAVING:
		return
	kitchen.cancel(customer)
	waiter.drop(customer)
	rin_helper.drop(customer)
	var uncooked := customer.state == Customer.State.WAITING
	if customer.regular_name:
		if uncooked:  # once cooked, the reserved fish is gone
			_regulars_unserved.append(customer.order)
	elif not customer.dish.always_available and uncooked:
		_plan.return_portion(customer.dish, customer.ingredients)
	customer.ingredients.clear()
	_free_seat(customer)
	if angry:
		_float_text(customer.position, "Bỏ đi!")
		customer_left_angry.emit()
	customer.leave(door_position)


func _free_seat(customer: Customer) -> void:
	var seat := _seats.find(customer)
	if seat != -1:
		_seats[seat] = null


func _float_text(at: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = at + Vector2(-10, -50)
	customer_layer.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 20, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(label.queue_free)
