class_name InventoryItem
extends RefCounted
## One caught fish, sitting in the boat hold or in storage.

var fish: FishData
## 1.0 for a perfect catch, 0.7 otherwise.
var quality: float = 1.0
## 100 = fresh, 0 = spoiled (drops each day from Phase 7).
var freshness: float = 100.0
## Turned 90 degrees clockwise in the grid.
var rotated: bool = false
## Top-left cell of the item's bounding box. Only meaningful while in a grid.
var grid_pos: Vector2i = Vector2i.ZERO


func _init(p_fish: FishData = null, p_quality: float = 1.0) -> void:
	fish = p_fish
	quality = p_quality


## Occupied cells relative to grid_pos, for the given orientation.
func get_cells(is_rotated: bool = rotated) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in fish.shape:
		# (x, y) -> (-y, x) turns 90° clockwise on screen (y points down).
		cells.append(Vector2i(-cell.y, cell.x) if is_rotated else cell)
	# Rotation produces negative x; shift so the bounding box starts at (0, 0).
	var min_cell := Vector2i(cells[0])
	for cell in cells:
		min_cell = min_cell.min(cell)
	for i in cells.size():
		cells[i] -= min_cell
	return cells


## Width/height of the bounding box in cells.
func get_size(is_rotated: bool = rotated) -> Vector2i:
	var max_cell := Vector2i.ZERO
	for cell in get_cells(is_rotated):
		max_cell = max_cell.max(cell)
	return max_cell + Vector2i.ONE
