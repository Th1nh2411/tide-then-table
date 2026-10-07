class_name ShelfDisplay
extends Control
## Draws the kitchen side of the dining room: the stove and fridge (looks
## follow their upgrade levels, also previewed while renovating), the shelf
## with the plates waiting on it (CustomerManager.shelf), the trash bin and
## the kitchen door sign.

@export var customers: CustomerManager
@export var shelf_origin: Vector2 = Vector2(78, 186)
@export var slot_width: float = 20.0
@export var door_x: float = 150.0
@export var bin_position: Vector2 = Vector2(20, 246)
@export var stove_rect: Rect2 = Rect2(40, 196, 40, 14)
## Bottom-left of the fridge (it grows upward with its level).
@export var fridge_base: Vector2 = Vector2(3, 210)

## Upgrade levels shown (set by the restaurant / renovation preview).
var kitchen_level: int = 0
var fridge_level: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_stove()
	_draw_fridge()
	var shelf := customers.shelf
	# Shelf board above the counter.
	draw_rect(Rect2(shelf_origin + Vector2(-4, 8), Vector2(slot_width * shelf.capacity + 4, 3)), Color(0.45, 0.3, 0.2))
	for i in shelf.plates.size():
		var at := plate_rect(i).position
		draw_rect(Rect2(at + Vector2(0, 5), Vector2(12, 3)), Color.WHITE)
		draw_rect(Rect2(at + Vector2(2, 1), Vector2(8, 4)), shelf.plates[i].dish.color)
	# Trash bin.
	draw_rect(Rect2(bin_position, Vector2(12, 14)), Color(0.35, 0.4, 0.35))
	draw_rect(Rect2(bin_position + Vector2(-1, -2), Vector2(14, 3)), Color(0.25, 0.3, 0.25))
	# Kitchen door marker.
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2(door_x - 2, 200), Vector2(4, 62)), Color(0.3, 0.2, 0.12))
	draw_string(font, Vector2(door_x - 14, 196), "BẾP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.6))


## 0 = charcoal brazier, 1 = gas stove, 2 = steel range with a hood.
func _draw_stove() -> void:
	var r := stove_rect
	match kitchen_level:
		0:
			draw_rect(r, Color(0.45, 0.25, 0.18))
			for i in 3:
				draw_circle(r.position + Vector2(10 + i * 12, 4), 2.5, Color(1.0, 0.4, 0.15))
		1:
			draw_rect(r, Color(0.55, 0.57, 0.6))
			for i in 2:
				draw_circle(r.position + Vector2(12 + i * 20, 2), 3.0, Color(0.35, 0.6, 1.0))
		_:
			draw_rect(Rect2(r.position - Vector2(8, 0), r.size + Vector2(16, 0)), Color(0.75, 0.78, 0.82))
			draw_rect(Rect2(r.position + Vector2(-10, -46), Vector2(r.size.x + 20, 10)), Color(0.7, 0.72, 0.75))  # hood
			for i in 3:
				draw_circle(r.position + Vector2(6 + i * 16, 2), 3.0, Color(0.35, 0.6, 1.0))


## Taller fridge per level.
func _draw_fridge() -> void:
	var sizes: Array[Vector2] = [Vector2(16, 30), Vector2(20, 42), Vector2(26, 54)]
	var size := sizes[clampi(fridge_level, 0, sizes.size() - 1)]
	var rect := Rect2(fridge_base - Vector2(0, size.y), size)
	draw_rect(rect, Color(0.85, 0.9, 0.95))
	draw_line(rect.position + Vector2(0, size.y * 0.35), rect.position + Vector2(size.x, size.y * 0.35), Color(0.6, 0.65, 0.7), 1.0)
	draw_rect(Rect2(rect.position + Vector2(size.x - 4, 4), Vector2(2, 6)), Color(0.5, 0.5, 0.55))


## Where plate `i` sits on the shelf.
func plate_rect(i: int) -> Rect2:
	return Rect2(shelf_origin + Vector2(i * slot_width, 0), Vector2(12, 8))


func bin_rect() -> Rect2:
	return Rect2(bin_position + Vector2(-1, -2), Vector2(14, 16))


## Index of the plate Rin standing at floor `x` faces (-1 = none).
func plate_index_at(x: float) -> int:
	var index := floori((x - shelf_origin.x + (slot_width - 12.0) * 0.5) / slot_width)
	return index if index >= 0 and index < customers.shelf.plates.size() else -1


## Areas the renovation mode outlines / makes clickable.
func stove_area() -> Rect2:
	return Rect2(stove_rect.position + Vector2(-12, -50), stove_rect.size + Vector2(24, 54))


func fridge_area() -> Rect2:
	return Rect2(fridge_base + Vector2(-2, -58), Vector2(30, 60))


func tables_area(seats: Array[Vector2]) -> Rect2:
	if seats.is_empty():
		return Rect2()
	return Rect2(seats[0] + Vector2(-4, -2), Vector2(seats.back().x - seats[0].x + 66, 42))
