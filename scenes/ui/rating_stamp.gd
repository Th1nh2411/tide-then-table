class_name RatingStamp
extends Control
## Red rubber stamp with the day's stars ("ĐÃ BÁN" + 5 stars, the earned ones
## inked in), a little uneven like real ink. Final art: ui/stamp_rating
## (empty stamp, stars drawn on top) via Art. Slam it with UiFx.stamp().

const RED := Color("a53030")
const PAPER := Color("e7d5b3")
const MAX_STARS := 5

@export var words: String = "ĐÃ BÁN"
var stars: int = 0


func _init() -> void:
	custom_minimum_size = Vector2(86, 40)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_stars(count: int) -> void:
	stars = clampi(count, 0, MAX_STARS)
	tooltip_text = "%d/%d sao" % [stars, MAX_STARS]
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var ink := Color(RED, 0.92)
	if not Art.draw(self, "ui/stamp_rating", rect):
		draw_rect(rect, ink, false, 2.0)
		draw_rect(rect.grow(-4.0), ink, false, 1.0)
		var font := get_theme_font("font", "TitleLabel")
		draw_string(font, Vector2(0, 17), words, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, ink)
	var step := 13.0
	var left := (size.x - step * MAX_STARS) * 0.5 + step * 0.5
	for i in MAX_STARS:
		_star(Vector2(left + step * i, 28.0), 5.5, i < stars, ink)
	# Worn ink: a few paper specks.
	for i in 14:
		var p := Vector2(fposmod(i * 37.0, size.x - 4.0) + 2.0, fposmod(i * 23.0, size.y - 4.0) + 2.0).floor()
		draw_rect(Rect2(p, Vector2.ONE), Color(PAPER, 0.7))


func _star(center: Vector2, radius: float, filled: bool, ink: Color) -> void:
	var points := PackedVector2Array()
	for k in 10:
		var r := radius if k % 2 == 0 else radius * 0.45
		var a := -PI * 0.5 + PI * k / 5.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	if filled:
		draw_colored_polygon(points, ink)
	else:
		points.append(points[0])
		draw_polyline(points, ink, 1.0)
