class_name TdMarkers
extends Node2D
## Visual cues for the top-down prototype (no prompt text):
## - outline on the cell Rin faces when E does something there (+ "E" key)
## - carrying a plate: the table that ordered it pulses green with an arrow;
##   nobody ordered it -> the bin pulses red

@export var room: TdRoom
@export var chef: TdChef
@export var customers: TdCustomers
@export var kitchen: TdKitchen
@export var good_color: Color = Color(0.3, 1.0, 0.45)
@export var bad_color: Color = Color(1.0, 0.35, 0.3)

var _time: float = 0.0


func _ready() -> void:
	z_index = 20


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.55 + 0.45 * sin(_time * 6.0)
	if chef.carried:
		var targets := _tables_for(chef.carried.dish)
		for k in targets.size():
			var rect := room.grid.cell_rect(room.tables[targets[k]]["table"]).grow(2)
			draw_rect(rect, Color(good_color, pulse if k == 0 else 0.35), false, 2.0 if k == 0 else 1.0)
			if k == 0:
				_arrow(rect.get_center() + Vector2(0, -16))
		if targets.is_empty():
			for bin in room.grid.cells_of("B"):
				draw_rect(room.grid.cell_rect(bin).grow(1), Color(bad_color, pulse), false, 2.0)
	if not chef.active:
		return
	var front := chef.front_cell()
	if _can_act(front):
		var rect := room.grid.cell_rect(front)
		draw_rect(rect, Color(1, 1, 1, 0.8), false, 1.0)
		_key_icon(rect.position + Vector2(rect.size.x * 0.5, -6), "E")


## Tables whose waiting guest ordered `dish`, oldest order first.
func _tables_for(dish: DishData) -> Array[int]:
	var result: Array[int] = []
	for guest in customers.waiting():
		if guest.dish == dish:
			result.append(guest.table)
	return result


## Whether E on `cell` does something right now.
func _can_act(cell: Vector2i) -> bool:
	var kind := room.grid.kind(cell)
	if room.is_counter(cell):
		return (chef.carried != null) != room.counter_plates.has(cell)
	if kind == "B":
		return chef.carried != null
	if kind in ["T", "h"]:
		var table := room.table_index(cell)
		if chef.carried:
			return table in _tables_for(chef.carried.dish)
		return room.dirty.has(room.tables[table]["table"])
	return false


func _arrow(tip: Vector2) -> void:
	tip.y -= absf(sin(_time * 8.0)) * 3.0
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-4, -6), tip + Vector2(4, -6)]), good_color)


func _key_icon(center: Vector2, text: String) -> void:
	var rect := Rect2(center - Vector2(5, 5), Vector2(10, 10))
	draw_rect(rect, Color(1, 1, 1, 0.9))
	draw_rect(rect, Color(0.2, 0.2, 0.2), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(2.5, 8.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(0.15, 0.15, 0.15))
