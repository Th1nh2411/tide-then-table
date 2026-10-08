class_name StreetProps
extends RefCounted
## Placeholder drawings shared by the street restaurant (static helpers that
## draw on any CanvasItem): the food cart + stove by kitchen level, the ice
## box by fridge level, the 2x2 bin, plates, and potted plants (decor).


## The cart (X cells + its stove S). Rin's side (top) is the steel worktop
## with the stove; the road side has the glass case, sign strip and wheels.
## Stove by kitchen level: 0 charcoal brazier, 1 gas ring, 2 double gas.
static func draw_cart(canvas: CanvasItem, grid: RoomGrid, level: int, time: float) -> void:
	var cells := grid.cells_of("X")
	cells.append_array(grid.cells_of("S"))
	if cells.is_empty():
		return
	var r := grid.cell_rect(cells[0])
	for cell in cells:
		r = r.merge(grid.cell_rect(cell))
	canvas.draw_rect(Rect2(r.position + Vector2(-1, 0), Vector2(r.size.x + 2, 9)), Color(0.75, 0.78, 0.8))
	canvas.draw_rect(Rect2(r.position + Vector2(1, 9), Vector2(r.size.x - 2, 4)), Color(0.75, 0.9, 1.0, 0.55))
	canvas.draw_rect(Rect2(r.position + Vector2(1, 9), Vector2(r.size.x - 2, 4)), Color(0.9, 0.95, 1.0, 0.85), false, 1.0)
	canvas.draw_rect(Rect2(r.position + Vector2(-1, 13), Vector2(r.size.x + 2, 3)), Color(0.8, 0.15, 0.12))
	canvas.draw_circle(r.position + Vector2(3, 16), 3.0, Color(0.1, 0.1, 0.1))
	canvas.draw_circle(Vector2(r.end.x - 3, r.position.y + 16), 3.0, Color(0.1, 0.1, 0.1))
	var c := grid.cell_rect(grid.cells_of("S")[0]).get_center() + Vector2(0, -4)
	match level:
		0:
			canvas.draw_circle(c, 6.0, Color(0.55, 0.3, 0.2))
			canvas.draw_circle(c, 4.5, Color(0.15, 0.1, 0.08))
			for i in 3:
				canvas.draw_circle(c + Vector2(-2 + i * 2, sin(time * 5.0 + i) * 0.8), 1.2, Color(1.0, 0.45, 0.1))
		1:
			canvas.draw_circle(c, 5.5, Color(0.3, 0.3, 0.32))
			canvas.draw_arc(c, 3.0, 0.0, TAU, 12, Color(0.35, 0.6, 1.0, 0.7 + 0.3 * sin(time * 8.0)), 1.5)
		_:
			for dx: float in [-8.0, 8.0]:
				canvas.draw_circle(c + Vector2(dx, 0), 5.0, Color(0.3, 0.3, 0.32))
				canvas.draw_arc(c + Vector2(dx, 0), 2.8, 0.0, TAU, 12, Color(0.35, 0.6, 1.0, 0.7 + 0.3 * sin(time * 8.0 + dx)), 1.5)


## Ice box by fridge level: 0 styrofoam box, 1 blue cooler, 2 chest freezer.
static func draw_ice_box(canvas: CanvasItem, r: Rect2, level: int) -> void:
	match level:
		0:
			canvas.draw_rect(Rect2(r.position + Vector2(1, 2), Vector2(14, 12)), Color(0.94, 0.95, 0.96))
			canvas.draw_rect(Rect2(r.position + Vector2(1, 11), Vector2(14, 3)), Color(0.78, 0.8, 0.82))
		1:
			canvas.draw_rect(Rect2(r.position + Vector2(0, -2), Vector2(16, 16)), Color(0.25, 0.5, 0.85))
			canvas.draw_rect(Rect2(r.position + Vector2(0, -2), Vector2(16, 4)), Color(0.9, 0.9, 0.92))
		_:
			canvas.draw_rect(Rect2(r.position + Vector2(-1, -8), Vector2(17, 22)), Color(0.88, 0.9, 0.93))
			canvas.draw_rect(Rect2(r.position + Vector2(-1, -8), Vector2(17, 5)), Color(0.7, 0.75, 0.8))
			canvas.draw_rect(Rect2(r.position + Vector2(10, 2), Vector2(3, 2)), Color(0.3, 0.8, 0.4))  # power light


static func draw_plate(canvas: CanvasItem, plate: DishShelf.Plate, at: Vector2) -> void:
	canvas.draw_circle(at, 5.0, Color.WHITE)
	canvas.draw_circle(at + Vector2(0, -1), 3.2, plate.dish.color)
	if not plate.visit.is_empty():  # a regular's order
		canvas.draw_arc(at, 5.5, 0.0, TAU, 14, Color(1.0, 0.8, 0.3), 1.0)


static func draw_plant(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at + Vector2(1, 6), Vector2(6, 6)), Color(0.65, 0.35, 0.2))
	canvas.draw_circle(at + Vector2(4, 3), 4.5, Color(0.25, 0.55, 0.25))
	canvas.draw_circle(at + Vector2(2, 1), 1.5, Color(0.95, 0.4, 0.55))


## Big blue plastic bin (2x2 cells) with a lid and a bag sticking out.
static func draw_bin(canvas: CanvasItem, r: Rect2) -> void:
	var body := r.grow(-3)
	canvas.draw_rect(Rect2(body.position + Vector2(0, 4), body.size - Vector2(0, 4)), Color(0.2, 0.4, 0.8))
	canvas.draw_rect(Rect2(body.position + Vector2(0, body.size.y - 4), Vector2(body.size.x, 4)), Color(0.14, 0.28, 0.6))
	canvas.draw_rect(Rect2(body.position + Vector2(-1, 0), Vector2(body.size.x + 2, 6)), Color(0.15, 0.32, 0.68))  # lid
	canvas.draw_rect(Rect2(body.position + Vector2(4, -2), Vector2(8, 3)), Color(0.2, 0.2, 0.22))  # bag
