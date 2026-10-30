class_name MapSymbols
extends RefCounted
## Ink symbols of the sea chart (PhoneMap): places, dock, pins, boat,
## labels and the legend, drawn with an ink outline like a printed chart.

const INK := Color("090a14")
const PAPER := Color("e7d5b3")
const BOAT := Color("ebede9")
const DOCK := Color("f2d98a")
const PLACE := Color("a53030")
const NET := Color("de9e41")
const PIN := Color("e0302b")
const FOG := Color("5ff2e0")


## Text printed on the chart: ink with a paper outline so it reads on sea and land.
static func label(view: CanvasItem, font: Font, at: Vector2, text: String, font_size: int,
		color: Color = INK) -> void:
	view.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, PAPER)
	view.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Round mark with a 1 px ink ring.
static func dot(view: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	view.draw_circle(at, radius + 1.0, INK)
	view.draw_circle(at, radius, color)


## Dock: small gold square on a jetty.
static func dock(view: CanvasItem, at: Vector2) -> void:
	view.draw_rect(Rect2(at - Vector2(4, 4), Vector2(8, 8)), INK)
	view.draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 6)), DOCK)
	view.draw_rect(Rect2(at + Vector2(-1, 3), Vector2(2, 5)), INK)


## Push pin: red head on an ink needle, number on top.
static func pin(view: CanvasItem, font: Font, at: Vector2, number: int, font_size: int) -> void:
	view.draw_line(at, at - Vector2(0, 6), INK, 1.0)
	dot(view, at - Vector2(0, 8), 2.5, PIN)
	label(view, font, at + Vector2(4, -7), str(number), font_size, PIN)


## Boat arrow pointing where it heads + a fading "you are here" ring.
static func boat(view: CanvasItem, at: Vector2, rotation: float) -> void:
	var pulse := fmod(Time.get_ticks_msec() * 0.001, 1.2) / 1.2
	view.draw_arc(at, 5.0 + pulse * 9.0, 0.0, TAU, 20, Color(INK, 0.7 * (1.0 - pulse)), 1.0)
	var forward := Vector2.RIGHT.rotated(rotation)
	var side := forward.orthogonal()
	var outline := PackedVector2Array([at + forward * 8.0, at - forward * 5.5 + side * 5.0,
		at - forward * 5.5 - side * 5.0])
	view.draw_colored_polygon(outline, INK)
	view.draw_colored_polygon(PackedVector2Array([at + forward * 6.0, at - forward * 4.0 + side * 3.5,
		at - forward * 4.0 - side * 3.5]), BOAT)


## Whirlpool: a small teal spiral.
static func whirlpool(view: CanvasItem, at: Vector2) -> void:
	dot(view, at, 4.0, Color("172038"))
	var turn := Time.get_ticks_msec() * 0.003
	view.draw_arc(at, 3.0, turn, turn + PI * 1.5, 8, FOG, 1.0)
	view.draw_circle(at, 1.0, FOG)


## Key to the symbols, right-aligned on the baseline `y`.
static func legend(view: CanvasItem, font: Font, right: float, y: float, font_size: int) -> void:
	var items: Array = [["Thuyền", BOAT], ["Bến", DOCK], ["Địa điểm", PLACE], ["Lưới", NET], ["Ghim", PIN]]
	var x := right
	for i in range(items.size() - 1, -1, -1):
		var text: String = items[i][0]
		x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		view.draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)
		dot(view, Vector2(x - 6, y - font_size * 0.35), 2.0, items[i][1])
		x -= 16.0
