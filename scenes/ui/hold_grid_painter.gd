class_name HoldGridPainter
extends RefCounted
## Drawing for HoldGridView (the boat hold): wet wooden slots
## (frames/hold_slot.png), the "new fish" tray as a chalk-dashed basket,
## the discard zone as a red plate with a bin icon, the sell zone (lobster
## raft) as a green plate with a coin and the price, NEW stickers on fish.
## Icons are UiIcons stickers; no words except numbers.

const INK := Color("090a14")
const CHALK := Color("ebede9")
const SLOT := Color("4d2b32")
const TRAY := Color("151d28")
const TRASH := Color("752438")
const SELL := Color("25562e")
const SELL_LIGHT := Color("468232")
const GOLD := Color("f2d98a")


static func cells(view: Control, grid: Vector2i, cell: int) -> void:
	var slot := UiStickers.texture("hold_slot")
	for y in grid.y:
		for x in grid.x:
			var r := Rect2(Vector2(x, y) * cell, Vector2.ONE * cell)
			if slot:
				view.draw_texture_rect(slot, r, false)
			else:
				view.draw_rect(r, SLOT)
				view.draw_rect(r, Color(INK, 0.6), false, 1.0)


## Tray for a fish that didn't fit: dashed chalk outline, a faint fish icon
## when empty; lit (gold dashes, bob) while a fish waits in it.
static func tray(view: Control, r: Rect2, waiting: bool, time: float) -> void:
	view.draw_rect(r, Color(TRAY, 0.85 if waiting else 0.45))
	var dash := GOLD if waiting else Color(CHALK, 0.35)
	dashed_rect(view, r.grow(-1.0), dash)
	if not waiting:
		var icon := UiIcons.sticker("fish", 14, Color(CHALK, 0.3))
		if icon:
			view.draw_texture_rect(icon, Rect2(r.get_center() - Vector2(7, 7), Vector2(14, 14)), false)
		return
	var bob := roundf(sin(time * 5.0) * 1.5)
	var spark := UiIcons.sticker("sparkles", 10, GOLD)
	if spark:
		view.draw_texture_rect(spark, Rect2(r.position + Vector2(r.size.x - 8, -6 + bob), Vector2(10, 10)), false)


## Discard ("Bỏ") or sell ("Bán") plate: icon + price while a fish is held.
static func zone(view: Control, r: Rect2, selling: bool, price: int, hot: bool) -> void:
	var fill := (SELL_LIGHT if hot else SELL) if selling else (Color("a53030") if hot else TRASH)
	view.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(INK, 0.6))  # hard shadow
	view.draw_rect(r, INK)
	view.draw_rect(r.grow(-2.0), fill)
	view.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 1)), fill.lightened(0.25))
	var id := "money" if selling else "trash"
	var icon := UiIcons.sticker(id, 16, GOLD if selling else CHALK)
	var font := view.get_theme_font(&"font", &"TitleLabel")
	var text := "%dk" % price if selling and price >= 0 else ""
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x if text != "" else 0.0
	var start := r.get_center().x - (16.0 + (text_w + 2.0 if text != "" else 0.0)) * 0.5
	if icon:
		view.draw_texture_rect(icon, Rect2(Vector2(start, r.get_center().y - 8), Vector2(16, 16)), false)
	if text != "":
		var at := Vector2(start + 18, r.get_center().y + 4)
		view.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, INK)
		view.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GOLD)


## Small gold "NEW" sticker in the corner of a fish's first cell.
static func new_tag(view: Control, origin: Vector2, cell: int, alpha: float) -> void:
	var tag := Rect2(origin + Vector2(1, cell - 9), Vector2(19, 8))
	view.draw_rect(tag, Color(INK, alpha))
	view.draw_rect(tag.grow(-1.0), Color(GOLD, alpha))
	var font := view.get_theme_font(&"font", &"TitleLabel")
	view.draw_string(font, tag.position + Vector2(2, 7), "NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(Color("a53030"), alpha))


static func dashed_rect(view: Control, r: Rect2, color: Color) -> void:
	var x := r.position.x
	while x < r.end.x:
		var w := minf(3.0, r.end.x - x)
		view.draw_rect(Rect2(x, r.position.y, w, 1), color)
		view.draw_rect(Rect2(x, r.end.y - 1, w, 1), color)
		x += 5.0
	var y := r.position.y
	while y < r.end.y:
		var h := minf(3.0, r.end.y - y)
		view.draw_rect(Rect2(r.position.x, y, 1, h), color)
		view.draw_rect(Rect2(r.end.x - 1, y, 1, h), color)
		y += 5.0
