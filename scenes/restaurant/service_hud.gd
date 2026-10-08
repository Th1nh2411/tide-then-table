class_name ServiceHud
extends Control
## Over the shop front (so the kitchen stays clear): the order tickets, oldest
## first (table, dish colour, patience; green border when its plate is on the
## plate table, gold for a regular). The menu is on the LED board (MenuBoard);
## Rin grills / pours with E at the grill / beer tap.

@export var customers: CustomerManager
@export var tickets_origin: Vector2 = Vector2(4, 4)
@export var ticket_size: Vector2 = Vector2(30, 18)
@export var max_tickets: int = 8


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in mini(customers.waiting.size(), max_tickets):
		var customer := customers.waiting[i]
		var rect := Rect2(tickets_origin + Vector2(i * (ticket_size.x + 3), 0), ticket_size)
		draw_rect(rect, Color(1.0, 0.97, 0.88))
		draw_circle(rect.position + Vector2(8, 8), 4.0, customer.dish.color)
		draw_string(font, rect.position + Vector2(14, 11), "B%d" % (customer.seat + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.2, 0.15, 0.1))
		draw_rect(Rect2(rect.position + Vector2(2, ticket_size.y - 4), Vector2((ticket_size.x - 4) * customer.patience, 2)),
			Color(1, 0.3, 0.3).lerp(Color(0.3, 0.8, 0.4), customer.patience))
		if customers.shelf.find_for(customer.dish, customer.visit):
			draw_rect(rect, Color(0.3, 0.9, 0.4), false, 2.0)
		elif customer.regular_name:
			draw_rect(rect, Color(1.0, 0.8, 0.3), false, 1.0)
