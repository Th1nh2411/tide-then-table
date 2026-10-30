class_name TicketRail3D
extends Control
## The HUD's ticket rail: a taut wire with two nails across the top, one
## OrderTicket3D slip per table with an order, packed left to right in table
## order; new slips drop in with a turn, then follow their slot.

const STEP := 34.0

var _tickets: Dictionary = {}  # table -> OrderTicket3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `orders`: the scene's per-table orders (empty dict = free table).
func refresh(orders: Array[Dictionary]) -> void:
	var live: Array[int] = []
	for i: int in range(orders.size()):
		if not orders[i].is_empty():
			live.append(i)
	for table: int in _tickets.keys():
		if not live.has(table):
			(_tickets[table] as Control).queue_free()
			_tickets.erase(table)
	for slot in live.size():
		var table := live[slot]
		var ticket: OrderTicket3D = _tickets.get(table)
		var home := Vector2(6.0 + slot * STEP, 2.0)
		if ticket == null:
			ticket = OrderTicket3D.new()
			ticket.position = home
			add_child(ticket)
			_tickets[table] = ticket
			UiFx.tilt(ticket, 1.5 if table % 2 == 0 else -1.5)
			UiFx.settle(ticket, Vector2(0, -40), 0.0, 10.0)
			Sfx.play("flip")
		elif ticket.position.distance_to(home) > 0.5 and ticket.modulate.a >= 1.0:
			ticket.position = ticket.position.lerp(home, 0.25)
		ticket.set_order(table, orders[table])
	visible = not live.is_empty()


func _draw() -> void:
	var y := 3.0
	draw_rect(Rect2(0, y + 1.0, size.x, 1), Color(HudChips.INK, 0.5))
	draw_rect(Rect2(0, y, size.x, 1), Color("819796"))
	for x: float in [0.0, size.x - 4.0]:
		draw_rect(Rect2(x, y - 2.0, 4, 5), HudChips.INK)
		draw_rect(Rect2(x + 1.0, y - 1.0, 2, 2), Color("c7cfcc"))
