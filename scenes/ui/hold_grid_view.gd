class_name HoldGridView
extends Control
## Draws the hold grid, a tray for an incoming fish that didn't fit, and a
## discard zone. Left mouse drags items; `rotate_item` turns the dragged item.
## Selling (`selling` true, at the lobster raft): the discard zone becomes a
## green "Bán" zone; dropping a fish there or right-clicking it sells it
## (`item_sold`; the caller pays).
## All game rules live in GridInventory; this only draws and forwards moves.

signal pending_changed
signal item_discarded(item: InventoryItem)
signal item_sold(item: InventoryItem)

@export var cell_size: int = 20
@export var tray_cells: Vector2i = Vector2i(3, 3)
@export var gap: int = 16
@export var cell_color: Color = Color(0.2, 0.15, 0.1)
@export var line_color: Color = Color(1, 1, 1, 0.15)
@export var valid_color: Color = Color(0.4, 1.0, 0.5)
@export var invalid_color: Color = Color(1.0, 0.35, 0.3)
@export var trash_color: Color = Color(0.5, 0.15, 0.15)
@export var sell_color: Color = Color(0.15, 0.45, 0.2)

## Sell mode: what one fish fetches (InventoryItem -> int); empty = not selling.
var sell_price: Callable

var hold: GridInventory
## Incoming fish waiting in the tray (overflow mode), or null.
var pending: InventoryItem

var _dragged: InventoryItem
var _drag_from_pending: bool = false
var _drag_origin_pos: Vector2i
var _drag_origin_rotated: bool
## Which cell of the item's bounding box the mouse is holding.
var _grab_offset: Vector2i = Vector2i.ZERO
var _mouse: Vector2 = Vector2.ZERO


func set_hold(new_hold: GridInventory) -> void:
	cancel_drag()
	if hold and hold.changed.is_connected(queue_redraw):
		hold.changed.disconnect(queue_redraw)
	hold = new_hold
	hold.changed.connect(queue_redraw)
	var trash_bottom := _trash_rect().end.y
	custom_minimum_size = Vector2(_tray_rect().end.x, maxf(_grid_rect().end.y, trash_bottom))
	queue_redraw()


func set_pending(item: InventoryItem) -> void:
	pending = item
	pending_changed.emit()
	queue_redraw()


## Put a dragged item back where it came from (used when the UI closes).
func cancel_drag() -> void:
	if _dragged == null:
		return
	if _drag_from_pending:
		_dragged.rotated = _drag_origin_rotated
	else:
		hold.place(_dragged, _drag_origin_pos, _drag_origin_rotated)
	_dragged = null
	queue_redraw()


## Name and quality of the item under the mouse, for the info line.
func get_hover_text() -> String:
	if hold == null:
		return ""
	var item := _dragged
	if item == null and hold and _grid_rect().has_point(_mouse):
		item = hold.get_item_at(_mouse_cell())
	if item == null and pending and _tray_rect().has_point(_mouse):
		item = pending
	if item == null:
		return ""
	var text := "%s %s · chất lượng %.1f" % [item.fish.display_name, item.fish.weight_text(item.size), item.quality]
	if is_selling():
		text += " · bán %dk" % int(sell_price.call(item))
	return text


func is_selling() -> bool:
	return sell_price.is_valid()


## Centre of the discard / "Bán" zone on screen (Guide points at it).
func zone_center() -> Vector2:
	return get_global_rect().position + _trash_rect().get_center()


func _process(_delta: float) -> void:
	if _dragged and Input.is_action_just_pressed("rotate_item"):
		_dragged.rotated = not _dragged.rotated
		# The old grab cell may not exist after rotating; hold by the corner.
		_grab_offset = Vector2i.ZERO
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = event.position
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_mouse = event.position
		if is_selling() and _dragged == null and _grid_rect().has_point(_mouse):
			var item := hold.get_item_at(_mouse_cell())
			if item:
				hold.remove(item)
				item_sold.emit(item)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = event.position
		if event.pressed:
			_start_drag()
		else:
			_end_drag()
		accept_event()


func _start_drag() -> void:
	if _dragged or hold == null:
		return
	if _grid_rect().has_point(_mouse):
		var item := hold.get_item_at(_mouse_cell())
		if item:
			_begin_drag(item, false, _mouse_cell() - item.grid_pos)
			hold.remove(item)
	elif pending and _tray_rect().has_point(_mouse):
		var offset := Vector2i((_mouse - _tray_rect().position) / cell_size)
		_begin_drag(pending, true, offset.clamp(Vector2i.ZERO, pending.get_size() - Vector2i.ONE))


func _begin_drag(item: InventoryItem, from_pending: bool, offset: Vector2i) -> void:
	_dragged = item
	_drag_from_pending = from_pending
	_drag_origin_pos = item.grid_pos
	_drag_origin_rotated = item.rotated
	_grab_offset = offset


func _end_drag() -> void:
	if _dragged == null:
		return
	var item := _dragged
	if _grid_rect().has_point(_mouse) and hold.place(item, _drop_pos()):
		if _drag_from_pending:
			set_pending(null)
		_dragged = null
	elif _trash_rect().has_point(_mouse):
		if _drag_from_pending:
			set_pending(null)
		_dragged = null
		if is_selling():
			item_sold.emit(item)
		else:
			item_discarded.emit(item)
	else:
		cancel_drag()
	queue_redraw()


func _mouse_cell() -> Vector2i:
	return Vector2i((_mouse / cell_size).floor())


## Top-left grid position the dragged item would land on.
func _drop_pos() -> Vector2i:
	return _mouse_cell() - _grab_offset


func _grid_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(hold.size * cell_size))


func _tray_rect() -> Rect2:
	return Rect2(Vector2(_grid_rect().end.x + gap, 0), Vector2(tray_cells * cell_size))


func _trash_rect() -> Rect2:
	var tray := _tray_rect()
	return Rect2(Vector2(tray.position.x, tray.end.y + 8), Vector2(tray.size.x, cell_size * 1.5))


func _draw() -> void:
	if hold == null:
		return
	var font := ThemeDB.fallback_font
	for y in hold.size.y:
		for x in hold.size.x:
			var cell_rect := Rect2(Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			draw_rect(cell_rect, cell_color)
			draw_rect(cell_rect, line_color, false, 1.0)
	for item in hold.items:
		_draw_item(item, Vector2(item.grid_pos * cell_size), 1.0)

	var tray := _tray_rect()
	draw_rect(tray, Color(0, 0, 0, 0.35))
	draw_string(font, tray.position + Vector2(2, -3), "Cá mới", HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	if pending and _dragged != pending:
		_draw_item(pending, tray.position, 1.0)

	var trash := _trash_rect()
	draw_rect(trash, sell_color if is_selling() else trash_color)
	var zone_text := "Bỏ"
	if is_selling():
		zone_text = "Bán %dk" % int(sell_price.call(_dragged)) if _dragged else "Bán"
	draw_string(font, trash.position + Vector2(0, trash.size.y * 0.5 + 4), zone_text,
		HORIZONTAL_ALIGNMENT_CENTER, trash.size.x, 12)

	if _dragged:
		_draw_dragged()


func _draw_dragged() -> void:
	if _grid_rect().has_point(_mouse):
		# Snap to the grid and outline green/red for valid/invalid drop.
		var pos := _drop_pos()
		var outline := valid_color if hold.can_place(_dragged, pos) else invalid_color
		_draw_item(_dragged, Vector2(pos * cell_size), 0.7, outline)
	else:
		var origin := _mouse - (Vector2(_grab_offset) + Vector2(0.5, 0.5)) * cell_size
		_draw_item(_dragged, origin, 0.7)


## The fish's picture over its cells (drawn unrotated, bow to the right;
## turned 90° clockwise like InventoryItem.get_cells when rotated).
func _draw_fish_art(item: InventoryItem, origin: Vector2, alpha: float) -> void:
	var size := Vector2i.ZERO
	for cell in item.fish.shape:
		size = size.max(cell + Vector2i.ONE)
	var art_size := Vector2(size) * cell_size
	if item.rotated:
		draw_set_transform(origin + Vector2(art_size.y, 0), PI / 2.0)
	else:
		draw_set_transform(origin)
	Art.draw(self, "fish/" + item.fish.id, Rect2(Vector2.ZERO, art_size), false, Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO)


func _draw_item(item: InventoryItem, origin: Vector2, alpha: float, outline: Color = Color.TRANSPARENT) -> void:
	var color := item.fish.color
	color.a = alpha
	var art := Art.has("fish/" + item.fish.id)
	if art:
		_draw_fish_art(item, origin, alpha)
	for cell in item.get_cells():
		var rect := Rect2(origin + Vector2(cell * cell_size) + Vector2.ONE, Vector2.ONE * (cell_size - 2))
		if not art:
			draw_rect(rect, color)
		if outline.a > 0.0:
			draw_rect(rect, outline, false, 2.0)
	if item.is_new:
		var tag := Rect2(origin + Vector2(2, cell_size - 10), Vector2(20, 8))
		draw_rect(tag, Color(1.0, 0.85, 0.3, alpha))
		draw_string(ThemeDB.fallback_font, tag.position + Vector2(1, 7), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.2, 0.1, 0.0, alpha))
	# White dot marks a perfect-quality catch.
	if item.quality >= 1.0:
		draw_circle(origin + Vector2(5, 5), 2.0, Color(1, 1, 1, alpha))
