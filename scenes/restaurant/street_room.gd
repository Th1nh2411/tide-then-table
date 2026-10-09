class_name StreetRoom
extends Node2D
## The restaurant: a Vietnamese sidewalk seafood spot seen top-down (3/4),
## 40x23 tiles of 16 px (5 rows of shop front wall) (Stardew scale), filling the 640x360 view. The shop
## front is at the top, the pavement in the middle, and only the near part of
## the road shows at the bottom. The kitchen stands in the middle of the
## pavement, the tables on the left. Kitchen: the plate table as a bench on
## the left, next to the tables (the pass: one plate per cell, `shelf` slots
## left to right), the fridge against the wall above the bench (bought
## groceries are put away there, MarketStall; ice box upgrade), then a bin
## and the food cart with Bảo's stove (kitchen upgrade) right of the bench,
## the draft beer keg on the cart's right end ("U", Rin pours facing up from the aisle); in front of
## them an open aisle for Rin, then his 2-cell charcoal grill ("N", y-sorted
## like the cart) starting under the cart's left end. Tables (TABLE_SIZE cells, "T" top
## left + "t", two stools above: the customer's seat "h" + a spare "o";
## seated customers face the road) come from the seats upgrade, filling the
## slots nearest the cart first; the decor upgrade adds string lights / plants.
## Next door (right): Cô Năm's grocery stall ("V" counter, "G"
## crates; MarketStall sells over the counter). A small LED menu board stands
## by the curb on the left ("E" cells, MenuBoard).
## Owns the grid (RoomGrid) and table states (DiningTables); draws cells,
## plates and dirty tables. StreetBackdrop draws the shop front and traffic.
## Map legend: see RoomGrid.

const TABLE_SIZE := Vector2i(2, 2)
## The customer's seat ("h") from the table's top-left cell ("T").
const SEAT_OFFSET := Vector2i(0, -1)

@export var map: PackedStringArray = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"..................F...........GG..GG.MM.",
	".ho..ho..ho..ho...............VVVVVV....",
	".Tt..Tt..Tt..Tt.PPPPPBXSXU..............",
	".tt..tt..tt..tt.........................",
	"........................................",
	".ho..ho..ho..ho.......NN................",
	".Tt..Tt..Tt..Tt.........................",
	".tt..tt..tt..tt.........................",
	"D......................................D",
	"D......................................D",
	".........Y...........................Y..",
	"...................EEEE.................",
	"KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
]
@export var cell_size: float = 16.0
## Y-sorted layer with the people (the cart is drawn there).
@export var sorted_layer: Node2D
## The kitchen area (for "Rin is at the kitchen" checks; not drawn).
@export var kitchen_area: Rect2i = Rect2i(15, 5, 13, 6)
@export var stool_colors: Array[Color] = [Color(0.85, 0.2, 0.2), Color(0.2, 0.5, 0.85)]
@export var bike_colors: Array[Color] = [Color(0.9, 0.3, 0.25), Color(0.25, 0.4, 0.9), Color(0.95, 0.95, 0.95),
	Color(0.2, 0.2, 0.22)]

var grid: RoomGrid
## Table states (free / taken / dirty, plates being eaten).
var dining := DiningTables.new()
## [{"table": Vector2i, "chair": Vector2i, "spare": Vector2i}] (the party's
## first and second guest), in use only.
var tables: Array[Dictionary] = []
## The pass (set by CustomerManager): slot i sits on pass_cells()[i].
var shelf: DishShelf
## Upgrade looks (also previewed while renovating).
var kitchen_level: int = 0
var fridge_level: int = 0
var decor_level: int = 0

var _time: float = 0.0
var _top: Node2D  # string lights and tree canopies, above the people
var _sorted: Array[Node2D] = []  # cart + tables, y-sorted with the people


func _ready() -> void:
	_top = Node2D.new()
	_top.z_index = 15
	_top.draw.connect(_draw_top)
	add_child(_top)
	if grid == null:
		setup_tables(4)
	# Only the cart's wheel row blocks; its worktop is drawn one row higher,
	# so people standing behind it get their legs hidden by it.
	_add_sorted(merged_rect("XSU").end.y,
		func(canvas: CanvasItem) -> void: StreetProps.draw_cart(canvas, grid, kitchen_level, _time))
	_add_sorted(merged_rect("N").end.y,
		func(canvas: CanvasItem) -> void: StreetProps.draw_grill(canvas, merged_rect("N"), _time))
	# One per table slot of the map; slots not in use draw nothing.
	var slots := _table_slots()
	for i in slots.size():
		_add_sorted(grid.cell_rect(slots[i]).position.y + TABLE_SIZE.y * cell_size,
			func(canvas: CanvasItem) -> void: _draw_table(canvas, i))


## A prop drawn by its own node in the people's y-sorted layer, its origin
## at the prop's base (`painter` draws in room coordinates).
func _add_sorted(base_y: float, painter: Callable) -> void:
	var node := Node2D.new()
	node.position = Vector2(0, base_y)
	node.draw.connect(func() -> void:
		node.draw_set_transform(-node.position)
		painter.call(node))
	_sorted.append(node)
	if sorted_layer:
		sorted_layer.add_child.call_deferred(node)
	else:
		add_child(node)


## Table slots of the map ("T" cells), column by column from the kitchen:
## the seats upgrade fills the ones nearest Bảo's stove first.
func _table_slots() -> Array[Vector2i]:
	var full := RoomGrid.new(map, cell_size, Vector2.ZERO)
	var stove_x := full.cells_of("S")[0].x
	var slots := full.cells_of("T")
	slots.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := absi(a.x - stove_x)
		var db := absi(b.x - stove_x)
		return da < db or (da == db and a.y < b.y))
	return slots


## Uses the first `count` table slots (rebuilds the grid).
func setup_tables(count: int) -> void:
	var rows := map.duplicate()
	var slots := _table_slots()
	for i in range(count, slots.size()):  # unused slot (table + its stool row): plain pavement
		var at := slots[i]
		for y in range(at.y - 1, at.y + TABLE_SIZE.y):
			rows[y] = rows[y].substr(0, at.x) + ".".repeat(TABLE_SIZE.x) + rows[y].substr(at.x + TABLE_SIZE.x)
	grid = RoomGrid.new(rows, cell_size, Vector2.ZERO)
	tables.clear()
	for i in mini(count, slots.size()):
		var chair := slots[i] + SEAT_OFFSET
		tables.append({"table": slots[i], "chair": chair, "spare": chair + Vector2i.RIGHT})
	dining.setup(tables.size())


## Where to stand to reach table `seat` (a free cell next to one of its
## cells, nearest to `near`); (-1, -1) if none.
func table_stand_cell(seat: int, near: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var top_left: Vector2i = tables[seat]["table"]
	for x in TABLE_SIZE.x:
		for y in TABLE_SIZE.y:
			var stand := grid.stand_cell(top_left + Vector2i(x, y), near)
			if stand.x >= 0 and (best.x < 0 or (stand - near).length_squared() < (best - near).length_squared()):
				best = stand
	return best


## Seat of the table covering `cell` (any of its cells or its chair), -1 if none.
func table_index(cell: Vector2i) -> int:
	for i in tables.size():
		if Rect2i(tables[i]["table"], TABLE_SIZE).has_point(cell) or cell == tables[i]["chair"] \
				or cell == tables[i]["spare"]:
			return i
	return -1


func pass_cells() -> Array[Vector2i]:
	return grid.cells_of("P")


## Pass slot of a cell (-1 if it isn't the plate table).
func pass_slot(cell: Vector2i) -> int:
	return pass_cells().find(cell)


func stove_cell() -> Vector2i:
	return grid.cells_of("S")[0]


## Rin's charcoal grill: its middle "N" cell (where he stands behind it).
func grill_cell() -> Vector2i:
	var cells := grid.cells_of("N")
	return cells[cells.size() / 2]


## Bounding rect of all cells of the given kinds (the bin, the cart...).
func merged_rect(kind_chars: String) -> Rect2:
	var r := Rect2()
	for kind_char in kind_chars:
		for cell in grid.cells_of(kind_char):
			r = grid.cell_rect(cell) if r.size == Vector2.ZERO else r.merge(grid.cell_rect(cell))
	return r


func table_rect(seat: int) -> Rect2:
	return Rect2(grid.cell_rect(tables[seat]["table"]).position, Vector2(TABLE_SIZE) * cell_size)


## Renovation click areas.
func tables_area() -> Rect2:
	return Rect2(8, 92, 240, 120)


func decor_area() -> Rect2:
	return Rect2(8, 78, 250, 22)


func stove_area() -> Rect2:
	return merged_rect("XSU").grow_individual(4, cell_size + 4, 4, 4)


func fridge_area() -> Rect2:
	return grid.cell_rect(grid.cells_of("F")[0]).grow_individual(4, 12, 4, 4)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	_top.queue_redraw()
	for node in _sorted:
		node.queue_redraw()


func _draw() -> void:
	for y in grid.size.y:
		for x in grid.size.x:
			_draw_ground(Vector2i(x, y))
	for y in grid.size.y:
		for x in grid.size.x:
			_draw_thing(Vector2i(x, y))
	StreetProps.draw_ice_box(self, grid.cell_rect(grid.cells_of("F")[0]), fridge_level)
	StreetProps.draw_bin(self, merged_rect("B"))
	if not grid.cells_of("V").is_empty():
		var crates: Array[Rect2] = []
		for cell in grid.cells_of("G"):
			crates.append(grid.cell_rect(cell))
		StreetProps.draw_stall(self, merged_rect("V"), crates)
	if shelf:
		var cells := pass_cells()
		for i in mini(cells.size(), shelf.capacity):
			if shelf.plate_at(i):
				StreetProps.draw_plate(self, shelf.plate_at(i), grid.cell_rect(cells[i]).get_center() + Vector2(0, -2))
	if decor_level >= 2:
		for i in tables.size():
			StreetProps.draw_plant(self, grid.cell_rect(tables[i]["table"]).position + Vector2(-8, 0))


func _draw_ground(cell: Vector2i) -> void:
	var r := grid.cell_rect(cell)
	match grid.kind(cell):
		"W":
			pass  # StreetBackdrop
		"K":
			draw_rect(r, Color(0.7, 0.68, 0.62))
			draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), Color(0.45, 0.43, 0.4))
		"R":
			draw_rect(r, Color(0.22, 0.22, 0.24))
			if cell.y == 20 and cell.x % 3 != 0:  # centre line dashes, between the lanes
				draw_rect(Rect2(r.position + Vector2(0, 7), Vector2(r.size.x, 2)), Color(0.9, 0.85, 0.6))
		_:
			var ground := Color(0.58, 0.55, 0.5)
			if (cell.x + cell.y * 3) % 7 == 0:
				ground = ground.darkened(0.06)
			draw_rect(r, ground)
			draw_rect(r, ground.darkened(0.1), false, 1.0)


## Low steel table (TABLE_SIZE cells) with its plate or leftovers (y-sorted).
func _draw_table(canvas: CanvasItem, seat: int) -> void:
	if seat >= tables.size():
		return
	var p := table_rect(seat).position
	var s := table_rect(seat).size
	var leg := Color(0.45, 0.47, 0.5)
	canvas.draw_rect(Rect2(p + Vector2(3, s.y - 9), Vector2(3, 9)), leg)
	canvas.draw_rect(Rect2(p + Vector2(s.x - 6, s.y - 9), Vector2(3, 9)), leg)
	canvas.draw_rect(Rect2(p + Vector2(1, -2), Vector2(s.x - 2, s.y - 10)), Color(0.82, 0.84, 0.86))
	canvas.draw_rect(Rect2(p + Vector2(1, -2), Vector2(s.x - 2, s.y - 10)), Color(0.7, 0.72, 0.75), false, 1.0)
	canvas.draw_rect(Rect2(p + Vector2(1, s.y - 12), Vector2(s.x - 2, 4)), Color(0.6, 0.62, 0.65))
	canvas.draw_rect(Rect2(p + Vector2(s.x - 10, 1), Vector2(6, 5)), Color(0.9, 0.85, 0.7))  # tissue box
	canvas.draw_rect(Rect2(p + Vector2(s.x - 9, 9), Vector2(2, 5)), Color(0.85, 0.2, 0.15))  # chili sauce
	canvas.draw_rect(Rect2(p + Vector2(s.x - 6, 9), Vector2(2, 5)), Color(0.35, 0.2, 0.1))  # fish sauce
	var mid := p + Vector2(cell_size * 0.5 + 2, 7)  # in front of the customer's seat
	if dining.plates[seat] and dining.states[seat] == DiningTables.State.TAKEN:
		StreetProps.draw_plate(canvas, dining.plates[seat], mid)
	if dining.states[seat] == DiningTables.State.DIRTY:
		canvas.draw_circle(mid + Vector2(-1, 0), 4.0, Color(0.95, 0.95, 0.9))
		canvas.draw_circle(mid + Vector2(4, 3), 1.5, Color(0.9, 0.5, 0.35))  # shells
		canvas.draw_circle(mid + Vector2(-5, 4), 1.2, Color(0.9, 0.5, 0.35))
		canvas.draw_circle(mid + Vector2(7, -1), 1.3, Color(0.9, 0.5, 0.35))


func _draw_thing(cell: Vector2i) -> void:
	var r := grid.cell_rect(cell)
	var p := r.position
	match grid.kind(cell):
		"P":  # plate table, a long wooden bench next to the cart
			var x0 := 0.0 if grid.kind(cell + Vector2i.LEFT) == "P" else 1.0
			var x1 := 16.0 if grid.kind(cell + Vector2i.RIGHT) == "P" else 15.0
			draw_rect(Rect2(p + Vector2(x0, 1), Vector2(x1 - x0, 11)), Color(0.72, 0.52, 0.32))
			draw_rect(Rect2(p + Vector2(x0, 12), Vector2(x1 - x0, 3)), Color(0.5, 0.35, 0.2))
			draw_line(p + Vector2(x0, 1), p + Vector2(x1, 1), Color(0.8, 0.6, 0.38), 1.0)
			if x0 > 0.0 or x1 < 16.0:  # legs at the ends
				draw_rect(Rect2(p + Vector2(2.0 if x0 > 0.0 else 12.0, 15), Vector2(2, 1)), Color(0.4, 0.28, 0.16))
		"h", "o":
			var color := stool_colors[(cell.x / 3 + cell.y) % stool_colors.size()]
			draw_rect(Rect2(p + Vector2(3, 4), Vector2(10, 8)), color)
			draw_rect(Rect2(p + Vector2(3, 12), Vector2(10, 3)), color.darkened(0.3))
		"M":
			StreetProps.draw_bike_parked(self, r.get_center() + Vector2(0, 2), bike_colors[cell.x % bike_colors.size()])
		"Z":
			draw_rect(Rect2(p + Vector2(1, -6), Vector2(14, 20)), Color(0.15, 0.45, 0.2))
			for i in 3:
				draw_line(p + Vector2(1, -2 + i * 6), p + Vector2(15, -2 + i * 6), Color(0.1, 0.3, 0.12), 1.0)
		"Y":
			draw_rect(Rect2(p + Vector2(6, -6), Vector2(4, 20)), Color(0.4, 0.28, 0.18))
			draw_rect(Rect2(p + Vector2(6, 6), Vector2(4, 8)), Color(0.95, 0.95, 0.9))
		"L":
			draw_rect(Rect2(p + Vector2(6, -40), Vector2(4, 54)), Color(0.6, 0.6, 0.58))


## Above the people: tree canopies, and string lights from the decor upgrade.
func _draw_top() -> void:
	for tree in grid.cells_of("Y"):
		var c := grid.cell_rect(tree).get_center() + Vector2(0, -16)
		_top.draw_circle(c, 15.0, Color(0.2, 0.45, 0.22, 0.92))
		_top.draw_circle(c + Vector2(-5, -4), 9.0, Color(0.28, 0.55, 0.28, 0.92))
	if decor_level >= 1:
		var bulbs: Array[Color] = [Color(1, 0.9, 0.5), Color(1, 0.5, 0.4), Color(0.6, 0.9, 1)]
		var from := Vector2(decor_area().position.x, 82)
		var to := Vector2(decor_area().end.x, 82)
		for i in 30:
			var t := float(i) / 29.0
			var at := from.lerp(to, t) + Vector2(0, sin(t * PI * 3.0) * 6.0 + 6.0)
			_top.draw_circle(at, 1.6, Color(bulbs[i % 3], 0.7 + 0.3 * sin(_time * 3.0 + i)))
