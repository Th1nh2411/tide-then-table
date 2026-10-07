class_name ServiceMarkers
extends Control
## Visual service cues instead of prompt text:
## - carrying a plate: the table(s) that ordered it (and their tickets) pulse
##   green with an arrow; no one ordered it -> the bin pulses red
## - in front of a plate on the shelf: arrow over it, its table glows faintly
## - a small "E" key over whatever E would act on right now

@export var rin: RinWalker
@export var kitchen: KitchenStation
@export var customers: CustomerManager
@export var tables: DiningTables
@export var shelf_display: ShelfDisplay
@export var good_color: Color = Color(0.3, 1.0, 0.45)
@export var bad_color: Color = Color(1.0, 0.35, 0.3)

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not kitchen.is_open() or not rin.active:
		return
	var pulse := 0.55 + 0.45 * sin(_time * 6.0)
	var plate := rin.carried if rin.carried else kitchen.shelf_pick
	if plate:
		var strong := rin.carried != null
		var targets := _orders_for(plate)
		for k in targets.size():
			var customer := targets[k]
			# The first order gets it; later ones of the same dish just glow.
			var alpha := (pulse if k == 0 else 0.35) if strong else 0.35
			draw_rect(_table_rect(customer.seat), Color(good_color, alpha), false, 2.0 if k == 0 and strong else 1.0)
			var ticket := customers.waiting.find(customer)
			if ticket < kitchen.max_tickets:
				draw_rect(kitchen.ticket_rect(ticket).grow(2), Color(good_color, alpha), false, 1.5)
			if k == 0 and strong:
				_arrow(_table_rect(customer.seat).get_center() - Vector2(0, 16), good_color)
		if strong and targets.is_empty():
			draw_rect(shelf_display.bin_rect().grow(2), Color(bad_color, pulse), false, 2.0)
	if kitchen.shelf_pick and not rin.carried:
		var rect := shelf_display.plate_rect(customers.shelf.plates.find(kitchen.shelf_pick))
		_arrow(Vector2(rect.get_center().x, rect.position.y - 2.0), good_color)
	var spot := _e_spot()
	if spot != Vector2.INF:
		_key_icon(spot)


## Waiting customers this plate can go to, in arrival order.
func _orders_for(plate: DishShelf.Plate) -> Array[Customer]:
	var result: Array[Customer] = []
	for customer in customers.waiting:
		if customer.dish == plate.dish and customer.visit == plate.visit and customer.seat >= 0:
			result.append(customer)
	return result


func _table_rect(seat: int) -> Rect2:
	var top := tables.seat_positions[seat] + tables.table_offset
	return Rect2(top + Vector2(-4, -12), Vector2(tables.table_size.x + 8, 34))


## Where the "E" icon goes (what E does right now), or Vector2.INF.
func _e_spot() -> Vector2:
	if kitchen.cooking.is_running():
		return Vector2.INF
	if rin.is_in_kitchen():
		if rin.carried:
			return shelf_display.bin_rect().get_center() - Vector2(0, 16) if kitchen.is_at_bin() else Vector2.INF
		return Vector2.INF  # cooking is by number; the plate arrow says the rest
	var seat := rin.nearest_table()
	if seat == -1:
		return Vector2.INF
	var can_serve := rin.carried and _orders_for(rin.carried).any(func(c: Customer) -> bool: return c.seat == seat)
	if can_serve or (not rin.carried and tables.states[seat] == DiningTables.State.DIRTY):
		return _table_rect(seat).get_center() - Vector2(0, 26)
	return Vector2.INF


func _arrow(tip: Vector2, color: Color) -> void:
	tip.y -= absf(sin(_time * 8.0)) * 2.0
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-3, -4), tip + Vector2(3, -4)]), color)


## A tiny keycap with "E".
func _key_icon(center: Vector2) -> void:
	var rect := Rect2(center - Vector2(5, 5), Vector2(10, 10))
	draw_rect(rect, Color(1, 1, 1, 0.9))
	draw_rect(rect, Color(0.2, 0.2, 0.2), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(2.5, 8.5), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(0.15, 0.15, 0.15))
