class_name RankChart
extends Control
## Weekly revenue bars (RivalRanking.week_board): one chunky pixel bar per
## eatery, logo + short name on the left, total at the bar's end; Rin's bar
## in sign red, rivals muted. `grow` (0..1) animates the bars; `play()`.
## Logos: assets/sprites/ui/rivals/<id>.png (12x12) else a coloured plate.

const ROW_H := 18.0
const GAP := 5.0
const LOGO := 12.0
const NAME_W := 66.0
const VALUE_W := 40.0

var board: Array[Dictionary] = []
var grow: float = 1.0:
	set(value):
		grow = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_board(entries: Array[Dictionary]) -> void:
	board = entries
	custom_minimum_size.y = entries.size() * (ROW_H + GAP)
	queue_redraw()


func play(delay: float = 0.0) -> void:
	grow = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "grow", 1.0, 0.7).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if board.is_empty():
		return
	var font := get_theme_font(&"font", &"NeoLabel")
	var font_px := roundi(7 * PhoneApp.NEO_FONT_SCALE)
	var top := 1
	for entry in board:
		top = maxi(top, int(entry["total"]))
	var bar_room := maxf(size.x - LOGO - NAME_W - VALUE_W - 8.0, 10.0)
	for i in board.size():
		var entry: Dictionary = board[i]
		var y := i * (ROW_H + GAP)
		var mine: bool = entry["player"]
		var color: Color = entry["color"]
		var logo := Rect2(0, y + 3, LOGO, LOGO)
		var art := Art.texture("ui/rivals/" + str(entry["id"]))
		draw_rect(Rect2(logo.position + Vector2(1, 1), logo.size), SocialStyle.INK)
		if art:
			draw_texture_rect(art, logo, false)
		else:
			draw_rect(logo, SocialStyle.INK)
			draw_rect(logo.grow(-1.0), color)
			draw_rect(Rect2(logo.position + Vector2(3, 3), Vector2(6, 2)), SocialStyle.LIGHT)  # awning stripe
			draw_rect(Rect2(logo.position + Vector2(4, 6), Vector2(4, 4)), SocialStyle.INK)  # door
		var name_color := SocialStyle.SIGN_RED if mine else SocialStyle.INK
		draw_string(font, Vector2(LOGO + 4.0, y + ROW_H - 5.0), str(entry["name"]), HORIZONTAL_ALIGNMENT_LEFT,
			NAME_W - 2.0, font_px, name_color)
		var width := roundf(bar_room * float(entry["total"]) / top * grow)
		var bar := Rect2(LOGO + NAME_W + 4.0, y + 2.0, maxf(width, 3.0), ROW_H - 4.0)
		draw_rect(Rect2(bar.position + Vector2(2, 2), bar.size), SocialStyle.INK)  # hard shadow
		draw_rect(bar, SocialStyle.INK)
		draw_rect(bar.grow(-1.0), color)
		draw_rect(Rect2(bar.position + Vector2(1, 1), Vector2(maxf(bar.size.x - 2.0, 0.0), 1)), color.lightened(0.3))
		var value := SocialStyle.money(roundi(float(entry["total"]) * grow))
		draw_string(font, Vector2(bar.end.x + 4.0, y + ROW_H - 5.0), value, HORIZONTAL_ALIGNMENT_LEFT, VALUE_W,
			font_px, name_color)
