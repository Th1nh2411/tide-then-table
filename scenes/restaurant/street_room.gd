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
## Owns the grid (RoomGrid) and table states (DiningTables); StreetRoomPainter
## draws cells, plates and tables. StreetBackdrop draws the shop front and traffic.
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
	_top.draw.connect(func() -> void: StreetRoomPainter.draw_top(_top, self, _time))
	add_child(_top)
	if grid == null:
		setup_tables(4)
	# Only the cart's wheel row blocks; its worktop is drawn one row higher,
	# so people standing behind it get their legs hidden by it.
	_add_sorted(merged_rect("XSU").end.y,
		func(canvas: CanvasItem) -> void: StreetProps.draw_cart(canvas, grid, kitchen_level, _time))
	_add_sorted(merged_rect("N").end.y,
		func(canvas: CanvasItem) -> void: StreetProps.draw_grill(canvas, merged_rect("N"), _time))
	_add_sorted(merged_rect("F").end.y,
		func(canvas: CanvasItem) -> void: StreetProps.draw_ice_box(canvas, merged_rect("F"), fridge_level))
	_add_sorted(merged_rect("B").end.y,
		func(canvas: CanvasItem) -> void: StreetProps.draw_bin(canvas, merged_rect("B")))
	_add_sorted(merged_rect("P").end.y,
		func(canvas: CanvasItem) -> void: StreetRoomPainter.draw_plate_bench(canvas, self))
	if not grid.cells_of("V").is_empty():
		_add_sorted(merged_rect("V").end.y,
			func(canvas: CanvasItem) -> void: StreetRoomPainter.draw_stall(canvas, self))
	# One per table slot of the map; slots not in use draw nothing.
	var slots := _table_slots()
	for i in slots.size():
		_add_sorted(grid.cell_rect(slots[i]).position.y + TABLE_SIZE.y * cell_size,
			func(canvas: CanvasItem) -> void: StreetRoomPainter.draw_table(canvas, self, i))


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
	StreetRoomPainter.draw_room(self)
