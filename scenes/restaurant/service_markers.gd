class_name ServiceMarkers
extends Node2D
## Visual cues over the street restaurant (no prompt text), drawn above
## everyone: customers' bubbles over the party leader ("..." while reading,
## then a dot per dish still coming + table number + patience bar, gold for
## a regular); while Rin carries a
## plate the table that ordered it pulses green with an arrow (nobody
## ordered it: the bin pulses red); a small "E"
## key over the cell (or person) E would act on right now (Cô Năm at the
## grocery too, also before opening; the fridge pulses green while Rin has
## groceries to put away).

@export var room: StreetRoom
@export var rin: RinChef
@export var customers: CustomerManager
@export var kitchen: KitchenStation
@export var stall: MarketStall
@export var good_color: Color = Color(0.3, 1.0, 0.45)
@export var bad_color: Color = Color(1.0, 0.35, 0.3)

var _time: float = 0.0


func _ready() -> void:
	z_index = 20


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for party in customers.waiting_parties():
		_order_bubble(party)
	_draw_reading()
	if rin.active and not kitchen.busy and stall.open and stall.can_reach(rin):
		_key_icon(stall.seller.position + Vector2(0, -40))
	if stall.bag.total() > 0:  # groceries in hand: the fridge pulses
		var fridge := room.merged_rect("F").grow(1)
		draw_rect(fridge, Color(good_color, 0.55 + 0.45 * sin(_time * 6.0)), false, 2.0)
		if rin.active and stall.can_store_at(rin.front_cell()):
			_key_over(rin.front_cell())
	if not kitchen.is_open():
		return
	var pulse := 0.55 + 0.45 * sin(_time * 6.0)
	if rin.carried:
		var seats := _seats_for(rin.carried)
		for k in seats.size():
			var rect := room.table_rect(seats[k]).grow(2)
			draw_rect(rect, Color(good_color, pulse if k == 0 else 0.35), false, 2.0 if k == 0 else 1.0)
			if k == 0:
				_arrow(rect.get_center() + Vector2(0, -14))
		if seats.is_empty():
			draw_rect(room.merged_rect("B").grow(1), Color(bad_color, pulse), false, 2.0)
	if rin.active and not kitchen.busy and _can_act(rin.front_cell()):
		_key_over(rin.front_cell())


## "E" key over the cell E acts on, with a white outline (the whole grill
## for it) — no outline on customer tables, just the key.
func _key_over(cell: Vector2i) -> void:
	var rect := room.merged_rect("N") if room.grid.kind(cell) == "N" else room.grid.cell_rect(cell)
	if room.table_index(cell) < 0:
		draw_rect(rect, Color(1, 1, 1, 0.8), false, 1.0)
	_key_icon(rect.position + Vector2(rect.size.x * 0.5, -6))


## "..." over customers still reading the menu.
func _draw_reading() -> void:
	for node in customers.people_layer.get_children():
		var customer := node as Customer
		if customer and customer.state == Customer.State.READING:
			var at := customer.position + Vector2(0, -42)
			_bubble(at, Color(1, 1, 1, 0.9))
			var dots := ".".repeat(1 + int(_time * 3.0) % 3)
			draw_string(ThemeDB.fallback_font, at + Vector2(-6, 3), dots, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
				Color(0.2, 0.2, 0.2))


func _order_bubble(customer: Customer) -> void:
	var at := customer.position + Vector2(0, -42)
	var n := customer.orders.size()
	var half := 6.0 + n * 4.5
	_bubble(at, Color(1.0, 0.88, 0.5, 0.95) if customer.regular_name else Color(1, 1, 1, 0.95), half)
	for k in n:
		draw_circle(at + Vector2(-half + 6 + k * 9, 0), 3.5, customer.orders[k].dish.color)
	draw_string(ThemeDB.fallback_font, at + Vector2(half - 7, 3), str(customer.seat + 1), HORIZONTAL_ALIGNMENT_LEFT,
		-1, 7, Color(0.2, 0.15, 0.1))
	draw_rect(Rect2(at + Vector2(-half + 1, 9), Vector2(half * 2 - 2, 2)), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(at + Vector2(-half + 1, 9), Vector2((half * 2 - 2) * customer.patience, 2)),
		Color(1, 0.3, 0.3).lerp(Color(0.3, 0.9, 0.4), customer.patience))


## Tables whose waiting order this plate can go to, oldest first.
func _seats_for(plate: DishShelf.Plate) -> Array[int]:
	var result: Array[int] = []
	for order in customers.waiting:
		if order.dish == plate.dish and order.visit == plate.visit and order.seat not in result:
			result.append(order.seat)
	return result


## Whether E on `cell` does something right now (KitchenStation.interact).
func _can_act(cell: Vector2i) -> bool:
	var slot := room.pass_slot(cell)
	if slot >= 0:
		return (rin.carried != null) != (customers.shelf.plate_at(slot) != null)
	if room.grid.kind(cell) == "B":
		return rin.carried != null
	if kitchen.can_act(cell):  # grill / beer tap with an order waiting
		return true
	var seat := room.table_index(cell)
	if seat < 0:
		return false
	if rin.carried:
		return seat in _seats_for(rin.carried)
	return room.dining.states[seat] == DiningTables.State.DIRTY


func _bubble(at: Vector2, color: Color, half_width: float = 11.0) -> void:
	draw_rect(Rect2(at - Vector2(half_width, 7), Vector2(half_width * 2, 15)), color)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-3, 8), at + Vector2(3, 8), at + Vector2(0, 12)]), color)


func _arrow(tip: Vector2) -> void:
	tip.y -= absf(sin(_time * 8.0)) * 3.0
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-4, -6), tip + Vector2(4, -6)]), good_color)


func _key_icon(center: Vector2) -> void:
	var rect := Rect2(center - Vector2(5, 5), Vector2(10, 10))
	draw_rect(rect, Color(1, 1, 1, 0.9))
	draw_rect(rect, Color(0.2, 0.2, 0.2), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(2.5, 8.5), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(0.15, 0.15, 0.15))
