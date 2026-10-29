class_name FloorGrid3D
extends RefCounted
## A* over the 3D restaurant floor (x/z plane). Furniture cells are solid.

const ORIGIN := Vector2(-20.0, -7.8)
const CELL := 0.25
const SIZE := Vector2i(160, 64)
const PAD := 0.25
## Furniture footprints: centre x, centre z, width, depth.
const TABLE_SIZE := Vector2(2.6, 1.2)
const FIXED: Array[Rect2] = [
	Rect2(1.6, -4.925, 2.8, 1.25),   # kitchen counter
	Rect2(-1.35, -4.675, 1.1, 0.75), # plate table
	Rect2(4.95, -3.95, 0.5, 0.5),    # beer tap
	Rect2(4.9, 1.45, 1.2, 0.2),      # bep board
	Rect2(0.75, 6.84, 1.5, 0.12),    # menu board
	Rect2(8.2, -4.7, 3.6, 0.8),     # grocery counter
	Rect2(-1.95, -7.6, 0.9, 0.8),    # fridge
]

static var shared: FloorGrid3D

var astar := AStarGrid2D.new()


static func get_shared(tables: Array) -> FloorGrid3D:
	if shared == null:
		shared = FloorGrid3D.new(tables)
	return shared


func _init(tables: Array) -> void:
	astar.region = Rect2i(Vector2i.ZERO, SIZE)
	astar.cell_size = Vector2(CELL, CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for table: Vector3 in tables:
		_block(Rect2(table.x - TABLE_SIZE.x * 0.5, table.z - TABLE_SIZE.y * 0.5, TABLE_SIZE.x, TABLE_SIZE.y))
	for rect in FIXED:
		_block(rect)


## True when the point sits on furniture (with padding).
func blocked_at(p: Vector3) -> bool:
	var cell := _cell(p)
	return not astar.is_in_boundsv(cell) or astar.is_point_solid(cell)


func _block(rect: Rect2) -> void:
	for x in range(SIZE.x):
		for y in range(SIZE.y):
			var center := ORIGIN + Vector2(x + 0.5, y + 0.5) * CELL
			if rect.grow(PAD).has_point(center):
				astar.set_point_solid(Vector2i(x, y), true)


func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x - ORIGIN.x) / CELL), floori((p.z - ORIGIN.y) / CELL))


func _world(c: Vector2i) -> Vector3:
	return Vector3(ORIGIN.x + (c.x + 0.5) * CELL, 0.0, ORIGIN.y + (c.y + 0.5) * CELL)


func _nearest_free(c: Vector2i) -> Vector2i:
	c = Vector2i(clampi(c.x, 0, SIZE.x - 1), clampi(c.y, 0, SIZE.y - 1))
	for r in range(0, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if astar.is_in_boundsv(n) and not astar.is_point_solid(n):
					return n
	return c


## Waypoints from `from` to `to` (both kept exactly), around furniture.
func path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var out := ([] as Array[Vector3])
	var a := _nearest_free(_cell(from))
	var b := _nearest_free(_cell(to))
	var cells := astar.get_id_path(a, b)
	out.append(from)
	if cells.is_empty(): return out
	for i in range(1, cells.size() - 1):
		var w := _world(cells[i])
		out.append(Vector3(w.x, from.y, w.z))
	out.append(to)
	# Greedy line-of-sight shortcuts remove grid stair-steps, retaining padded clearance.
	var smooth: Array[Vector3] = [out[0]]
	var index := 0
	while index < out.size()-1:
		var next := out.size()-1
		while next > index+1 and not _line_clear(out[index],out[next]): next -= 1
		smooth.append(out[next])
		index = next
	return smooth

func _line_clear(a: Vector3, b: Vector3) -> bool:
	var samples := maxi(1,ceili(a.distance_to(b)/(CELL*.4)))
	for i in samples+1:
		if blocked_at(a.lerp(b,float(i)/float(samples))): return false
	return true
