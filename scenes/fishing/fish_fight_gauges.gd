class_name FishFightGauges
extends RefCounted
## The fishing screen's readouts as things on a wooden plank (bottom left):
## a reel that fills as the fish comes up with the line tension around it,
## a spirit level for the boat's balance and Rin's daze; the all-in wheel
## is a carved disc (bottom right). Art: "fishing/reel" (32x32),
## "fishing/wheel" (72x72, the disc under the coloured slices).

const INK := Color("090a14")
const CREAM := Color("e7d5b3")
const PLANK := Vector2(222, 44)


static func plank_rect(size: Vector2) -> Rect2:
	return Rect2(Vector2(8, size.y - PLANK.y - 6), PLANK)


static func wheel_center(size: Vector2) -> Vector2:
	return Vector2(size.x - 54.0, size.y - 74.0)


static func draw(canvas: Control, game: FishFightGame, size: Vector2) -> void:
	var plank := plank_rect(size)
	var box := canvas.get_theme_stylebox(&"panel", &"WoodPanel")
	if box:
		canvas.draw_style_box(box, plank)
	else:
		canvas.draw_rect(plank, Color("7a4841"))
		canvas.draw_rect(plank, INK, false, 2.0)
	var reel := plank.position + Vector2(24, plank.size.y * 0.5)
	_draw_reel(canvas, game, reel)
	_draw_balance(canvas, game, Rect2(plank.position + Vector2(48, 9), Vector2(164, 7)))
	_bar(canvas, Rect2(plank.position + Vector2(48, 26), Vector2(164, 7)), game.stun, Color("c65197"), "wave")
	if game.hooked_index >= 0:
		_draw_wheel(canvas, game, wheel_center(size))


## Reel: fills with the fish's colour as it comes up; the ring is the tension.
static func _draw_reel(canvas: Control, game: FishFightGame, center: Vector2) -> void:
	var tension_color := Color("de9e41").lerp(Color("e0302b"), clampf((game.tension - 0.5) * 2.0, 0.0, 1.0))
	canvas.draw_arc(center, 17.0, 0.0, TAU, 40, INK, 4.0)
	canvas.draw_arc(center, 17.0, -PI * 0.5, -PI * 0.5 + TAU * game.tension, 40, tension_color, 2.0)
	if not Art.draw(canvas, "fishing/reel", Rect2(center - Vector2(16, 16), Vector2(32, 32))):
		canvas.draw_circle(center, 13.0, INK)
		canvas.draw_circle(center, 12.0, Color("394a50"))
	if game.progress >= 0.99:
		canvas.draw_circle(center, 10.0, game._tint(game.fish.color))
	elif game.progress > 0.01:
		var points := PackedVector2Array([center])
		var steps := maxi(3, roundi(24 * game.progress))
		for i in steps + 1:
			points.append(center + Vector2.UP.rotated(TAU * game.progress * i / steps) * 10.0)
		canvas.draw_colored_polygon(points, game._tint(game.fish.color))
	var crank := Vector2.UP.rotated(game.progress * TAU * 5.0) * 9.0
	canvas.draw_line(center, center + crank, CREAM, 2.0)
	canvas.draw_circle(center + crank, 2.5, Color("884b2b"))
	canvas.draw_circle(center, 2.0, CREAM)


## Spirit level: the bubble drifts off-centre as the boat tips.
static func _draw_balance(canvas: Control, game: FishFightGame, rect: Rect2) -> void:
	var track := _track(canvas, rect, "boat")
	var center_x := track.position.x + track.size.x * 0.5
	canvas.draw_rect(Rect2(center_x - 1, track.position.y, 2, track.size.y), Color(1, 1, 1, 0.35))
	var danger := absf(game.balance) >= 0.8
	canvas.draw_circle(Vector2(center_x + game.balance * track.size.x * 0.47, track.position.y + track.size.y * 0.5), 3.0,
		Color("e0302b") if danger else Color("a8ca58"))


static func _bar(canvas: Control, rect: Rect2, value: float, color: Color, icon_id: String) -> void:
	var track := _track(canvas, rect, icon_id)
	var fill := Rect2(track.position, Vector2(roundf(track.size.x * clampf(value, 0.0, 1.0)), track.size.y))
	canvas.draw_rect(fill, color)
	canvas.draw_rect(Rect2(fill.position, Vector2(fill.size.x, 1)), color.lightened(0.3))


## Icon sticker on the left, then an ink-outlined dark track; returns the track.
static func _track(canvas: Control, rect: Rect2, icon_id: String) -> Rect2:
	var icon := UiIcons.sticker(icon_id, 12, CREAM)
	if icon:
		canvas.draw_texture_rect(icon, Rect2(rect.position + Vector2(0, rect.size.y * 0.5 - 6), Vector2(12, 12)), false)
	var track := Rect2(rect.position + Vector2(16, 0), Vector2(rect.size.x - 16, rect.size.y))
	canvas.draw_rect(track.grow(1.0), INK)
	canvas.draw_rect(track, Color("151d28"))
	return track


static func _draw_wheel(canvas: Control, game: FishFightGame, center: Vector2) -> void:
	var radius := 30.0
	var start := -PI * 0.5
	var green := game.yank_green_chance()
	var yellow := game.yank_yellow_chance()
	if not Art.draw(canvas, "fishing/wheel", Rect2(center - Vector2(36, 36), Vector2(72, 72))):
		canvas.draw_circle(center, radius + 6.0, INK)
		canvas.draw_circle(center, radius + 4.0, Color("884b2b"))
		canvas.draw_arc(center, radius + 4.0, PI, PI * 1.6, 12, Color("ad7757"), 1.0)
	canvas.draw_arc(center, radius - 2.0, start, start + TAU, 64, Color("a53030"), 8.0, true)
	if game.hooked_index >= 0:
		canvas.draw_arc(center, radius - 2.0, start + TAU * green, start + TAU * (green + yellow), 24,
			Color("de9e41"), 8.0, true)
		canvas.draw_arc(center, radius - 2.0, start, start + TAU * green, maxi(3, roundi(64.0 * green)),
			Color("a8ca58"), 8.0, true)
	canvas.draw_circle(center, radius - 7.0, Color("4d2b32"))
	var tip := center + Vector2.RIGHT.rotated(game._pointer_angle) * (radius + 1.0)
	canvas.draw_line(center, tip, Color("ebede9"), 2.0, true)
	canvas.draw_circle(center, 3.0, Color("ebede9"))
	var font := canvas.get_theme_font(&"font", &"TitleLabel")
	var words := "%d%%" % roundi(green * 100.0)
	canvas.draw_string_outline(font, center + Vector2(-14, 4), words, HORIZONTAL_ALIGNMENT_CENTER, 28.0, 9, 3, INK)
	canvas.draw_string(font, center + Vector2(-14, 4), words, HORIZONTAL_ALIGNMENT_CENTER, 28.0, 9, Color("ebede9"))
	# "E" key cap under the wheel: spin it all-in.
	var cap := Rect2(center + Vector2(-6, radius + 9), Vector2(12, 11))
	var key_box := canvas.get_theme_stylebox(&"normal", &"KeyLabel")
	if key_box:
		canvas.draw_style_box(key_box, cap)
	canvas.draw_string(font, cap.position + Vector2(3, 9), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, CREAM)
