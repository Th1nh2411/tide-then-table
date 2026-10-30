class_name OrderTicket3D
extends Control
## One order slip on the HUD's ticket rail: torn-bottom paper clipped to the
## rail, slightly crooked; table number in red ink, the dish picture, a
## patience bar (green -> amber -> red, shakes when the guest is about to
## leave), a sticker for who makes it (Rin's grill flame / beer) and a check
## when the plate is ready (greyed "eating" once served). Paper art:
## ui/frames/ticket (via Art), drawn otherwise.

const SIZE := Vector2(30, 48)
const INK := Color("090a14")
const PAPER := Color("e7d5b3")
const PAPER_DARK := Color("d7b594")
const RED := Color("a53030")
const GREEN := Color("468232")
const AMBER := Color("de9e41")
const ALARM := Color("cf573c")
const URGENT_SECONDS := 15.0

var table: int = -1
var dish: DishData
var phase: String = "waiting"
var cooked := false
var patience := 1.0  # fraction left
var urgent := false
var _time := 0.0


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	pivot_offset = Vector2(SIZE.x * 0.5, 0)  # swings from its clip


func set_order(table_index: int, order: Dictionary) -> void:
	table = table_index
	dish = order["dish"]
	phase = str(order.get("phase", "waiting"))
	cooked = bool(order.get("cooked", false))
	var left: float = float(order.get("patience", 0.0))
	patience = clampf(left / maxf(float(order.get("initial_patience", 38.0)), 0.001), 0.0, 1.0)
	urgent = phase != "eating" and not cooked and left < URGENT_SECONDS
	tooltip_text = "Bàn %d · %s" % [table + 1, dish.display_name]
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if urgent:
		queue_redraw()


func _draw() -> void:
	var shake := Vector2(roundf(sin(_time * 40.0)), 0) if urgent else Vector2.ZERO
	var paper := Rect2(Vector2(0, 4) + shake, Vector2(SIZE.x - 2.0, SIZE.y - 6.0))
	if not Art.draw(self, "ui/frames/ticket", paper):
		_paper(paper)
	var faded := phase == "eating"
	var ink := Color(INK, 0.5) if faded else INK
	var font := get_theme_font("font", "TitleLabel")
	draw_string(font, paper.position + Vector2(3, 11), str(table + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(RED, 0.5) if faded else RED)
	var badge := _badge_id()
	if badge != "":
		var tex := UiIcons.sticker(badge, 8, GREEN if badge == "check" else (AMBER if badge == "fire" else PAPER))
		if tex:
			draw_texture_rect(tex, Rect2(paper.position + Vector2(paper.size.x - 11, 2), Vector2(8, 8)), false)
	var picture: Texture2D = Art.texture("dishes/" + dish.id) if dish else null
	if picture == null:
		picture = UiIcons.sticker("meal", 16, PAPER_DARK)
	var pic := Rect2(paper.position + Vector2(4, 12), Vector2(20, 20))
	draw_texture_rect(picture, pic, false, Color(1, 1, 1, 0.45) if faded else Color.WHITE)
	if not faded:
		var bar := Rect2(paper.position + Vector2(3, 34), Vector2(paper.size.x - 6.0, 4))
		draw_rect(bar, ink)
		var fill_color := GREEN if patience > 0.5 else (AMBER if patience > 0.25 else ALARM)
		if cooked:
			fill_color = GREEN
		var inner := bar.grow(-1.0)
		draw_rect(Rect2(inner.position, Vector2(roundf(inner.size.x * (1.0 if cooked else patience)), inner.size.y)), fill_color)
	# Clip on the rail.
	draw_rect(Rect2(SIZE.x * 0.5 - 3.0, 0, 5, 7), INK)
	draw_rect(Rect2(SIZE.x * 0.5 - 2.0, 1, 3, 5), Color("819796"))


## Paper with a hard shadow, ink outline and a torn (zigzag) bottom.
func _paper(rect: Rect2) -> void:
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
	var x := rect.end.x
	var down := true
	while x > rect.position.x:
		points.append(Vector2(x, rect.end.y - (0.0 if down else 2.0)))
		x -= 2.0
		down = not down
	points.append(Vector2(rect.position.x, rect.end.y))
	var shadow := PackedVector2Array()
	for p in points:
		shadow.append(p + Vector2(2, 2))
	draw_colored_polygon(shadow, Color(INK, 0.55))
	draw_colored_polygon(points, PAPER)
	draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2.0, 1)), Color("ebede9"))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, INK, 1.0)


func _badge_id() -> String:
	if phase == "eating":
		return "meal"
	if cooked:
		return "check"
	if dish == null:
		return ""
	if dish.instant_serve:
		return "beer"
	return "fire" if dish.cook_type == DishData.CookType.GRILL else ""
