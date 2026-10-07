class_name Customer
extends Control
## A customer: walks in to a table, reads the menu for a moment, orders
## (bubble + patience bar), waits until a waiter brings the dish, eats for a
## few seconds, then pays and leaves (CustomerManager handles money and the
## dirty table). Runs out of patience while waiting = leaves angry.
## Special kinds: a regular coming for their fish order (name tag, gold
## bubble, more patient) and a well-off customer (gold shirt, pays more).
## Placeholder drawing only.

signal ordered(customer: Customer)
signal patience_ran_out(customer: Customer)
signal finished_eating(customer: Customer)

enum State { WALKING_IN, READING, WAITING, EATING, LEAVING }

## Seconds from full patience to leaving (only while WAITING).
@export var patience_seconds: float = 45.0
@export var walk_seconds: float = 1.5
## Reading the menu before ordering (random in range).
@export var read_seconds: Vector2 = Vector2(1.5, 3.0)
@export var eat_seconds: Vector2 = Vector2(4.0, 6.0)
@export var body_size: Vector2 = Vector2(18, 34)
@export var bubble_size: Vector2 = Vector2(96, 22)

## Ordered dish (chosen by the manager when the customer orders).
var dish: DishData
## Set for a regular eating their order (the FishOrders visit); {} otherwise.
var visit: Dictionary = {}
var regular_name: String = ""
## Well-off customer (decor upgrade): pays more, less patient.
var rich: bool = false
## Table index.
var seat: int = -1
## 1.0 = full patience, 0.0 = leaving.
var patience: float = 1.0
## The dish being eaten (set when served).
var plate: DishShelf.Plate
var state: State = State.WALKING_IN

var _timer: float = 0.0
var _shirt_color: Color


func _ready() -> void:
	size = body_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shirt_color = Color.from_hsv(randf(), 0.5, 0.85)
	if rich:
		_shirt_color = Color(0.95, 0.8, 0.3)
	elif regular_name:
		_shirt_color = Color(0.3, 0.5, 0.45)


func walk_to(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, walk_seconds)
	await tween.finished
	if state == State.WALKING_IN:
		state = State.READING
		_timer = randf_range(read_seconds.x, read_seconds.y)


## The dish arrives at the table.
func serve(p_plate: DishShelf.Plate) -> void:
	plate = p_plate
	state = State.EATING
	_timer = randf_range(eat_seconds.x, eat_seconds.y)


func is_waiting() -> bool:
	return state == State.WAITING


## Walk to the door and disappear.
func leave(door_position: Vector2) -> void:
	state = State.LEAVING
	var tween := create_tween()
	tween.tween_property(self, "position", door_position, walk_seconds)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	queue_redraw()
	match state:
		State.READING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.WAITING
				ordered.emit(self)
		State.WAITING:
			patience = maxf(patience - delta / patience_seconds, 0.0)
			if patience <= 0.0:
				patience_ran_out.emit(self)
		State.EATING:
			_timer -= delta
			if _timer <= 0.0:
				finished_eating.emit(self)


func _draw() -> void:
	draw_rect(Rect2(Vector2(0, 12), Vector2(body_size.x, body_size.y - 12)), _shirt_color)
	draw_circle(Vector2(body_size.x * 0.5, 6), 6, Color(0.95, 0.8, 0.65))
	if rich:
		draw_rect(Rect2(Vector2(body_size.x * 0.5 - 1, 14), Vector2(2, 8)), Color(0.6, 0.15, 0.15))  # tie
	match state:
		State.READING:
			_draw_thinking()
		State.WAITING:
			_draw_order_bubble()
		State.EATING:
			# Chopsticks going up and down.
			var lift := absf(sin(_timer * 6.0)) * 4.0
			draw_line(Vector2(body_size.x + 2, 16 - lift), Vector2(body_size.x + 10, 22 - lift), Color(0.6, 0.45, 0.3), 1.0)


func _draw_thinking() -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2(body_size.x * 0.5 - 12, -18)
	draw_rect(Rect2(origin, Vector2(24, 12)), Color(1, 1, 1, 0.85))
	var dots := ".".repeat(1 + int(_timer * 3.0) % 3)
	draw_string(font, origin + Vector2(4, 9), dots, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.2, 0.2, 0.2))


func _draw_order_bubble() -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2((body_size.x - bubble_size.x) * 0.5, -bubble_size.y - 10)
	var bubble_color := Color(1.0, 0.88, 0.5, 0.95) if regular_name else Color(1, 1, 1, 0.92)
	draw_rect(Rect2(origin, bubble_size), bubble_color)
	draw_rect(Rect2(origin + Vector2(3, 3), Vector2(8, 8)), dish.color)
	var text_color := Color(0.15, 0.1, 0.1)
	draw_string(font, origin + Vector2(14, 10), dish.display_name, HORIZONTAL_ALIGNMENT_LEFT,
		bubble_size.x - 16, 8, text_color)
	draw_string(font, origin + Vector2(14, 19), "Bàn %d" % (seat + 1), HORIZONTAL_ALIGNMENT_LEFT,
		bubble_size.x - 16, 7, text_color)
	if regular_name:
		draw_string(font, origin + Vector2(0, -3), "%s (đặt trước)" % regular_name, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 8, Color(1.0, 0.9, 0.55))
	# Patience bar under the bubble: green -> red.
	var bar := Rect2(origin + Vector2(0, bubble_size.y + 2), Vector2(bubble_size.x, 3))
	draw_rect(bar, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * patience, bar.size.y)),
		Color(1, 0.3, 0.3).lerp(Color(0.3, 0.9, 0.4), patience))
