class_name TdHud
extends Control
## Screen HUD for the top-down prototype, all over the shop front so the
## kitchen stays clear: the numbered menu as one row of chips along the top
## (bright while Rin is near the cart, dim elsewhere; click a chip = press
## its number), order tickets + money below it, short messages.

@export var kitchen: TdKitchen
@export var customers: TdCustomers
@export var board_origin: Vector2 = Vector2(4, 3)
## One menu chip (number, colour, name, portions left).
@export var row_size: Vector2 = Vector2(124, 14)
@export var tickets_origin: Vector2 = Vector2(4, 21)
@export var max_tickets: int = 10
@export var ticket_size: Vector2 = Vector2(30, 18)

var money: int = 0

var _message: String = ""
var _message_left: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	customers.paid.connect(func(amount: int) -> void: money += amount)
	kitchen.message_requested.connect(show_message)


func show_message(text: String) -> void:
	_message = text
	_message_left = 1.5


func row_rect(i: int) -> Rect2:
	return Rect2(board_origin + Vector2(i * (row_size.x + 2), 0), row_size)


func _process(delta: float) -> void:
	_message_left = maxf(_message_left - delta, 0.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and kitchen.can_cook():
		for i in kitchen.board.size():
			if row_rect(i).has_point(click.position):
				get_viewport().set_input_as_handled()
				kitchen.cook(i)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(560, 36), "%dk" % money, HORIZONTAL_ALIGNMENT_RIGHT, 72, 12, Color(1, 0.9, 0.5))
	# Tickets: table number, dish colour, patience.
	var waiting := customers.waiting()
	for i in mini(waiting.size(), max_tickets):
		var guest := waiting[i]
		var rect := Rect2(tickets_origin + Vector2(i * (ticket_size.x + 3), 0), ticket_size)
		draw_rect(rect, Color(1.0, 0.97, 0.88))
		draw_circle(rect.position + Vector2(8, 8), 4.0, guest.dish.color)
		draw_string(font, rect.position + Vector2(14, 11), "B%d" % (guest.table + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.2, 0.15, 0.1))
		draw_rect(Rect2(rect.position + Vector2(2, ticket_size.y - 4), Vector2((ticket_size.x - 4) * guest.patience, 2)),
			Color(1, 0.3, 0.3).lerp(Color(0.3, 0.8, 0.4), guest.patience))
	_draw_board(font)
	if _message_left > 0.0:
		draw_string(font, Vector2(0, 300), _message, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10,
			Color(1, 1, 1, minf(_message_left, 1.0)))


## Menu chips, always on screen; dim unless Rin can cook (near the cart).
func _draw_board(font: Font) -> void:
	var active := kitchen.can_cook()
	var fade := 1.0 if active else 0.45
	for i in kitchen.board.size():
		var dish := kitchen.board[i]
		var count: int = kitchen.counts[dish]
		var rect := row_rect(i)
		var ink := Color(1, 0.95, 0.85, (1.0 if count != 0 else 0.4) * fade)
		draw_rect(rect, Color(0.1, 0.12, 0.1, 0.85 * fade))
		if active:
			draw_rect(rect, Color(1, 0.8, 0.3, 0.8), false, 1.0)
		draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(10, 10)), Color(1, 1, 1, ink.a))
		draw_string(font, rect.position + Vector2(4.5, 11), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.1, 0.1, 0.1))
		draw_circle(rect.position + Vector2(17, 7), 3.0, Color(dish.color, ink.a))
		draw_string(font, rect.position + Vector2(23, 10.5), dish.display_name, HORIZONTAL_ALIGNMENT_LEFT,
			row_size.x - 42, 8, ink)
		if count >= 0:
			draw_string(font, rect.position + Vector2(row_size.x - 20, 10.5), "x%d" % count, HORIZONTAL_ALIGNMENT_RIGHT,
				18, 8, ink)
