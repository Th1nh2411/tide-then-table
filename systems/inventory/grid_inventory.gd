class_name GridInventory
extends RefCounted
## Pure grid logic for the boat hold (no UI, no nodes).
## Items occupy the cells of their shape; nothing may overlap or leave the grid.
## `is_rotated` parameters default to the item's current orientation.

signal changed

const NO_SPOT := Vector2i(-1, -1)

var size: Vector2i
var items: Array[InventoryItem] = []
## Vector2i cell -> InventoryItem occupying it. Fast overlap checks.
var _cells: Dictionary = {}


func _init(p_size: Vector2i = Vector2i(4, 3)) -> void:
	size = p_size


## True if `item` fits with its top-left at `pos`. The item's own current
## cells count as free, so already-placed items can be moved/rotated in place.
func can_place(item: InventoryItem, pos: Vector2i, is_rotated: bool = item.rotated) -> bool:
	for offset in item.get_cells(is_rotated):
		var cell := pos + offset
		if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
			return false
		var other: InventoryItem = _cells.get(cell)
		if other != null and other != item:
			return false
	return true


## Places (or moves) the item. Returns false and changes nothing if it doesn't fit.
func place(item: InventoryItem, pos: Vector2i, is_rotated: bool = item.rotated) -> bool:
	if not can_place(item, pos, is_rotated):
		return false
	if items.has(item):
		_clear_cells(item)
	else:
		items.append(item)
	item.rotated = is_rotated
	item.grid_pos = pos
	for offset in item.get_cells():
		_cells[pos + offset] = item
	changed.emit()
	return true


func remove(item: InventoryItem) -> void:
	if not items.has(item):
		return
	_clear_cells(item)
	items.erase(item)
	changed.emit()


## First free top-left position (scanning row by row), or NO_SPOT.
func find_free_spot(item: InventoryItem, is_rotated: bool = item.rotated) -> Vector2i:
	for y in size.y:
		for x in size.x:
			if can_place(item, Vector2i(x, y), is_rotated):
				return Vector2i(x, y)
	return NO_SPOT


## Tries the current orientation, then the rotated one. Returns true if placed.
func auto_place(item: InventoryItem) -> bool:
	for is_rotated: bool in [item.rotated, not item.rotated]:
		var spot := find_free_spot(item, is_rotated)
		if spot != NO_SPOT:
			return place(item, spot, is_rotated)
	return false


func get_item_at(cell: Vector2i) -> InventoryItem:
	return _cells.get(cell)


func _clear_cells(item: InventoryItem) -> void:
	for offset in item.get_cells():
		_cells.erase(item.grid_pos + offset)
