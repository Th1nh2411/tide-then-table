class_name RoomGrid
extends RefCounted
## Top-down restaurant: the street as a grid of cells parsed from an
## ASCII map, plus A* paths for walkers. Pure logic, no nodes.
## Legend: # wall, . floor, S stove, P pass counter, C counter, B bin,
## F fridge / ice box, T table, h chair (a customer's seat), D entrance
## (walkable), W building, K curb, R road, L pole, M parked bike, Z crates,
## o spare stool, Y tree, X food cart.

const SOLID := "#SPCBFTWKRLMZoYXQ"

var cell_size: float = 24.0
var origin: Vector2 = Vector2.ZERO
var size: Vector2i = Vector2i.ZERO

var _rows: PackedStringArray = []
var _astar := AStarGrid2D.new()


func _init(rows: PackedStringArray = [], p_cell_size: float = 24.0, p_origin: Vector2 = Vector2.ZERO) -> void:
	_rows = rows
	cell_size = p_cell_size
	origin = p_origin
	size = Vector2i(rows[0].length() if rows.size() > 0 else 0, rows.size())
	_astar.region = Rect2i(Vector2i.ZERO, size)
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()
	for y in size.y:
		for x in size.x:
			_astar.set_point_solid(Vector2i(x, y), not is_walkable(Vector2i(x, y)))


func kind(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
		return "#"
	return _rows[cell.y][cell.x]


func is_walkable(cell: Vector2i) -> bool:
	return not SOLID.contains(kind(cell))


## All cells of one kind, row by row.
func cells_of(kind_char: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			if _rows[y][x] == kind_char:
				result.append(Vector2i(x, y))
	return result


func to_cell(world: Vector2) -> Vector2i:
	return Vector2i(((world - origin) / cell_size).floor())


func to_world(cell: Vector2i) -> Vector2:
	return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(origin + Vector2(cell) * cell_size, Vector2.ONE * cell_size)


## World points from `from` to `to` (both walkable), [] if unreachable.
func path(from: Vector2i, to: Vector2i) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if not is_walkable(from) or not is_walkable(to):
		return result
	for cell in _astar.get_id_path(from, to):
		result.append(to_world(cell))
	return result


## Walkable neighbour of `cell` closest to `near` (where to stand to use it).
func stand_cell(cell: Vector2i, near: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var n := cell + dir
		if kind(n) == "." and (best.x < 0 or (n - near).length_squared() < (best - near).length_squared()):
			best = n
	return best
