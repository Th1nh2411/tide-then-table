class_name ServiceHud
extends Control
## Over the shop front (so the kitchen stays clear): today's menu as one row
## of numbered chips (bright while Rin can cook near the cart, dim elsewhere;
## click a chip = press its number) and the order tickets below it (table,
## dish colour, patience; green border when its plate is on the plate table).

@export var kitchen: KitchenStation
@export var customers: CustomerManager
@export var chips_origin: Vector2 = Vector2(4, 3)
@export var chip_size: Vector2 = Vector2(104, 14)
@export var tickets_origin: Vector2 = Vector2(4, 21)
@export var ticket_size: Vector2 = Vector2(30, 18)
@export var max_tickets: int = 8


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func chip_rect(i: int) -> Rect2:
	return Rect2(chips_origin + Vector2(i * (chip_size.x + 2), 0), chip_size)


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and kitchen.can_cook() and visible:
		for i in kitchen.trays().size():
			if chip_rect(i).has_point(click.position):
				get_viewport().set_input_as_handled()
				kitchen.cook(i)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_chips(font)
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


func _draw_chips(font: Font) -> void:
	var active := kitchen.can_cook()
	var fade := 1.0 if active else 0.45
	var rows := kitchen.trays()
	for i in mini(rows.size(), 9):
		var row := rows[i]
		var count: int = row["count"]
		var rect := chip_rect(i)
		var ink := Color(1, 0.95, 0.85, (1.0 if count != 0 else 0.4) * fade)
		draw_rect(rect, Color(0.1, 0.12, 0.1, 0.85 * fade))
		if active:
			draw_rect(rect, Color(1, 0.8, 0.3, 0.8), false, 1.0)
		if row["kind"] == "regular":
			draw_rect(rect, Color(1, 0.8, 0.3, fade), false, 1.0)
		draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(10, 10)), Color(1, 1, 1, ink.a))
		draw_string(font, rect.position + Vector2(4.5, 11), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(0.1, 0.1, 0.1))
		draw_circle(rect.position + Vector2(17, 7), 3.0, Color((row["dish"] as DishData).color, ink.a))
		draw_string(font, rect.position + Vector2(23, 10.5), row["label"], HORIZONTAL_ALIGNMENT_LEFT,
			chip_size.x - 44, 8, ink)
		if count >= 0:
			draw_string(font, rect.position + Vector2(chip_size.x - 20, 10.5), "x%d" % count,
				HORIZONTAL_ALIGNMENT_RIGHT, 18, 8, ink)
