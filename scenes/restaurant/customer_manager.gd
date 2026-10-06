class_name CustomerManager
extends Node
## Runs the customers during a shift: spawns them at random intervals into
## free seats, has them order from today's MenuPlan (taking one portion),
## starts cooking when one is clicked, and pays out when the dish is done.
## Customers only come while the menu still has portions left.

signal customer_served(price: int, tip: int)
signal customer_left_angry
## Always emitted when a cooking attempt ends (even if the customer is gone).
signal cooking_ended
signal message_requested(text: String)

@export var customer_scene: PackedScene
@export var cooking: CookingOverlay
## Parent node for customer nodes (and floating money text).
@export var customer_layer: Control
## Where a seated customer stands (top-left of the customer), one per table.
@export var seat_positions: Array[Vector2] = []
@export var door_position: Vector2 = Vector2(605, 226)
@export var first_spawn_delay: float = 1.5
@export var min_spawn_interval: float = 5.0
@export var max_spawn_interval: float = 10.0
## Tip = price × tip_ratio, only if served with patience above the threshold.
@export var tip_ratio: float = 0.2
@export var tip_patience_threshold: float = 0.5

var _seats: Array[Customer] = []
var _plan: MenuPlan
var _accepting: bool = false
var _spawn_left: float = 0.0
var _cooking_customer: Customer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_seats.resize(seat_positions.size())
	cooking.finished.connect(_on_cooking_finished)


func start_shift(plan: MenuPlan) -> void:
	_plan = plan
	_accepting = true
	_spawn_left = first_spawn_delay


## Stop spawning and send waiting customers home (not counted as angry).
## The customer currently being cooked for still gets served.
func stop_shift() -> void:
	_accepting = false
	for customer in _seats:
		if customer and customer != _cooking_customer:
			_send_away(customer, false)


func is_cooking() -> bool:
	return _cooking_customer != null


## No one seated (or walking in) and nothing on the stove.
func is_idle() -> bool:
	return not is_cooking() and _seats.all(func(c: Customer) -> bool: return c == null)


func _process(delta: float) -> void:
	if not _accepting:
		return
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_left = _rng.randf_range(min_spawn_interval, max_spawn_interval)
		_try_spawn()


func _try_spawn() -> void:
	var seat := _seats.find(null)
	var dishes := _plan.available_dishes()
	if seat == -1 or dishes.is_empty():
		return
	var customer: Customer = customer_scene.instantiate()
	customer.dish = dishes[_rng.randi() % dishes.size()]
	customer.ingredients = _plan.take_portion(customer.dish)
	customer.position = door_position
	customer.clicked.connect(_on_customer_clicked)
	customer.patience_ran_out.connect(_send_away.bind(true))
	_seats[seat] = customer
	customer_layer.add_child(customer)
	customer.walk_to(seat_positions[seat])


func _on_customer_clicked(customer: Customer) -> void:
	if is_cooking():
		message_requested.emit("Đang nấu món khác")
		return
	if not customer.can_be_served():
		message_requested.emit("Kho không đủ nguyên liệu cho %s" % customer.dish.display_name)
		return
	_cooking_customer = customer
	customer.set_cooking(true)
	cooking.start(customer.dish)


func _on_cooking_finished(dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	var customer := _cooking_customer
	_cooking_customer = null
	if is_instance_valid(customer):
		var price := KitchenLogic.calc_price(dish, multiplier, customer.ingredients)
		var tip := roundi(price * tip_ratio) if customer.patience > tip_patience_threshold else 0
		customer.ingredients.clear()  # eaten
		GameState.add_money(price + tip)
		_float_text(customer.position, "+%dk" % (price + tip) + (" (tip)" if tip > 0 else ""))
		_free_seat(customer)
		customer.leave(door_position)
		customer_served.emit(price, tip)
	cooking_ended.emit()


## Customer leaves without being served; their portion goes back on the menu.
func _send_away(customer: Customer, angry: bool) -> void:
	if customer.state == Customer.State.LEAVING:
		return
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
