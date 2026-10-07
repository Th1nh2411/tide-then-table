class_name RestaurantDecor
extends Control
## Draws the decorations from the decor upgrade: level 1 = red lanterns
## along the wall, level 2 = + flower pots and a painting. (Tables are drawn
## by DiningTables.) Placeholder drawing only.
@export var lantern_y: float = 70.0
@export var lantern_x_range: Vector2 = Vector2(180.0, 570.0)
@export var lantern_count: int = 6

var _level: int = 0
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func setup(decor_level: int) -> void:
	_level = decor_level
	queue_redraw()


func _process(delta: float) -> void:
	if _level >= 1:
		_time += delta
		queue_redraw()


func _draw() -> void:
	if _level >= 2:
		_draw_painting(Vector2(440, 100))
		for x in [168.0, 590.0]:
			_draw_flower_pot(Vector2(x, 262))
	if _level >= 1:
		_draw_lanterns()


func _draw_lanterns() -> void:
	draw_line(Vector2(lantern_x_range.x - 10, lantern_y - 14), Vector2(lantern_x_range.y + 10, lantern_y - 14),
		Color(0.3, 0.2, 0.15), 1.0)
	for i in lantern_count:
		var x := lerpf(lantern_x_range.x, lantern_x_range.y, float(i) / (lantern_count - 1))
		var swing := sin(_time * 1.5 + i) * 1.5
		var at := Vector2(x + swing, lantern_y)
		draw_line(Vector2(x, lantern_y - 14), at - Vector2(0, 7), Color(0.3, 0.2, 0.15), 1.0)
		draw_circle(at, 12.0, Color(1.0, 0.6, 0.3, 0.15))  # glow
		draw_rect(Rect2(at - Vector2(6, 7), Vector2(12, 14)), Color(0.85, 0.15, 0.12))
		draw_rect(Rect2(at - Vector2(4, 9), Vector2(8, 2)), Color(0.9, 0.75, 0.3))
		draw_rect(Rect2(at + Vector2(-4, 7), Vector2(8, 2)), Color(0.9, 0.75, 0.3))


func _draw_painting(at: Vector2) -> void:
	draw_rect(Rect2(at, Vector2(70, 44)), Color(0.45, 0.3, 0.15))
	draw_rect(Rect2(at + Vector2(4, 4), Vector2(62, 36)), Color(0.75, 0.85, 0.9))
	# Sea, a boat and the moon.
	draw_rect(Rect2(at + Vector2(4, 26), Vector2(62, 14)), Color(0.2, 0.4, 0.65))
	draw_colored_polygon(PackedVector2Array([at + Vector2(24, 26), at + Vector2(44, 26),
		at + Vector2(40, 30), at + Vector2(28, 30)]), Color(0.4, 0.25, 0.15))
	draw_circle(at + Vector2(54, 12), 4.0, Color(1.0, 0.95, 0.75))


func _draw_flower_pot(base: Vector2) -> void:
	draw_rect(Rect2(base + Vector2(-6, -12), Vector2(12, 12)), Color(0.65, 0.35, 0.2))
	for i in 3:
		var tip := base + Vector2(-6 + i * 6, -26 - i % 2 * 4)
		draw_line(base + Vector2(0, -12), tip, Color(0.25, 0.55, 0.25), 1.5)
		draw_circle(tip, 3.0, Color(0.95, 0.4, 0.55) if i != 1 else Color(1.0, 0.85, 0.3))
