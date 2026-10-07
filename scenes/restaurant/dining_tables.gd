class_name DiningTables
extends Control
## The tables (one seat each, count from the seats upgrade) and their state:
## FREE -> TAKEN (a customer sits) -> DIRTY (they ate and left) -> FREE once
## cleaned (by Bảo or Rin). A customer who leaves without eating leaves the
## table FREE. Draws tables, stools and dirty dishes.

enum State { FREE, TAKEN, DIRTY }

@export var table_offset: Vector2 = Vector2(24, 18)
@export var table_size: Vector2 = Vector2(36, 6)
@export var leg_size: Vector2 = Vector2(6, 14)
@export var stool_offset: Vector2 = Vector2(2, 30)
@export var stool_size: Vector2 = Vector2(14, 8)
@export var table_colors: Array[Color] = [Color(0.85, 0.2, 0.2), Color(0.2, 0.6, 0.35),
	Color(0.9, 0.7, 0.2), Color(0.2, 0.45, 0.85)]

## Where each seated customer stands (top-left of the customer).
var seat_positions: Array[Vector2] = []
var states: Array[State] = []
## A plate being eaten from, per table (null if none), drawn on the table.
var plates: Array[DishShelf.Plate] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func setup(seats: Array[Vector2]) -> void:
	seat_positions = seats
	states.resize(seats.size())
	states.fill(State.FREE)
	plates.resize(seats.size())
	queue_redraw()


## First free table, or -1.
func free_seat() -> int:
	return states.find(State.FREE)


func take(seat: int) -> void:
	states[seat] = State.TAKEN
	queue_redraw()


## The customer left without eating.
func release(seat: int) -> void:
	states[seat] = State.FREE
	plates[seat] = null
	queue_redraw()


## Food arrived at this table.
func put_plate(seat: int, plate: DishShelf.Plate) -> void:
	plates[seat] = plate
	queue_redraw()


## The customer ate and left: dirty until cleaned.
func make_dirty(seat: int) -> void:
	states[seat] = State.DIRTY
	queue_redraw()


func clean(seat: int) -> void:
	if states[seat] == State.DIRTY:
		states[seat] = State.FREE
		plates[seat] = null
		queue_redraw()


func dirty_seats() -> Array[int]:
	var result: Array[int] = []
	for i in states.size():
		if states[i] == State.DIRTY:
			result.append(i)
	return result


## Where someone stands to use this table (just left of the stool).
func stand_x(seat: int) -> float:
	return seat_positions[seat].x - 10.0


func _draw() -> void:
	for i in seat_positions.size():
		var seat := seat_positions[i]
		var color := table_colors[i % table_colors.size()]
		var top := seat + table_offset
		draw_rect(Rect2(top, table_size), color)
		draw_rect(Rect2(top + Vector2((table_size.x - leg_size.x) * 0.5, table_size.y), leg_size), color)
		draw_rect(Rect2(seat + stool_offset, stool_size), color.darkened(0.2))
		draw_string(ThemeDB.fallback_font, top + Vector2(table_size.x * 0.5 - 3, table_size.y + 22),
			str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
		if plates[i]:
			var full := states[i] == State.TAKEN
			draw_rect(Rect2(top + Vector2(10, -3), Vector2(16, 3)), Color.WHITE)
			if full:
				draw_rect(Rect2(top + Vector2(12, -7), Vector2(12, 4)), plates[i].dish.color)
		if states[i] == State.DIRTY:
			# Stacked dirty bowls + a stain.
			draw_rect(Rect2(top + Vector2(6, -4), Vector2(10, 4)), Color(0.85, 0.85, 0.8))
			draw_rect(Rect2(top + Vector2(8, -7), Vector2(7, 3)), Color(0.8, 0.8, 0.75))
			draw_circle(top + Vector2(26, -1), 2.0, Color(0.5, 0.35, 0.2, 0.8))
