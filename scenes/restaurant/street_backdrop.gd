class_name StreetBackdrop
extends Node2D
## Behind the street restaurant: the shop front (wall, rolling shutters,
## awning; on the right Cô Năm's open grocery
## with a green awning) over the W rows, and motorbikes passing on the road. Sits
## after StreetRoom and under the people; it only paints the W rows and the
## road lanes.

@export var room: StreetRoom
@export var lane_rows: Vector2i = Vector2i(21, 19)
## The awning turns green from here on (Cô Năm's shop next door).
@export var grocery_from_x: float = 448.0
@export var bike_colors: Array[Color] = [Color(0.9, 0.3, 0.25), Color(0.25, 0.4, 0.9), Color(0.95, 0.95, 0.95),
	Color(0.2, 0.2, 0.22)]
@export var shirt_colors: Array[Color] = [Color(0.3, 0.55, 0.4), Color(0.85, 0.85, 0.8), Color(0.55, 0.3, 0.5)]

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_shop_front()
	_draw_traffic()


func _draw_shop_front() -> void:
	var bottom := room.merged_rect("W").end.y
	var width := room.grid.size.x * room.cell_size
	# Keep the base behind the transparent pixel-art facade so gaps in doors,
	# shelves and awnings never expose the clear viewport.
	draw_rect(Rect2(Vector2.ZERO, Vector2(width, bottom)), Color(0.86, 0.78, 0.55))
	for x0: float in [0.0, 208.0]:
		draw_rect(Rect2(x0 + 8, 24, 160, bottom - 24), Color(0.32, 0.27, 0.23))
		draw_rect(Rect2(x0 + 8, 24, 160, 5), Color(0.62, 0.62, 0.64))
	_draw_grocery(Rect2(456, 24, 160, bottom - 24))
	for i in int(width / 16.0):
		var grocery := i * 16 >= int(grocery_from_x)  # Cô Năm's green awning
		var stripe := Color(0.25, 0.6, 0.3) if grocery else Color(0.15, 0.5, 0.75)
		draw_rect(Rect2(i * 16, bottom - 6, 16, 7), stripe if i % 2 == 0 else Color(0.95, 0.95, 0.9))
	Art.draw(self, "restaurant/shop_front", Rect2(0, 0, width, bottom))


## Cô Năm's grocery next door, open: lit inside, shelves of goods.
func _draw_grocery(r: Rect2) -> void:
	draw_rect(r, Color(0.45, 0.38, 0.28))
	var goods: Array[Color] = [Color(0.3, 0.65, 0.25), Color(0.9, 0.3, 0.2), Color(0.95, 0.75, 0.3),
		Color(0.55, 0.3, 0.55), Color(0.85, 0.55, 0.5)]
	for row in 2:
		var y := r.position.y + 6 + row * 13
		draw_rect(Rect2(r.position.x + 4, y + 8, r.size.x - 8, 2), Color(0.3, 0.22, 0.15))  # shelf
		for i in int((r.size.x - 8) / 9.0):
			draw_rect(Rect2(r.position.x + 6 + i * 9, y + 2, 7, 6), goods[(i + row * 2) % goods.size()])


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
		var y := (lanes.x if forward else lanes.y) + 8.0 - (i / 2) * 6.0
		var back := shirt_colors[(i + 1) % shirt_colors.size()] if i % 3 == 1 else Color.TRANSPARENT  # some carry two
		StreetProps.draw_bike_side(self, Vector2(x, y), 1.0 if forward else -1.0, bike_colors[i % bike_colors.size()],
			true, Color(0.9, 0.75, 0.3) if forward else Color(0.85, 0.2, 0.2), shirt_colors[i % shirt_colors.size()],
			back, Color(0.95, 0.95, 0.95))
