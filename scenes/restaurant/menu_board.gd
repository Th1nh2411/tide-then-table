class_name MenuBoard
extends Node2D
## A small LED menu board standing on the pavement by the curb (the "E" cells
## of the StreetRoom map): a scrolling title, then today's seafood dishes as
## pictures only (a plate in the dish's colour) with the servings left; sold
## out = dimmed with a red cross. Rows: KitchenStation.menu_rows() of kind
## "menu" (no rau / beer, no regulars' orders). Lives in the people's y-sorted
## layer (origin = the board's base) so walkers behind it are hidden.
## Before opening it's the way to plan the menu: while `clickable` it pulses
## a gold frame with a bouncing arrow above it, lifts and lights up under the
## mouse (hand cursor), and a click emits `clicked`.

signal clicked

@export var room: StreetRoom
@export var kitchen: KitchenStation
@export var title: String = "QUÁN RIN & BẢO  ·  HẢI SẢN TƯƠI SỐNG  ·  "
@export var led_color: Color = Color(1.0, 0.62, 0.15)
@export var sold_out_color: Color = Color(1.0, 0.2, 0.15)
@export var board_height: float = 40.0
@export var font_size: int = 7
@export var icon_radius: float = 6.0
@export var icon_step: float = 20.0

## Set by the restaurant: the menu can be planned now (before opening).
var clickable: bool = false

var _time: float = 0.0
var _hovered: bool = false
var _mouse: Vector2 = Vector2(-1000, -1000)  # in room coordinates


func _ready() -> void:
	position = Vector2(0, room.merged_rect("E").end.y)


func _process(delta: float) -> void:
	_time += delta
	var hovered := clickable and is_visible_in_tree() and _panel().grow(3).has_point(_mouse)
	if hovered != _hovered:
		_hovered = hovered
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered else Input.CURSOR_ARROW)
	queue_redraw()


func _exit_tree() -> void:
	if _hovered:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion:
		_mouse = get_canvas_transform().affine_inverse() * motion.position


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and _hovered:
		get_viewport().set_input_as_handled()
		clicked.emit()


## The board's face in room coordinates.
func _panel() -> Rect2:
	var base := room.merged_rect("E")
	return Rect2(base.position.x, base.end.y - board_height - 8, base.size.x, board_height)


func _draw() -> void:
	draw_set_transform(-position)
	var base := room.merged_rect("E")
	var panel := _panel()
	for x: float in [panel.position.x + 6, panel.end.x - 9]:  # posts
		draw_rect(Rect2(x, panel.end.y, 3, base.end.y - panel.end.y - 1), Color(0.3, 0.3, 0.33))
	if _hovered:  # lifts a little under the mouse
		draw_set_transform(-position + Vector2(0, -2))
	if not Art.draw(self, "restaurant/menu_board", Rect2(panel.position - Vector2(2, 2),
			Vector2(panel.size.x + 4, base.end.y - panel.position.y + 1))):
		draw_rect(panel.grow(2), Color(0.22, 0.22, 0.25))
	draw_rect(panel, Color(0.04, 0.04, 0.06))
	if clickable:
		var pulse := 1.0 if _hovered else 0.45 + 0.4 * sin(_time * 4.0)
		draw_rect(panel.grow(3), Color(1.0, 0.85, 0.3, pulse), false, 2.0 if _hovered else 1.0)
		var tip := Vector2(panel.get_center().x, panel.position.y - 5 - absf(sin(_time * 5.0)) * 4.0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-4, -6), tip + Vector2(4, -6)]),
			Color(1.0, 0.85, 0.3))
	var font := ThemeDB.fallback_font
	var start := int(_time * 6.0) % title.length()
	_led_text(font, panel.position + Vector2(2, 8), _fit((title + title).substr(start), font, panel.size.x - 4))
	draw_line(panel.position + Vector2(2, 10), panel.position + Vector2(panel.size.x - 2, 10), Color(led_color, 0.35), 1.0)
	var rows := kitchen.menu_rows().filter(func(row: Dictionary) -> bool: return row["kind"] == "menu")
	for i in rows.size():
		var row: Dictionary = rows[i]
		var dish: DishData = row["dish"]
		var count: int = row["count"]
		var at := panel.position + Vector2(8 + i * icon_step, 10 + (panel.size.y - 10) * 0.5)
		var alpha := 1.0 if count > 0 else 0.35
		draw_circle(at, icon_radius, Color(1, 1, 1, alpha))
		draw_circle(at + Vector2(0, -0.5), icon_radius * 0.65, Color(dish.color, alpha))
		if StreetProps.rin_grills(dish):  # Rin grills this one
			StreetProps.draw_flame(self, at + Vector2(icon_radius * 0.7, -icon_radius * 0.4), 5.0, _time)
		if count > 0:
			_led_text(font, at + Vector2(icon_radius + 1, 4), str(count))
		else:  # sold out: red cross
			var red := Color(sold_out_color, 0.6 + 0.4 * sin(_time * 6.0))
			var d := icon_radius
			draw_line(at + Vector2(-d, -d), at + Vector2(d, d), red, 1.5)
			draw_line(at + Vector2(-d, d), at + Vector2(d, -d), red, 1.5)
	draw_set_transform(Vector2.ZERO)


## The longest start of `text` that fits in `width` px.
func _fit(text: String, font: Font, width: float) -> String:
	var n := text.length()
	while n > 0 and font.get_string_size(text.left(n), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		n -= 1
	return text.left(n)


## Text with a soft glow behind it, like lit LEDs.
func _led_text(font: Font, at: Vector2, text: String) -> void:
	draw_string(font, at + Vector2(0.5, 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(led_color, 0.3))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, led_color)
