class_name RinWalker
extends Control
## Rin on the restaurant floor (the player, Dave the Diver style): A/D walks,
## `interact` (E) acts on the spot — at the kitchen door it opens the kitchen
## view; at a table it serves the carried plate, or cleans a dirty table.
## Only active while the shop is open and the kitchen view is closed.

signal kitchen_requested
## E at a table while carrying a plate.
signal serve_requested(seat: int)
signal clean_requested(seat: int)
signal message_requested(text: String)

@export var tables: DiningTables
@export var speed: float = 140.0
## Kitchen door: E within `reach` of this x opens the kitchen.
@export var door_x: float = 150.0
@export var floor_y: float = 228.0
@export var reach: float = 18.0
@export var x_range: Vector2 = Vector2(140.0, 585.0)
@export var clean_seconds: float = 0.8
@export var body_color: Color = Color(0.2, 0.45, 0.8)

var active: bool = false
## Plate Rin is carrying out (null = empty hands).
var carried: DishShelf.Plate

var _x: float = 150.0
var _facing: float = 1.0
var _cleaning_left: float = 0.0
var _cleaning_seat: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_x = door_x


func is_at_door() -> bool:
	return absf(_x - door_x) <= reach


func _process(delta: float) -> void:
	queue_redraw()
	if _cleaning_left > 0.0:
		_cleaning_left -= delta
		if _cleaning_left <= 0.0:
			clean_requested.emit(_cleaning_seat)
		return
	if not active:
		return
	var axis := Input.get_axis("turn_left", "turn_right")
	if axis != 0.0:
		_facing = signf(axis)
		_x = clampf(_x + axis * speed * delta, x_range.x, x_range.y)


func _unhandled_input(event: InputEvent) -> void:
	if not active or _cleaning_left > 0.0 or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if is_at_door():
		kitchen_requested.emit()
		return
	var seat := _nearest_table()
	if seat == -1:
		message_requested.emit("Tới gần bàn hoặc cửa bếp rồi bấm E")
	elif carried:
		serve_requested.emit(seat)
	elif tables.states[seat] == DiningTables.State.DIRTY:
		_cleaning_seat = seat
		_cleaning_left = clean_seconds
	else:
		message_requested.emit("Vào bếp (cửa bên trái) lấy món trên kệ để bưng ra")


func _nearest_table() -> int:
	var best := -1
	for i in tables.seat_positions.size():
		if absf(tables.stand_x(i) - _x) <= reach and (best == -1
				or absf(tables.stand_x(i) - _x) < absf(tables.stand_x(best) - _x)):
			best = i
	return best


func _draw() -> void:
	var at := Vector2(_x - 8, floor_y)
	draw_rect(Rect2(at + Vector2(0, 12), Vector2(16, 22)), body_color)
	draw_circle(at + Vector2(8, 6), 6, Color(0.95, 0.8, 0.65))
	draw_rect(Rect2(at + Vector2(2, -6), Vector2(12, 6)), Color.WHITE)  # chef hat
	draw_circle(at + Vector2(8 + _facing * 3, 5), 1.0, Color.BLACK)
	if carried:
		draw_rect(Rect2(at + Vector2(-2, -10), Vector2(12, 3)), Color.WHITE)
		draw_rect(Rect2(at + Vector2(0, -14), Vector2(8, 4)), carried.dish.color)
	if _cleaning_left > 0.0:
		draw_line(at + Vector2(16, 14), at + Vector2(22, 10 + sin(_cleaning_left * 20.0) * 3.0), Color(0.9, 0.9, 1.0), 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, at + Vector2(0, -18 if carried else -10), "Rin", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(1, 1, 1, 0.8))
	if active and is_at_door() and not carried:
		draw_string(font, at + Vector2(-14, -28), "[E] Vào bếp", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(1, 0.9, 0.5))
