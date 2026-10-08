class_name TdRoom
extends Node2D
## Top-down (3/4) Vietnamese sidewalk seafood spot for the prototype, filling
## the 640x360 view (40x23 tiles of 16 px, Stardew scale). No walls: shop
## front with parked motorbikes at the top, Rin's open-air kitchen on the
## left (a food cart with the stove on it and, right of it, a long table set
## lengthwise for finished plates — the pass: Rin puts plates down from the
## kitchen side, Bảo takes them from the pavement side), low steel tables and plastic stools on the
## pavement (7 tiles, ~6 m), a tree, a pole with string lights, curb, a
## two-lane road (8 tiles) with passing motorbikes and the far pavement. Starting setup: one stove, `table_count` of the map's table
## slots (seats upgrade: 4 -> 6). Holds plates on counters (P, C) and dirty tables.
## Map legend (besides TdGrid's): X food cart (S = its stove), M parked bike, Z beer crates,
## o spare stool, Y tree, L electric pole, Q far side of the street.

@export var map: PackedStringArray = [
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW",
	".................ZZ...........MM..M.MM..",
	"......P.................................",
	"..XSX.P....To...To...To...To...To...To..",
	"......P....h....h....h....h....h....h...",
	"D.....P................................D",
	"D.....P................................D",
	"..L.Y..................................Y",
	"KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ",
	"QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ",
	"QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ",
]
## 16 px tiles, like Stardew Valley (characters are 16x32).
@export var cell_size: float = 16.0
@export var room_origin: Vector2 = Vector2.ZERO
## Rin's kitchen (wet floor): the board lights up / cooking works here.
@export var kitchen_area: Rect2i = Rect2i(1, 5, 6, 5)
## Tables in use (row by row); the other slots stay empty pavement.
@export var table_count: int = 4
@export var stool_colors: Array[Color] = [Color(0.85, 0.2, 0.2), Color(0.2, 0.5, 0.85)]
@export var bike_colors: Array[Color] = [Color(0.9, 0.3, 0.25), Color(0.25, 0.4, 0.9), Color(0.95, 0.95, 0.95),
	Color(0.2, 0.2, 0.22)]

var grid: TdGrid
## cell -> TdPlate on the counters.
var counter_plates: Dictionary = {}
## table cell -> true while dirty.
var dirty: Dictionary = {}
## [{"table": Vector2i, "chair": Vector2i}], one seat per table.
var tables: Array[Dictionary] = []

var _time: float = 0.0
## Tree canopies and string lights, drawn above the people.
var _top: Node2D


func _ready() -> void:
	grid = TdGrid.new(_used_map(), cell_size, room_origin)
	for chair in grid.cells_of("h"):
		tables.append({"table": chair + Vector2i.UP, "chair": chair})
	_top = Node2D.new()
	_top.z_index = 15
	_top.draw.connect(_draw_top)
	add_child(_top)


## The map with table slots past `table_count` (and their stools) cleared.
func _used_map() -> PackedStringArray:
	var rows := map.duplicate()
	var seen := 0
	for y in rows.size():
		for x in rows[y].length():
			if rows[y][x] != "T":
				continue
			seen += 1
			if seen > table_count:
				for cell: Vector2i in [Vector2i(x, y), Vector2i(x, y + 1), Vector2i(x + 1, y)]:
					rows[cell.y] = rows[cell.y].substr(0, cell.x) + "." + rows[cell.y].substr(cell.x + 1)
	return rows


func table_index(cell: Vector2i) -> int:
	for i in tables.size():
		if tables[i]["table"] == cell or tables[i]["chair"] == cell:
			return i
	return -1


func is_counter(cell: Vector2i) -> bool:
	return grid.kind(cell) in ["P", "C"]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	_top.queue_redraw()


func _draw() -> void:
	for y in grid.size.y:
		for x in grid.size.x:
			_draw_ground(Vector2i(x, y))
	_draw_shop_front()
	for y in grid.size.y:
		for x in grid.size.x:
			_draw_thing(Vector2i(x, y))
	_draw_cart()
	_draw_bikes()
	for cell: Vector2i in counter_plates:
		(counter_plates[cell] as TdPlate).draw_at(self, grid.cell_rect(cell).get_center() + Vector2(0, -3))


func _draw_ground(cell: Vector2i) -> void:
	var r := grid.cell_rect(cell)
	match grid.kind(cell):
		"K":
			draw_rect(r, Color(0.7, 0.68, 0.62))
			draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), Color(0.45, 0.43, 0.4))
		"R":
			draw_rect(r, Color(0.22, 0.22, 0.24))
			if cell.y == 16 and cell.x % 3 != 0:  # centre line dashes
				draw_rect(Rect2(r.position + Vector2(0, -1), Vector2(r.size.x, 2)), Color(0.9, 0.85, 0.6))
		"Q":  # far pavement across the street, its curb on top
			draw_rect(r, Color(0.5, 0.48, 0.44))
			if cell.y == 20:
				draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color(0.66, 0.64, 0.58))
		_:
			# Worn pavement bricks; a wet patch around the kitchen.
			var ground := Color(0.58, 0.55, 0.5)
			if (cell.x + cell.y * 3) % 7 == 0:
				ground = ground.darkened(0.06)
			if kitchen_area.has_point(cell):
				ground = ground.darkened(0.12)
			draw_rect(r, ground)
			draw_rect(r, ground.darkened(0.1), false, 1.0)


func _draw_thing(cell: Vector2i) -> void:
	var r := grid.cell_rect(cell)
	var p := r.position
	match grid.kind(cell):
		"P":  # long wooden table for finished plates (set lengthwise)
			var last := grid.kind(cell + Vector2i.DOWN) != "P"
			draw_rect(Rect2(p + Vector2(2, 0), Vector2(12, 16 if not last else 12)), Color(0.72, 0.52, 0.32))
			if last:
				draw_rect(Rect2(p + Vector2(2, 12), Vector2(12, 3)), Color(0.5, 0.35, 0.2))
			draw_line(p + Vector2(2, 0), p + Vector2(14, 0), Color(0.6, 0.43, 0.27), 1.0)
		"F":
			if cell == grid.cells_of("F")[0]:  # styrofoam ice box
				draw_rect(Rect2(p + Vector2(1, 2), Vector2(14, 12)), Color(0.94, 0.95, 0.96))
				draw_rect(Rect2(p + Vector2(1, 11), Vector2(14, 3)), Color(0.78, 0.8, 0.82))
			else:  # plastic basin with live shrimp and clams
				draw_circle(r.get_center(), 7.0, Color(0.2, 0.45, 0.85))
				draw_circle(r.get_center(), 5.5, Color(0.5, 0.75, 0.9))
				for i in 4:
					draw_circle(r.get_center() + Vector2(cos(i * 1.7 + _time) * 3.0, sin(i * 2.3) * 3.0), 1.2,
						Color(1.0, 0.5, 0.4))
		"C":  # aluminium folding table
			draw_rect(Rect2(p + Vector2(0, 3), Vector2(16, 9)), Color(0.75, 0.77, 0.8))
			draw_rect(Rect2(p + Vector2(0, 12), Vector2(16, 2)), Color(0.55, 0.57, 0.6))
		"B":  # blue plastic bucket
			draw_rect(Rect2(p + Vector2(3, 3), Vector2(10, 11)), Color(0.2, 0.4, 0.8))
			draw_rect(Rect2(p + Vector2(2, 2), Vector2(12, 2)), Color(0.15, 0.3, 0.65))
		"T":  # low stainless table
			draw_rect(Rect2(p + Vector2(0, 2), Vector2(16, 10)), Color(0.82, 0.84, 0.86))
			draw_rect(Rect2(p + Vector2(0, 12), Vector2(16, 2)), Color(0.6, 0.62, 0.65))
			draw_rect(Rect2(p + Vector2(10, 3), Vector2(4, 4)), Color(0.9, 0.85, 0.7))  # tissue box
			if dirty.has(cell):
				draw_circle(r.get_center() + Vector2(-3, -1), 3.0, Color(0.95, 0.95, 0.9))
				draw_circle(r.get_center() + Vector2(1, 2), 1.5, Color(0.9, 0.5, 0.35))  # shells
				draw_circle(r.get_center() + Vector2(-5, 3), 1.2, Color(0.9, 0.5, 0.35))
		"h", "o":  # plastic stool
			var color := stool_colors[(cell.x / 3 + cell.y) % stool_colors.size()]
			draw_rect(Rect2(p + Vector2(4, 6), Vector2(8, 6)), color)
			draw_rect(Rect2(p + Vector2(4, 12), Vector2(8, 2)), color.darkened(0.3))
		"M":  # parked motorbike, nose to the wall
			var color := bike_colors[cell.x % bike_colors.size()]
			draw_rect(Rect2(p + Vector2(5, 1), Vector2(6, 14)), color)
			draw_rect(Rect2(p + Vector2(6, 5), Vector2(4, 6)), Color(0.15, 0.12, 0.1))  # seat
			draw_rect(Rect2(p + Vector2(2, 1), Vector2(12, 2)), Color(0.3, 0.3, 0.32))  # handlebar
		"Z":  # stacked beer crates
			draw_rect(Rect2(p + Vector2(1, -6), Vector2(14, 20)), Color(0.15, 0.45, 0.2))
			for i in 3:
				draw_line(p + Vector2(1, -2 + i * 6), p + Vector2(15, -2 + i * 6), Color(0.1, 0.3, 0.12), 1.0)
		"Y":  # trunk with the white-painted base
			draw_rect(Rect2(p + Vector2(6, -6), Vector2(4, 20)), Color(0.4, 0.28, 0.18))
			draw_rect(Rect2(p + Vector2(6, 6), Vector2(4, 8)), Color(0.95, 0.95, 0.9))
		"L":  # pole holding the string lights
			draw_rect(Rect2(p + Vector2(6, -40), Vector2(4, 54)), Color(0.6, 0.6, 0.58))


## Shop front: tiled wall, rolling shutters, sign, striped awning.
func _draw_shop_front() -> void:
	var bottom := grid.cell_rect(Vector2i(0, 3)).end.y
	draw_rect(Rect2(room_origin, Vector2(grid.size.x * cell_size, bottom)), Color(0.86, 0.78, 0.55))
	for x0: float in [0.0, 208.0, 448.0]:
		draw_rect(Rect2(x0 + 8, 24, 160, bottom - 24), Color(0.32, 0.27, 0.23))
		draw_rect(Rect2(x0 + 8, 24, 160, 5), Color(0.62, 0.62, 0.64))
	draw_rect(Rect2(456, 42, 160, 14), Color(0.8, 0.12, 0.1))
	draw_string(ThemeDB.fallback_font, Vector2(456, 53), "HẢI SẢN TƯƠI SỐNG", HORIZONTAL_ALIGNMENT_CENTER, 160, 10,
		Color(1, 0.9, 0.35))
	for i in 40:
		var color := Color(0.15, 0.5, 0.75) if i % 2 == 0 else Color(0.95, 0.95, 0.9)
		draw_rect(Rect2(i * 16, bottom - 6, 16, 7), color)


## The food cart (X cells + its stove S): Rin's side (top) is the open steel
## worktop with the charcoal brazier; the customer side (towards the road)
## has the glass case, the red sign strip and the wheels.
func _draw_cart() -> void:
	var cells := grid.cells_of("X")
	cells.append_array(grid.cells_of("S"))
	if cells.is_empty():
		return
	var r := grid.cell_rect(cells[0])
	for cell in cells:
		r = r.merge(grid.cell_rect(cell))
	draw_rect(Rect2(r.position + Vector2(-1, 0), Vector2(r.size.x + 2, 9)), Color(0.75, 0.78, 0.8))  # worktop
	draw_rect(Rect2(r.position + Vector2(1, 9), Vector2(r.size.x - 2, 4)), Color(0.75, 0.9, 1.0, 0.55))  # glass case
	draw_rect(Rect2(r.position + Vector2(1, 9), Vector2(r.size.x - 2, 4)), Color(0.9, 0.95, 1.0, 0.85), false, 1.0)
	draw_rect(Rect2(r.position + Vector2(-1, 13), Vector2(r.size.x + 2, 3)), Color(0.8, 0.15, 0.12))  # sign strip
	draw_circle(r.position + Vector2(3, 16), 3.0, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(r.end.x - 3, r.position.y + 16), 3.0, Color(0.1, 0.1, 0.1))
	for stove in grid.cells_of("S"):
		var c := grid.cell_rect(stove).get_center() + Vector2(0, -4)
		draw_circle(c, 6.0, Color(0.55, 0.3, 0.2))
		draw_circle(c, 4.5, Color(0.15, 0.1, 0.08))
		for i in 3:
			draw_circle(c + Vector2(-2 + i * 2, sin(_time * 5.0 + i) * 0.8), 1.2, Color(1.0, 0.45, 0.1))

## Motorbikes passing on the road (decor).
func _draw_bikes() -> void:
	var lanes := Vector2(grid.cell_rect(Vector2i(0, 17)).get_center().y, grid.cell_rect(Vector2i(0, 14)).get_center().y)
	var width := grid.size.x * cell_size + 80.0
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
		draw_circle(Vector2(x, y - 7), 3.5, Color(0.9, 0.75, 0.3) if i % 2 == 0 else Color(0.85, 0.2, 0.2))  # helmet
		draw_circle(Vector2(x + (9.0 if forward else -9.0), y - 1), 1.8, Color(1, 1, 0.7))


## Above the people: tree canopies and the string lights.
func _draw_top() -> void:
	for tree in grid.cells_of("Y"):
		var c := grid.cell_rect(tree).get_center() + Vector2(0, -16)
		_top.draw_circle(c, 15.0, Color(0.2, 0.45, 0.22, 0.92))
		_top.draw_circle(c + Vector2(-5, -4), 9.0, Color(0.28, 0.55, 0.28, 0.92))
	for pole in grid.cells_of("L"):
		var top := grid.cell_rect(pole).position + Vector2(8, -38)
		# String lights from the pole to the awning.
		var end := Vector2(grid.size.x * cell_size - 40, 64)
		var bulbs: Array[Color] = [Color(1, 0.9, 0.5), Color(1, 0.5, 0.4), Color(0.6, 0.9, 1)]
		for i in 24:
			var t := float(i) / 23.0
			var at := top.lerp(end, t) + Vector2(0, sin(t * PI) * 26.0 + 6)
			var glow := 0.7 + 0.3 * sin(_time * 3.0 + i)
			_top.draw_circle(at, 1.6, Color(bulbs[i % 3], glow))
