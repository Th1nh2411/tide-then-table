class_name NotebookSpread
extends Control
## The open notebook drawn as a landscape two-page spread (cheap school
## notebook: blue cover peeking out, ruled pages, red margin on the left of
## each page, a shadow in the fold). Each page is cut from notebook_page.png
## (a tall portrait spread): the top of a page joined to its bottom on a
## ruled line, so the ruling stays real and every page keeps both edges.
## Writing sits on those rules; `pages` / `spread` come from RinNotebook.

const HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const PAGE_ART: Texture2D = preload("res://assets/textures/horror/notebook_page.png")
const COVER_ART: Texture2D = preload("res://assets/textures/horror/notebook_cover.png")
## Source columns of the left page and of the right page (drawn mirrored so
## its margin is on the left too); the pencil in the fold is left out.
const LEFT_SRC := Vector2(4.0, 490.0)
const RIGHT_SRC := Vector2(538.0, 1015.0)
## Red margin line, as a fraction of each cut page's width.
const MARGIN := [68.5 / 486.0, 54.5 / 477.0]
## Top piece ends and bottom piece starts on a ruled line (source pixels).
const TOP_END := 316.5
const BOTTOM_FROM := 780.5
const SOURCE_TALL := 1400.0
## The ruled lines of the joined page (source pixels from its top).
const RULES: Array[float] = [111.5, 153.5, 194.5, 236.0, 276.0, 316.5, 358.5, 399.5, 441.5,
	483.5, 524.5, 566.5, 607.5, 649.0, 690.5, 731.0, 772.5, 814.5, 856.0]
const PENCIL := Color(0.2, 0.18, 0.2, 0.9)
const RED_PENCIL := Color(0.55, 0.15, 0.12, 0.92)

var pages: Array[Array] = []
var spread := 0


static func rows() -> int:
	return RULES.size()


## Joined page height in source pixels.
static func joined_tall() -> float:
	return TOP_END + SOURCE_TALL - BOTTOM_FROM


func page_size() -> Vector2:
	return Vector2(size.x * 0.5, size.y)


func rule_step() -> float:
	return (RULES[-1] - RULES[0]) / float(RULES.size() - 1) * size.y / joined_tall()


## Handwriting size for this ruling.
func font_size() -> int:
	return floori(rule_step() * 0.9)


## Writing column of a page: x from the page's left edge, width.
func writing_span(side: int) -> Vector2:
	var margin: float = MARGIN[side]
	var x := margin * page_size().x + 5.0
	return Vector2(x, page_size().x - x - 10.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var cover := Rect2(Vector2.ZERO, size).grow(6.0)
	draw_texture_rect_region(COVER_ART, cover, Rect2(150, 760, 760, 560))
	for side in 2:
		_draw_page(side)
	_draw_fold()
	for side in 2:
		var index := spread * 2 + side
		if index < pages.size():
			_write_page(side, pages[index], index)


func _draw_page(side: int) -> void:
	var page := page_size()
	var src: Vector2 = LEFT_SRC if side == 0 else RIGHT_SRC
	var scale_y := page.y / joined_tall()
	var top_h := TOP_END * scale_y
	if side == 1:  # mirrored: draw from the right edge leftwards
		draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect_region(PAGE_ART, Rect2(0, 0, page.x, top_h), Rect2(src.x, 0, src.y - src.x, TOP_END))
	draw_texture_rect_region(PAGE_ART, Rect2(0, top_h, page.x, page.y - top_h),
		Rect2(src.x, BOTTOM_FROM, src.y - src.x, SOURCE_TALL - BOTTOM_FROM))
	draw_set_transform(Vector2.ZERO)


## Shadow down the binding.
func _draw_fold() -> void:
	var mid := size.x * 0.5
	for i in 12:
		var shade := Color(0.08, 0.06, 0.04, 0.32 * (1.0 - i / 12.0))
		draw_rect(Rect2(mid - 1.0 - i, 0, 1, size.y), shade)
		draw_rect(Rect2(mid + i, 0, 1, size.y), shade)


func _rule_y(row: int) -> float:
	return RULES[row] * size.y / joined_tall()


func _write_page(side: int, rows_on_page: Array, index: int) -> void:
	var span := writing_span(side)
	var x := side * page_size().x + span.x
	var font_px := font_size()
	for i in rows_on_page.size():
		var row: Dictionary = rows_on_page[i]
		var text := str(row.get("text", ""))
		if text == "" or i >= RULES.size():
			continue
		var y := _rule_y(i) - rule_step() * 0.12
		var date := str(row.get("kind", "")) == "date"
		draw_string(HAND, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, span.y, font_px,
			RED_PENCIL if date else PENCIL)
		if date:  # underlined in red pencil, a little crooked
			var under := minf(HAND.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x, span.y)
			draw_line(Vector2(x, y + 2.0), Vector2(x + under, y + 1.4), Color(RED_PENCIL, 0.75), 0.8)
	if pages.size() > 2:
		var number := str(index + 1)
		# Page numbers in the outer bottom corners.
		var corner := Vector2(page_size().x * 0.06 if side == 0 else size.x - page_size().x * 0.08, size.y - 8.0)
		draw_string(HAND, corner, number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px - 2, PENCIL)
