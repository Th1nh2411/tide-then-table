class_name StreetProps
extends RefCounted
## Placeholder drawings shared by the street restaurant (static helpers that
## draw on any CanvasItem): the food cart + stove by kitchen level, the ice
## box by fridge level, the bin, plates, potted plants (decor), motorbikes
## (riding / parked) and the market stall next door.


## The cart (X cells + its stove S + the beer tap U on its right end). The
## top is the steel worktop with Bảo's stove, a chopping board and the draft
## beer keg; the road side has the glass case, sign strip and wheels.
## Stove by kitchen level: 0 charcoal brazier, 1 gas ring, 2 double gas.
static func draw_cart(canvas: CanvasItem, grid: RoomGrid, level: int, time: float) -> void:
	var cells := grid.cells_of("X")
	cells.append_array(grid.cells_of("S"))
	cells.append_array(grid.cells_of("U"))
	if cells.is_empty():
		return
	var r := grid.cell_rect(cells[0])
	for cell in cells:
		r = r.merge(grid.cell_rect(cell))
	r = r.grow_individual(0, grid.cell_size, 0, 0)  # the worktop rises one row above its (solid) base
	var top := r.size.y - 14.0  # worktop depth; the front face below it
	canvas.draw_rect(Rect2(r.position + Vector2(-1, 0), Vector2(r.size.x + 2, top)), Color(0.75, 0.78, 0.8))
	canvas.draw_rect(Rect2(r.position + Vector2(-1, 0), Vector2(r.size.x + 2, 2)), Color(0.88, 0.9, 0.92))
	canvas.draw_rect(Rect2(r.position.x + 2, r.position.y + 4, 11, 8), Color(0.78, 0.6, 0.4))  # chopping board
	for tap in grid.cells_of("U"):  # the draft keg stands on the worktop
		draw_beer_tap(canvas, Vector2(grid.cell_rect(tap).position.x, r.position.y))
	var glass := Rect2(r.position + Vector2(1, top), Vector2(r.size.x - 2, 7))
	canvas.draw_rect(glass, Color(0.75, 0.9, 1.0, 0.55))
	var goods: Array[Color] = [Color(0.95, 0.5, 0.35), Color(0.6, 0.65, 0.75), Color(0.95, 0.75, 0.4)]
	for i in int(glass.size.x / 9.0):
		canvas.draw_rect(Rect2(glass.position + Vector2(3 + i * 9, 3), Vector2(6, 3)), goods[i % goods.size()])
	canvas.draw_rect(glass, Color(0.9, 0.95, 1.0, 0.85), false, 1.0)
	canvas.draw_rect(Rect2(r.position + Vector2(-1, top + 7), Vector2(r.size.x + 2, 5)), Color(0.8, 0.15, 0.12))
	canvas.draw_rect(Rect2(r.position + Vector2(8, top + 8.5), Vector2(r.size.x - 16, 2)), Color(1.0, 0.85, 0.3))  # sign text
	canvas.draw_circle(Vector2(r.position.x + 6, r.end.y), 3.5, Color(0.1, 0.1, 0.1))
	canvas.draw_circle(Vector2(r.end.x - 6, r.end.y), 3.5, Color(0.1, 0.1, 0.1))
	var c := Vector2(grid.cell_rect(grid.cells_of("S")[0]).get_center().x, r.position.y + top * 0.5 + 1.0)
	match level:
		0:
			canvas.draw_circle(c, 7.0, Color(0.55, 0.3, 0.2))
			canvas.draw_circle(c, 5.5, Color(0.15, 0.1, 0.08))
			for i in 3:
				canvas.draw_circle(c + Vector2(-2.5 + i * 2.5, sin(time * 5.0 + i) * 0.8), 1.4, Color(1.0, 0.45, 0.1))
		1:
			canvas.draw_circle(c, 6.5, Color(0.3, 0.3, 0.32))
			canvas.draw_arc(c, 3.5, 0.0, TAU, 12, Color(0.35, 0.6, 1.0, 0.7 + 0.3 * sin(time * 8.0)), 1.5)
		_:
			for dx: float in [-7.0, 9.0]:
				canvas.draw_circle(c + Vector2(dx, 0), 6.0, Color(0.3, 0.3, 0.32))
				canvas.draw_arc(c + Vector2(dx, 0), 3.2, 0.0, TAU, 12, Color(0.35, 0.6, 1.0, 0.7 + 0.3 * sin(time * 8.0 + dx)), 1.5)


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


## Motorbike riding along the road, side view, ~32 px long (people are 16x32).
## `p` = road contact point under the middle; `facing` 1 = right, -1 = left.
static func draw_bike_side(canvas: CanvasItem, p: Vector2, facing: float, color: Color,
		rider: bool = false, helmet: Color = Color.WHITE, shirt: Color = Color.GRAY) -> void:
	var tyre := Color(0.1, 0.1, 0.1)
	canvas.draw_rect(_flip(p, facing, -13, -8, 25, 5), Color(0.3, 0.3, 0.32))  # frame
	canvas.draw_rect(_flip(p, facing, -14, -13, 16, 6), color)  # rear body
	canvas.draw_rect(_flip(p, facing, 6, -18, 5, 13), color)  # front shield
	canvas.draw_rect(_flip(p, facing, -12, -15, 13, 3), Color(0.15, 0.12, 0.1))  # seat
	canvas.draw_rect(_flip(p, facing, 7, -21, 4, 2), Color(0.3, 0.3, 0.32))  # handlebar
	canvas.draw_circle(p + Vector2(-10 * facing, -4), 4.0, tyre)
	canvas.draw_circle(p + Vector2(10 * facing, -4), 4.0, tyre)
	canvas.draw_circle(p + Vector2(-10 * facing, -4), 1.5, Color(0.6, 0.6, 0.62))
	canvas.draw_circle(p + Vector2(10 * facing, -4), 1.5, Color(0.6, 0.6, 0.62))
	canvas.draw_circle(p + Vector2(12 * facing, -14), 1.8, Color(1, 1, 0.7))  # headlight
	if rider:
		draw_rider(canvas, p, facing, helmet, shirt)
		canvas.draw_line(p + Vector2(1 * facing, -26), p + Vector2(8 * facing, -21), shirt.darkened(0.2), 2.0)  # arm


## Someone sitting on a motorbike (side view; the driver adds the arm).
static func draw_rider(canvas: CanvasItem, p: Vector2, facing: float, helmet: Color, shirt: Color) -> void:
	canvas.draw_rect(_flip(p, facing, -4, -17, 8, 5), Color(0.25, 0.25, 0.35))  # thighs
	canvas.draw_rect(_flip(p, facing, 2, -14, 3, 8), Color(0.25, 0.25, 0.35))  # shin
	canvas.draw_rect(_flip(p, facing, -6, -29, 9, 13), shirt)
	canvas.draw_circle(p + Vector2(-1 * facing, -33), 5.5, Color(0.95, 0.8, 0.65))
	canvas.draw_circle(p + Vector2(-1.5 * facing, -35), 5.5, helmet)
	canvas.draw_rect(_flip(p, facing, 2, -34, 3, 2), Color(0.2, 0.2, 0.25, 0.8))  # visor


## Motorbike parked nose down (towards the road), seen from above, ~28 px long.
static func draw_bike_parked(canvas: CanvasItem, p: Vector2, color: Color) -> void:
	var tyre := Color(0.1, 0.1, 0.1)
	canvas.draw_rect(Rect2(p + Vector2(-2, -14), Vector2(4, 5)), tyre)  # back tyre
	canvas.draw_rect(Rect2(p + Vector2(-2, 10), Vector2(4, 5)), tyre)  # front tyre
	canvas.draw_rect(Rect2(p + Vector2(-4, -11), Vector2(8, 21)), color)
	canvas.draw_rect(Rect2(p + Vector2(-3, -9), Vector2(6, 11)), Color(0.15, 0.12, 0.1))  # seat
	canvas.draw_rect(Rect2(p + Vector2(-4, 4), Vector2(8, 5)), color.darkened(0.2))  # front shield
	canvas.draw_rect(Rect2(p + Vector2(-8, 3), Vector2(16, 2)), Color(0.3, 0.3, 0.32))  # handlebar
	canvas.draw_circle(p + Vector2(-8, 2), 1.5, Color(0.7, 0.75, 0.8))  # mirrors
	canvas.draw_circle(p + Vector2(8, 2), 1.5, Color(0.7, 0.75, 0.8))
	canvas.draw_circle(p + Vector2(0, 10), 1.5, Color(1, 1, 0.7))  # headlight


## Rect given for a right-facing drawing, mirrored when facing left.
static func _flip(p: Vector2, facing: float, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(p.x + (x if facing > 0 else -x - w), p.y + y, w, h)


## Cô Năm's grocery stall: the counter (V cells) with goods on top (water
## spinach, tomatoes, beer kegs) and a green front with its name, plastic
## crates behind it (G cells).
static func draw_stall(canvas: CanvasItem, counter: Rect2, crates: Array[Rect2]) -> void:
	var crate_colors: Array[Color] = [Color(0.25, 0.45, 0.8), Color(0.3, 0.6, 0.35)]
	var veg: Array[Color] = [Color(0.3, 0.65, 0.25), Color(0.95, 0.55, 0.15), Color(0.55, 0.3, 0.55)]
	for i in crates.size():
		var c := crates[i]
		canvas.draw_rect(Rect2(c.position + Vector2(1, 3), Vector2(14, 12)), crate_colors[i % crate_colors.size()])
		for k in 3:
			canvas.draw_circle(c.position + Vector2(4 + k * 4, 4), 2.5, veg[(i + k) % veg.size()])
		canvas.draw_line(c.position + Vector2(1, 10), c.position + Vector2(15, 10), Color(0, 0, 0, 0.25), 1.0)
	var p := counter.position
	canvas.draw_rect(Rect2(p + Vector2(0, -4), Vector2(counter.size.x, 12)), Color(0.72, 0.55, 0.35))
	canvas.draw_rect(Rect2(p + Vector2(0, 8), Vector2(counter.size.x, 8)), Color(0.2, 0.5, 0.3))
	canvas.draw_string(ThemeDB.fallback_font, p + Vector2(0, 15), "TẠP HOÁ", HORIZONTAL_ALIGNMENT_CENTER,
		counter.size.x, 7, Color(1, 0.95, 0.8))
	for i in int(counter.size.x / 16.0):
		var at := p + Vector2(i * 16 + 8, 2)
		match i % 3:
			0:  # water spinach bunches
				for k in 3:
					canvas.draw_rect(Rect2(at + Vector2(-6 + k * 4, -4), Vector2(3, 8)), Color(0.25, 0.6, 0.2))
					canvas.draw_rect(Rect2(at + Vector2(-6 + k * 4, 2), Vector2(3, 2)), Color(0.8, 0.75, 0.5))
			1:  # tomatoes and chillies
				canvas.draw_circle(at + Vector2(-3, 0), 2.5, Color(0.9, 0.2, 0.15))
				canvas.draw_circle(at + Vector2(2, -1), 2.5, Color(0.9, 0.25, 0.15))
				canvas.draw_rect(Rect2(at + Vector2(-1, 2), Vector2(6, 1)), Color(0.95, 0.3, 0.1))
			_:  # draft beer keg
				canvas.draw_rect(Rect2(at + Vector2(-5, -5), Vector2(10, 9)), Color(0.72, 0.75, 0.78))
				canvas.draw_rect(Rect2(at + Vector2(-5, -2), Vector2(10, 1)), Color(0.5, 0.52, 0.55))
				canvas.draw_rect(Rect2(at + Vector2(-1, -7), Vector2(2, 2)), Color(0.3, 0.3, 0.32))  # tap


## Rin's charcoal grill (N cells): a low clay brazier with glowing coals, a
## wire grate with skewers and a wisp of smoke.
static func draw_grill(canvas: CanvasItem, r: Rect2, time: float) -> void:
	canvas.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 9)), Color(0.55, 0.3, 0.2))
	canvas.draw_rect(Rect2(r.position + Vector2(2, 11), Vector2(r.size.x - 4, 4)), Color(0.4, 0.22, 0.15))
	canvas.draw_rect(Rect2(r.position + Vector2(4, 3), Vector2(r.size.x - 8, 7)), Color(0.15, 0.1, 0.08))
	for i in int((r.size.x - 8) / 3.0):
		var glow := 0.6 + 0.4 * sin(time * 4.0 + i * 1.7)
		canvas.draw_circle(r.position + Vector2(5.5 + i * 3, 6.5), 1.2, Color(1.0, 0.4 * glow + 0.1, 0.05, glow))
	for i in int((r.size.x - 4) / 4.0):  # grate
		canvas.draw_line(r.position + Vector2(3 + i * 4, 3), r.position + Vector2(3 + i * 4, 10), Color(0.6, 0.6, 0.62), 1.0)
	for k in 2:  # smoke
		var t := fmod(time * 0.6 + k * 0.5, 1.0)
		canvas.draw_circle(r.position + Vector2(r.size.x * (0.35 + k * 0.3) + sin(time + k) * 2.0, 2.0 - t * 14.0),
			2.0 + t * 3.0, Color(0.85, 0.85, 0.85, 0.35 * (1.0 - t)))


## The draft beer keg with its tap, standing on the cart's worktop (`at` =
## top-left of its cell on the worktop row).
static func draw_beer_tap(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at + Vector2(3, -4), Vector2(10, 16)), Color(0.72, 0.75, 0.78))
	canvas.draw_rect(Rect2(at + Vector2(3, 0), Vector2(10, 1)), Color(0.5, 0.52, 0.55))
	canvas.draw_rect(Rect2(at + Vector2(3, 7), Vector2(10, 1)), Color(0.5, 0.52, 0.55))
	canvas.draw_rect(Rect2(at + Vector2(7, 12), Vector2(2, 3)), Color(0.2, 0.2, 0.22))  # spout, Rin's side
	canvas.draw_rect(Rect2(at + Vector2(6, 10), Vector2(4, 2)), Color(0.95, 0.72, 0.2))  # handle
	canvas.draw_rect(Rect2(at + Vector2(4, 15), Vector2(8, 2)), Color(0.3, 0.3, 0.32))  # drip tray


## Small blue plastic bin (one cell) with a lid and a bag sticking out.
static func draw_bin(canvas: CanvasItem, r: Rect2) -> void:
	var body := r.grow_individual(-3, -1, -3, -1)
	canvas.draw_rect(Rect2(body.position + Vector2(0, 3), body.size - Vector2(0, 3)), Color(0.2, 0.4, 0.8))
	canvas.draw_rect(Rect2(body.position + Vector2(0, body.size.y - 3), Vector2(body.size.x, 3)), Color(0.14, 0.28, 0.6))
	canvas.draw_rect(Rect2(body.position + Vector2(-1, 0), Vector2(body.size.x + 2, 4)), Color(0.15, 0.32, 0.68))  # lid
	canvas.draw_rect(Rect2(body.position + Vector2(3, -2), Vector2(5, 2)), Color(0.2, 0.2, 0.22))  # bag
