class_name Waiter
extends Control
## Someone carrying dishes from the counter to the tables. Bảo (auto_serve)
## picks up whatever is ready (up to carry_capacity) and serves the nearest
## table first. Rin uses the same walk when helping out: `deliver()` one
## dish, walk it out, come back (the stove is unattended meanwhile).

signal served(customer: Customer)
## Back at home with empty hands.
signal returned_home

@export var kitchen: Kitchen
@export var display_name: String = "Bảo"
## True for Bảo: picks up ready dishes on its own.
@export var auto_serve: bool = true
@export var speed: float = 110.0
@export var carry_capacity: int = 2
@export var home_x: float = 168.0
@export var floor_y: float = 228.0
@export var x_range: Vector2 = Vector2(150.0, 585.0)
@export var body_color: Color = Color(0.85, 0.5, 0.2)
## False for Rin: drawn by the Kitchen while at the stove.
@export var visible_at_home: bool = true

## Customers whose dishes are being carried, in serving order.
var carried: Array[Customer] = []

var _x: float = 168.0
var _facing: float = 1.0
var _was_home: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_x = home_x


func is_home() -> bool:
	return carried.is_empty() and absf(_x - home_x) < 1.0


## Take this customer's dish off the counter and serve it (manual helper).
## False if hands are full or the dish isn't on the counter any more.
func deliver(customer: Customer) -> bool:
	if carried.size() >= carry_capacity or not kitchen.counter.has(customer):
		return false
	kitchen.counter.erase(customer)
	carried.append(customer)
	return true


## The customer left: their carried dish is thrown away.
func drop(customer: Customer) -> void:
	carried.erase(customer)


func _process(delta: float) -> void:
	queue_redraw()
	for i in range(carried.size() - 1, -1, -1):
		if not is_instance_valid(carried[i]):
			carried.remove_at(i)
	if carried.is_empty():
		if auto_serve and is_home() and not kitchen.counter.is_empty():
			carried = kitchen.take(carry_capacity)
			carried.sort_custom(func(a: Customer, b: Customer) -> bool: return a.position.x < b.position.x)
			return
		_walk_to(home_x, delta)
		var home := is_home()
		if home and not _was_home:
			returned_home.emit()
		_was_home = home
		return
	_was_home = false
	var customer := carried[0]
	var goal := clampf(customer.position.x - 10.0, x_range.x, x_range.y)
	_walk_to(goal, delta)
	if absf(goal - _x) < 1.0:
		carried.pop_front()
		served.emit(customer)


func _walk_to(goal: float, delta: float) -> void:
	var step := clampf(goal - _x, -speed * delta, speed * delta)
	if step != 0.0:
		_facing = signf(step)
	_x += step


func _draw() -> void:
	if not visible_at_home and is_home():
		return
	var at := Vector2(_x - 8, floor_y)
	draw_rect(Rect2(at + Vector2(0, 12), Vector2(16, 22)), body_color)
	draw_rect(Rect2(at + Vector2(2, 20), Vector2(12, 14)), Color(0.95, 0.9, 0.8))  # apron
	draw_circle(at + Vector2(8, 6), 6, Color(0.95, 0.8, 0.65))
	draw_circle(at + Vector2(8 + _facing * 3, 5), 1.0, Color.BLACK)
	for i in carried.size():
		var tray := at + Vector2(-2 + i * 10, -4 - i * 2)
		draw_rect(Rect2(tray, Vector2(10, 3)), Color.WHITE)
		draw_rect(Rect2(tray + Vector2(1, -4), Vector2(8, 4)), carried[i].dish.color)
	draw_string(ThemeDB.fallback_font, at + Vector2(-2, -12 - carried.size() * 2), display_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.8))
