class_name ServiceHud
extends Control
## Over the shop front (so the kitchen stays clear): the order tickets, one
## per table, oldest first (table, a dot per dish still to bring with a
## green ring when its plate is on the plate table, patience; gold border
## for a regular). The menu is on the LED board (MenuBoard); Rin grills /
## pours with E at the grill / beer tap.

@export var customers: CustomerManager
@export var tickets_origin: Vector2 = Vector2(4, 4)
## Ticket height, and width = base + one dot step per dish.
@export var ticket_height: float = 18.0
@export var ticket_base_width: float = 18.0
@export var dot_step: float = 9.0
@export var max_tickets: int = 8


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var x := tickets_origin.x
	var parties := customers.waiting_parties()
	for i in mini(parties.size(), max_tickets):
		var party := parties[i]
		var lines := party.orders
		var rect := Rect2(Vector2(x, tickets_origin.y), Vector2(ticket_base_width + lines.size() * dot_step, ticket_height))
		x += rect.size.x + 3
		draw_rect(rect, Color(1.0, 0.97, 0.88))
		draw_string(font, rect.position + Vector2(2, 11), "B%d" % (party.seat + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.2, 0.15, 0.1))
		for k in lines.size():
			var at := rect.position + Vector2(ticket_base_width + k * dot_step, 8)
			draw_circle(at, 3.5, lines[k].dish.color)
			if customers.shelf.find_for(lines[k].dish, lines[k].visit):
				draw_arc(at, 4.5, 0.0, TAU, 12, Color(0.2, 0.75, 0.3), 1.5)
		draw_rect(Rect2(rect.position + Vector2(2, ticket_height - 4), Vector2((rect.size.x - 4) * party.patience, 2)),
			Color(1, 0.3, 0.3).lerp(Color(0.3, 0.8, 0.4), party.patience))
		if party.regular_name:
			draw_rect(rect, Color(1.0, 0.8, 0.3), false, 1.0)
