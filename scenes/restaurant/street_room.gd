class_name StreetRoom
extends Node2D
## The restaurant: a Vietnamese sidewalk seafood spot seen top-down (3/4),
## 40x23 tiles of 16 px (Stardew scale), filling the 640x360 view. The shop
## front is at the top, the pavement in the middle, and only the near part of
## the road shows at the bottom. Rin's kitchen (left): the ice box (fridge
## upgrade), the food cart with its stove (kitchen upgrade) and the plate
## table set lengthwise (the pass: one plate per cell, `shelf` slots top to
## bottom), and a bin for unwanted plates. Tables come from the seats upgrade (first `table_count` slots of
## the map), the decor upgrade adds string lights / plants.
## Owns the grid (RoomGrid) and table states (DiningTables); draws cells,
## plates and dirty tables. StreetBackdrop draws the shop front and traffic.
## Map legend: see RoomGrid.

@export var map: PackedStringArray = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"....................ZZ..........MM.MM.M.",
	"........................................",
	".BB....P....To.....To.....To.....To.....",
	".BBXSX.P....h......h......h......h......",
	".......P................................",
	".F.....P................................",
	".......P........To........To............",
	"................h.........h.............",
	"D......................................D",
	"D......................................D",
	"...L.....Y...........................Y..",
	"........................................",
	"KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
]
@export var cell_size: float = 16.0
## Rin's kitchen (wet floor): near enough to cook from here.
@export var kitchen_area: Rect2i = Rect2i(1, 6, 7, 5)
@export var stool_colors: Array[Color] = [Color(0.85, 0.2, 0.2), Color(0.2, 0.5, 0.85)]
@export var bike_colors: Array[Color] = [Color(0.9, 0.3, 0.25), Color(0.25, 0.4, 0.9), Color(0.95, 0.95, 0.95),
	Color(0.2, 0.2, 0.22)]

var grid: RoomGrid
## Table states (free / taken / dirty, plates being eaten).
var dining := DiningTables.new()
## [{"table": Vector2i, "chair": Vector2i}], one seat per table, in use only.
var tables: Array[Dictionary] = []
## The pass (set by CustomerManager): slot i sits on pass_cells()[i].
var shelf: DishShelf
## Upgrade looks (also previewed while renovating).
var kitchen_level: int = 0
var fridge_level: int = 0
var decor_level: int = 0

var _time: float = 0.0
var _top: Node2D  # string lights and tree canopies, above the people


func _ready() -> void:
	_top = Node2D.new()
	_top.z_index = 15
	_top.draw.connect(_draw_top)
	add_child(_top)
	if grid == null:
		setup_tables(4)


## Uses the first `count` table slots of the map (rebuilds the grid).
func setup_tables(count: int) -> void:
	var rows := map.duplicate()
	var seen := 0
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] != "T":
				continue
			seen += 1
			if seen > count:  # unused slot: plain pavement
				for cell: Vector2i in [Vector2i(x, y), Vector2i(x, y + 1), Vector2i(x + 1, y)]:
					rows[cell.y] = rows[cell.y].substr(0, cell.x) + "." + rows[cell.y].substr(cell.x + 1)
	grid = RoomGrid.new(rows, cell_size, Vector2.ZERO)
	tables.clear()
	for chair in grid.cells_of("h"):
		tables.append({"table": chair + Vector2i.UP, "chair": chair})
	dining.setup(tables.size())


func table_index(cell: Vector2i) -> int:
	for i in tables.size():
		if tables[i]["table"] == cell or tables[i]["chair"] == cell:
			return i
	return -1


func pass_cells() -> Array[Vector2i]:
	return grid.cells_of("P")


## Pass slot of a cell (-1 if it isn't the plate table).
func pass_slot(cell: Vector2i) -> int:
	return pass_cells().find(cell)


func stove_cell() -> Vector2i:
	return grid.cells_of("S")[0]


## Bounding rect of all cells of one kind (the 2x2 bin, the cart...).
func merged_rect(kind_char: String) -> Rect2:
	var cells := grid.cells_of(kind_char)
	var r := grid.cell_rect(cells[0])
	for cell in cells:
		r = r.merge(grid.cell_rect(cell))
	return r


func table_rect(seat: int) -> Rect2:
	return grid.cell_rect(tables[seat]["table"])


## Renovation click areas.
func tables_area() -> Rect2:
	return Rect2(176, 88, 400, 104)


func decor_area() -> Rect2:
	return Rect2(160, 62, 470, 22)


func stove_area() -> Rect2:
	var cart := grid.cell_rect(grid.cells_of("X")[0]).merge(grid.cell_rect(grid.cells_of("X")[1]))
	return cart.grow_individual(0, 4, 4, 4)


func fridge_area() -> Rect2:
	return grid.cell_rect(grid.cells_of("F")[0]).grow_individual(4, 12, 4, 4)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	_top.queue_redraw()


func _draw() -> void:
	for y in grid.size.y:
		for x in grid.size.x:
			_draw_ground(Vector2i(x, y))
	for y in grid.size.y:
		for x in grid.size.x:
			_draw_thing(Vector2i(x, y))
	StreetProps.draw_cart(self, grid, kitchen_level, _time)
	StreetProps.draw_ice_box(self, grid.cell_rect(grid.cells_of("F")[0]), fridge_level)
	StreetProps.draw_bin(self, merged_rect("B"))
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
			if cell.y == 20 and cell.x % 3 != 0:  # centre line dashes
				draw_rect(Rect2(r.position + Vector2(0, -1), Vector2(r.size.x, 2)), Color(0.9, 0.85, 0.6))
		_:
			var ground := Color(0.58, 0.55, 0.5)
			if (cell.x + cell.y * 3) % 7 == 0:
				ground = ground.darkened(0.06)
			if kitchen_area.has_point(cell):
				ground = ground.darkened(0.12)  # wet floor around the cart
			draw_rect(r, ground)
			draw_rect(r, ground.darkened(0.1), false, 1.0)


func _draw_thing(cell: Vector2i) -> void:
	var r := grid.cell_rect(cell)
	var p := r.position
	match grid.kind(cell):
		"P":  # plate table, set lengthwise
			var last := grid.kind(cell + Vector2i.DOWN) != "P"
			draw_rect(Rect2(p + Vector2(2, 0), Vector2(12, 12 if last else 16)), Color(0.72, 0.52, 0.32))
			if last:
				draw_rect(Rect2(p + Vector2(2, 12), Vector2(12, 3)), Color(0.5, 0.35, 0.2))
			draw_line(p + Vector2(2, 0), p + Vector2(14, 0), Color(0.6, 0.43, 0.27), 1.0)
		"T":
			var seat := table_index(cell)
			draw_rect(Rect2(p + Vector2(0, 2), Vector2(16, 10)), Color(0.82, 0.84, 0.86))
			draw_rect(Rect2(p + Vector2(0, 12), Vector2(16, 2)), Color(0.6, 0.62, 0.65))
			draw_rect(Rect2(p + Vector2(11, 3), Vector2(4, 4)), Color(0.9, 0.85, 0.7))  # tissue box
			if seat >= 0 and dining.plates[seat]:
				if dining.states[seat] == DiningTables.State.TAKEN:
					StreetProps.draw_plate(self, dining.plates[seat], r.get_center() + Vector2(-2, -1))
			if seat >= 0 and dining.states[seat] == DiningTables.State.DIRTY:
				draw_circle(r.get_center() + Vector2(-3, -1), 3.0, Color(0.95, 0.95, 0.9))
				draw_circle(r.get_center() + Vector2(1, 2), 1.5, Color(0.9, 0.5, 0.35))  # shells
				draw_circle(r.get_center() + Vector2(-5, 3), 1.2, Color(0.9, 0.5, 0.35))
		"h", "o":
			var color := stool_colors[(cell.x / 3 + cell.y) % stool_colors.size()]
			draw_rect(Rect2(p + Vector2(4, 6), Vector2(8, 6)), color)
			draw_rect(Rect2(p + Vector2(4, 12), Vector2(8, 2)), color.darkened(0.3))
		"M":
			var color := bike_colors[cell.x % bike_colors.size()]
			draw_rect(Rect2(p + Vector2(5, 1), Vector2(6, 14)), color)
			draw_rect(Rect2(p + Vector2(6, 5), Vector2(4, 6)), Color(0.15, 0.12, 0.1))
			draw_rect(Rect2(p + Vector2(2, 1), Vector2(12, 2)), Color(0.3, 0.3, 0.32))
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
		var from := Vector2(decor_area().position.x, 66)
		var to := Vector2(decor_area().end.x, 66)
		for i in 30:
			var t := float(i) / 29.0
			var at := from.lerp(to, t) + Vector2(0, sin(t * PI * 3.0) * 6.0 + 6.0)
			_top.draw_circle(at, 1.6, Color(bulbs[i % 3], 0.7 + 0.3 * sin(_time * 3.0 + i)))
