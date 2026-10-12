class_name StreetRoomPainter
extends RefCounted
## Placeholder drawings of a StreetRoom (static helpers): the floor cells and
## flat things (bench, stools, parked bikes...), plates on the pass, the
## y-sorted tables, and the layer above the people (tree canopies, lights).


## Everything drawn on the room itself (below the people).
static func draw_room(room: StreetRoom) -> void:
	var grid := room.grid
	for y in grid.size.y:
		for x in grid.size.x:
			draw_ground(room, Vector2i(x, y))
	for y in grid.size.y:
		for x in grid.size.x:
			draw_thing(room, Vector2i(x, y))
	StreetProps.draw_ice_box(room, grid.cell_rect(grid.cells_of("F")[0]), room.fridge_level)
	StreetProps.draw_bin(room, room.merged_rect("B"))
	if not grid.cells_of("V").is_empty():
		var crates: Array[Rect2] = []
		for cell in grid.cells_of("G"):
			crates.append(grid.cell_rect(cell))
		StreetProps.draw_stall(room, room.merged_rect("V"), crates)
	if room.shelf:
		var cells := room.pass_cells()
		for i in mini(cells.size(), room.shelf.capacity):
			if room.shelf.plate_at(i):
				StreetProps.draw_plate(room, room.shelf.plate_at(i), grid.cell_rect(cells[i]).get_center() + Vector2(0, -2))
	if room.decor_level >= 2:
		for i in room.tables.size():
			StreetProps.draw_plant(room, grid.cell_rect(room.tables[i]["table"]).position + Vector2(-8, 0))


static func draw_ground(room: StreetRoom, cell: Vector2i) -> void:
	var r := room.grid.cell_rect(cell)
	match room.grid.kind(cell):
		"W":
			pass  # StreetBackdrop
		"K" when Art.draw(room, "restaurant/curb", r):
			pass
		"R" when Art.draw(room, "restaurant/road_line" if cell.y == 20 and cell.x % 3 != 0 else "restaurant/road", r):
			pass
		"K":
			room.draw_rect(r, Color(0.7, 0.68, 0.62))
			room.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), Color(0.45, 0.43, 0.4))
		"R":
			room.draw_rect(r, Color(0.22, 0.22, 0.24))
			if cell.y == 20 and cell.x % 3 != 0:  # centre line dashes, between the lanes
				room.draw_rect(Rect2(r.position + Vector2(0, 7), Vector2(r.size.x, 2)), Color(0.9, 0.85, 0.6))
		_ when Art.draw(room, _pavement(cell), r):
			pass
		_:
			var ground := Color(0.58, 0.55, 0.5)
			if (cell.x + cell.y * 3) % 7 == 0:
				ground = ground.darkened(0.06)
			room.draw_rect(r, ground)
			room.draw_rect(r, ground.darkened(0.1), false, 1.0)


## Pavement tile, with up to 3 variants ("pavement_2" / "_3") for variety.
static func _pavement(cell: Vector2i) -> String:
	var variant := (cell.x * 7 + cell.y * 13) % 5
	if variant >= 3 and Art.has("restaurant/pavement_%d" % (variant - 1)):
		return "restaurant/pavement_%d" % (variant - 1)
	return "restaurant/pavement"


## Low steel table (TABLE_SIZE cells) with its plate or leftovers (y-sorted).
static func draw_table(canvas: CanvasItem, room: StreetRoom, seat: int) -> void:
	if seat >= room.tables.size():
		return
	var dining := room.dining
	var p := room.table_rect(seat).position
	var s := room.table_rect(seat).size
	var mid := p + Vector2(room.cell_size * 0.5 + 2, 7)  # in front of the customer's seat
	if Art.draw(canvas, "restaurant/table", Rect2(p, s)):
		if dining.plates[seat] and dining.states[seat] == DiningTables.State.TAKEN:
			StreetProps.draw_plate(canvas, dining.plates[seat], mid)
		if dining.states[seat] == DiningTables.State.DIRTY and not Art.draw(canvas, "restaurant/table_dirty", Rect2(p, s)):
			canvas.draw_circle(mid, 4.0, Color(0.95, 0.95, 0.9))
		return
	var leg := Color(0.45, 0.47, 0.5)
	canvas.draw_rect(Rect2(p + Vector2(3, s.y - 9), Vector2(3, 9)), leg)
	canvas.draw_rect(Rect2(p + Vector2(s.x - 6, s.y - 9), Vector2(3, 9)), leg)
	canvas.draw_rect(Rect2(p + Vector2(1, -2), Vector2(s.x - 2, s.y - 10)), Color(0.82, 0.84, 0.86))
	canvas.draw_rect(Rect2(p + Vector2(1, -2), Vector2(s.x - 2, s.y - 10)), Color(0.7, 0.72, 0.75), false, 1.0)
	canvas.draw_rect(Rect2(p + Vector2(1, s.y - 12), Vector2(s.x - 2, 4)), Color(0.6, 0.62, 0.65))
	canvas.draw_rect(Rect2(p + Vector2(s.x - 10, 1), Vector2(6, 5)), Color(0.9, 0.85, 0.7))  # tissue box
	canvas.draw_rect(Rect2(p + Vector2(s.x - 9, 9), Vector2(2, 5)), Color(0.85, 0.2, 0.15))  # chili sauce
	canvas.draw_rect(Rect2(p + Vector2(s.x - 6, 9), Vector2(2, 5)), Color(0.35, 0.2, 0.1))  # fish sauce
	if dining.plates[seat] and dining.states[seat] == DiningTables.State.TAKEN:
		StreetProps.draw_plate(canvas, dining.plates[seat], mid)
	if dining.states[seat] == DiningTables.State.DIRTY:
		canvas.draw_circle(mid + Vector2(-1, 0), 4.0, Color(0.95, 0.95, 0.9))
		canvas.draw_circle(mid + Vector2(4, 3), 1.5, Color(0.9, 0.5, 0.35))  # shells
		canvas.draw_circle(mid + Vector2(-5, 4), 1.2, Color(0.9, 0.5, 0.35))
		canvas.draw_circle(mid + Vector2(7, -1), 1.3, Color(0.9, 0.5, 0.35))


static func draw_thing(room: StreetRoom, cell: Vector2i) -> void:
	var grid := room.grid
	var r := grid.cell_rect(cell)
	var p := r.position
	match grid.kind(cell):
		"P" when Art.draw(room, _bench_piece(grid, cell), r):
			pass
		"h", "o" when Art.draw(room, "restaurant/stool_%d" % ((cell.x / 3 + cell.y) % 2), r):
			pass
		"P":  # plate table, a long wooden bench next to the cart
			var x0 := 0.0 if grid.kind(cell + Vector2i.LEFT) == "P" else 1.0
			var x1 := 16.0 if grid.kind(cell + Vector2i.RIGHT) == "P" else 15.0
			room.draw_rect(Rect2(p + Vector2(x0, 1), Vector2(x1 - x0, 11)), Color(0.72, 0.52, 0.32))
			room.draw_rect(Rect2(p + Vector2(x0, 12), Vector2(x1 - x0, 3)), Color(0.5, 0.35, 0.2))
			room.draw_line(p + Vector2(x0, 1), p + Vector2(x1, 1), Color(0.8, 0.6, 0.38), 1.0)
			if x0 > 0.0 or x1 < 16.0:  # legs at the ends
				room.draw_rect(Rect2(p + Vector2(2.0 if x0 > 0.0 else 12.0, 15), Vector2(2, 1)), Color(0.4, 0.28, 0.16))
		"h", "o":
			var color := room.stool_colors[(cell.x / 3 + cell.y) % room.stool_colors.size()]
			room.draw_rect(Rect2(p + Vector2(3, 4), Vector2(10, 8)), color)
			room.draw_rect(Rect2(p + Vector2(3, 12), Vector2(10, 3)), color.darkened(0.3))
		"M":
			StreetProps.draw_bike_parked(room, r.get_center() + Vector2(0, 2),
				room.bike_colors[cell.x % room.bike_colors.size()])
		"Z":
			room.draw_rect(Rect2(p + Vector2(1, -6), Vector2(14, 20)), Color(0.15, 0.45, 0.2))
			for i in 3:
				room.draw_line(p + Vector2(1, -2 + i * 6), p + Vector2(15, -2 + i * 6), Color(0.1, 0.3, 0.12), 1.0)
		"Y":
			room.draw_rect(Rect2(p + Vector2(6, -6), Vector2(4, 20)), Color(0.4, 0.28, 0.18))
			room.draw_rect(Rect2(p + Vector2(6, 6), Vector2(4, 8)), Color(0.95, 0.95, 0.9))
		"L":
			room.draw_rect(Rect2(p + Vector2(6, -40), Vector2(4, 54)), Color(0.6, 0.6, 0.58))


## The plate bench is drawn per cell: "plate_bench_left" / "_mid" /
## "_right" pieces if they exist, else the same "plate_bench" in every cell.
static func _bench_piece(grid: RoomGrid, cell: Vector2i) -> String:
	var left := grid.kind(cell + Vector2i.LEFT) == "P"
	var right := grid.kind(cell + Vector2i.RIGHT) == "P"
	var piece := "restaurant/plate_bench_" + ("mid" if left and right else "right" if left else "left")
	return piece if Art.has(piece) else "restaurant/plate_bench"


## Above the people: tree canopies, and string lights from the decor upgrade.
static func draw_top(canvas: CanvasItem, room: StreetRoom, time: float) -> void:
	for tree in room.grid.cells_of("Y"):
		var c := room.grid.cell_rect(tree).get_center() + Vector2(0, -16)
		canvas.draw_circle(c, 15.0, Color(0.2, 0.45, 0.22, 0.92))
		canvas.draw_circle(c + Vector2(-5, -4), 9.0, Color(0.28, 0.55, 0.28, 0.92))
	if room.decor_level >= 1:
		var bulbs: Array[Color] = [Color(1, 0.9, 0.5), Color(1, 0.5, 0.4), Color(0.6, 0.9, 1)]
		var from := Vector2(room.decor_area().position.x, 82)
		var to := Vector2(room.decor_area().end.x, 82)
		for i in 30:
			var t := float(i) / 29.0
			var at := from.lerp(to, t) + Vector2(0, sin(t * PI * 3.0) * 6.0 + 6.0)
			canvas.draw_circle(at, 1.6, Color(bulbs[i % 3], 0.7 + 0.3 * sin(time * 3.0 + i)))
