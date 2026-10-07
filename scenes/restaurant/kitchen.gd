class_name Kitchen
extends Control
## Rin's stove and the pass counter. Rin cooks a clicked customer's dish
## (cooking minigame; snacks are instant), and the finished dish waits on the
## counter until Bảo (Waiter) carries it out — Dave the Diver style service,
## with Rin as the cook. Draws Rin at the stove and the dishes on the counter.

signal dish_ready(customer: Customer)
## Emitted when a cooking attempt ends (even if the customer is gone).
signal cooking_ended

@export var cooking: CookingOverlay
## Dishes the counter can hold; no new cooking while it is full.
@export var counter_capacity: int = 4
@export var cook_position: Vector2 = Vector2(100, 176)
@export var counter_slot_start: Vector2 = Vector2(96, 200)
@export var cook_color: Color = Color(0.2, 0.45, 0.8)

## Dishes ready on the counter, oldest first (their customers).
var counter: Array[Customer] = []
## The customer Rin is cooking for (null when the stove is free).
var current: Customer
## Rin is out carrying a dish: nobody at the stove.
var rin_away: bool = false

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	cooking.finished.connect(_on_cooking_finished)


func is_cooking() -> bool:
	return current != null


## Rin can start a new dish now.
func can_cook() -> bool:
	return current == null and not rin_away and not is_counter_full()


func is_counter_full() -> bool:
	return counter.size() >= counter_capacity


## Starts cooking for this customer (snacks go straight to the counter).
func cook(customer: Customer) -> void:
	if customer.dish.instant_serve:
		_to_counter(customer, 1.0)
		return
	current = customer
	customer.set_cooking(true)
	cooking.start(customer.dish)


## Takes up to `count` dishes off the counter, oldest first.
func take(count: int) -> Array[Customer]:
	var taken: Array[Customer] = []
	while taken.size() < count and not counter.is_empty():
		taken.append(counter.pop_front())
	return taken


## The customer left: their dish on the counter is thrown away.
func cancel(customer: Customer) -> void:
	counter.erase(customer)


func _on_cooking_finished(dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	var customer := current
	current = null
	if is_instance_valid(customer) and customer.dish == dish and customer.state == Customer.State.COOKING:
		_to_counter(customer, multiplier)
	cooking_ended.emit()


func _to_counter(customer: Customer, multiplier: float) -> void:
	customer.cook_multiplier = multiplier
	customer.set_ready()
	counter.append(customer)
	dish_ready.emit(customer)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_counter()
	if rin_away:
		return
	# Rin at the stove, bobbing while cooking.
	var bob := sin(_time * 8.0) * 1.0 if current else 0.0
	var at := cook_position + Vector2(0, bob)
	draw_rect(Rect2(at + Vector2(0, 12), Vector2(16, 22)), cook_color)
	draw_circle(at + Vector2(8, 6), 6, Color(0.95, 0.8, 0.65))
	draw_rect(Rect2(at + Vector2(2, -6), Vector2(12, 6)), Color.WHITE)  # chef hat
	var font := ThemeDB.fallback_font
	draw_string(font, at + Vector2(0, -10), "Rin", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.8))


func _draw_counter() -> void:
	var font := ThemeDB.fallback_font
	for i in counter.size():
		var slot := counter_slot_start + Vector2(i * 14 - 60, 0)
		draw_rect(Rect2(slot, Vector2(12, 6)), Color.WHITE)
		if is_instance_valid(counter[i]):
			draw_rect(Rect2(slot + Vector2(2, -4), Vector2(8, 4)), counter[i].dish.color)
	if is_counter_full():
		draw_string(font, counter_slot_start + Vector2(-60, -10), "Quầy đầy!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(1, 0.5, 0.4))
