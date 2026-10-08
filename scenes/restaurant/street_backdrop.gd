class_name StreetBackdrop
extends Node2D
## Behind the street restaurant: the shop front (wall, rolling shutters,
## sign, awning) over the W rows, and motorbikes passing on the road. Sits
## after StreetRoom and under the people; it only paints the W rows and the
## road lanes.

@export var room: StreetRoom
@export var lane_rows: Vector2i = Vector2i(21, 18)
@export var bike_colors: Array[Color] = [Color(0.9, 0.3, 0.25), Color(0.25, 0.4, 0.9), Color(0.95, 0.95, 0.95),
	Color(0.2, 0.2, 0.22)]

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_shop_front()
	_draw_traffic()


func _draw_shop_front() -> void:
	var bottom := room.grid.cell_rect(Vector2i(0, 3)).end.y
	var width := room.grid.size.x * room.cell_size
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, bottom)), Color(0.86, 0.78, 0.55))
	for x0: float in [0.0, 208.0, 448.0]:
		draw_rect(Rect2(x0 + 8, 24, 160, bottom - 24), Color(0.32, 0.27, 0.23))
		draw_rect(Rect2(x0 + 8, 24, 160, 5), Color(0.62, 0.62, 0.64))
	draw_rect(Rect2(456, 42, 160, 14), Color(0.8, 0.12, 0.1))
	draw_string(ThemeDB.fallback_font, Vector2(456, 53), "HẢI SẢN TƯƠI SỐNG", HORIZONTAL_ALIGNMENT_CENTER, 160, 10,
		Color(1, 0.9, 0.35))
	for i in int(width / 16.0):
		var color := Color(0.15, 0.5, 0.75) if i % 2 == 0 else Color(0.95, 0.95, 0.9)
		draw_rect(Rect2(i * 16, bottom - 6, 16, 7), color)


## Motorbikes passing on both lanes (decor; drive on the right).
func _draw_traffic() -> void:
	var lanes := Vector2(room.grid.cell_rect(Vector2i(0, lane_rows.x)).get_center().y,
		room.grid.cell_rect(Vector2i(0, lane_rows.y)).get_center().y)
	var width := room.grid.size.x * room.cell_size + 80.0
	for i in 4:
		var forward := i % 2 == 0
		var speed := 60.0 + i * 17.0
		var x := fmod(_time * speed + i * 190.0, width) - 40.0
		if not forward:
			x = width - 80.0 - x
		var y := (lanes.x if forward else lanes.y) + (i / 2) * 8.0
		draw_rect(Rect2(x - 9, y - 3, 18, 6), bike_colors[i % bike_colors.size()])
		draw_circle(Vector2(x - 7, y + 3), 2.5, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(x + 7, y + 3), 2.5, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(x, y - 7), 3.5, Color(0.9, 0.75, 0.3) if forward else Color(0.85, 0.2, 0.2))
		draw_circle(Vector2(x + (9.0 if forward else -9.0), y - 1), 1.8, Color(1, 1, 0.7))
