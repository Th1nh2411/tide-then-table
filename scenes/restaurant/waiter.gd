class_name Waiter
extends Control
## Bảo, the waiter. Waits by the kitchen shelf; CustomerManager hands out
## jobs: carry a plate to a table, or clean a dirty table. Walks along the
## floor, does the job, walks back to the shelf.

signal delivered(customer: Customer, plate: DishShelf.Plate)
signal cleaned(seat: int)

enum Job { NONE, CARRY, CLEAN, RETURN }

@export var display_name: String = "Bảo"
@export var speed: float = 100.0
@export var shelf_x: float = 172.0
@export var floor_y: float = 228.0
@export var clean_seconds: float = 1.2
@export var body_color: Color = Color(0.85, 0.5, 0.2)

var job: Job = Job.NONE

var _x: float = 172.0
var _goal_x: float = 172.0
var _customer: Customer
var _plate: DishShelf.Plate
var _seat: int = -1
var _timer: float = 0.0
var _facing: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_x = shelf_x


## Free and standing at the shelf.
func is_idle() -> bool:
	return job == Job.NONE


func deliver(customer: Customer, plate: DishShelf.Plate, table_x: float) -> void:
	_customer = customer
	_plate = plate
	_goal_x = table_x
	job = Job.CARRY


func clean(seat: int, table_x: float) -> void:
	_seat = seat
	_goal_x = table_x
	_timer = clean_seconds
	job = Job.CLEAN


func _process(delta: float) -> void:
	queue_redraw()
	if job == Job.NONE:
		return
	if job == Job.RETURN:
		_goal_x = shelf_x
	var step := clampf(_goal_x - _x, -speed * delta, speed * delta)
	if step != 0.0:
		_facing = signf(step)
	_x += step
	if absf(_goal_x - _x) > 0.5:
		return
	match job:
		Job.CARRY:
			var customer := _customer
			var plate := _plate
			_customer = null
			_plate = null
			job = Job.RETURN
			delivered.emit(customer, plate)
		Job.CLEAN:
			_timer -= delta
			if _timer <= 0.0:
				job = Job.RETURN
				cleaned.emit(_seat)
		Job.RETURN:
			job = Job.NONE


func _draw() -> void:
	var at := Vector2(_x - 8, floor_y)
	draw_rect(Rect2(at + Vector2(0, 12), Vector2(16, 22)), body_color)
	draw_rect(Rect2(at + Vector2(2, 20), Vector2(12, 14)), Color(0.95, 0.9, 0.8))  # apron
	draw_circle(at + Vector2(8, 6), 6, Color(0.95, 0.8, 0.65))
	draw_circle(at + Vector2(8 + _facing * 3, 5), 1.0, Color.BLACK)
	if _plate:
		draw_rect(Rect2(at + Vector2(-2, -4), Vector2(12, 3)), Color.WHITE)
		draw_rect(Rect2(at + Vector2(0, -8), Vector2(8, 4)), _plate.dish.color)
	if job == Job.CLEAN and absf(_goal_x - _x) <= 0.5:
		draw_line(at + Vector2(16, 14), at + Vector2(22, 10 + sin(_timer * 20.0) * 3.0), Color(0.9, 0.9, 1.0), 2.0)
	draw_string(ThemeDB.fallback_font, at + Vector2(-2, -12), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(1, 1, 1, 0.8))
