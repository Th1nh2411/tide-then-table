class_name DialoguePortrait
extends Control
## Big bust of whoever speaks in the DialogueBox (Nine Sols style), drawn in
## the bottom corner. Art: assets/sprites/portraits/<id>/<mood>.png, else
## <id>/base.png (square, facing right; the right-hand side mirrors it), else a
## placeholder bust in the speaker's colors. <id> is the speaker's name
## without accents ("Cô Năm" -> co_nam); the cat is "cat".
## Bobs while the line is typing, slides in when the speaker changes.

## id -> [skin, hair, shirt] for the placeholder.
const PALETTES := {
	"rin": [Color(0.93, 0.76, 0.6), Color(0.15, 0.13, 0.12), Color(0.3, 0.5, 0.75)],
	"bao": [Color(0.85, 0.66, 0.5), Color(0.1, 0.08, 0.08), Color(0.95, 0.95, 0.92)],
	"co_nam": [Color(0.9, 0.72, 0.58), Color(0.55, 0.55, 0.58), Color(0.45, 0.65, 0.45)],
	"vy": [Color(0.96, 0.8, 0.68), Color(0.2, 0.12, 0.1), Color(0.9, 0.55, 0.6)],
	"ong_tam": [Color(0.75, 0.55, 0.4), Color(0.85, 0.85, 0.85), Color(0.4, 0.38, 0.3)],
}
const ACCENTS := {
	"a": "àáảãạăằắẳẵặâầấẩẫậ", "e": "èéẻẽẹêềếểễệ", "i": "ìíỉĩị", "o": "òóỏõọôồốổỗộơờớởỡợ",
	"u": "ùúủũụưừứửữự", "y": "ỳýỷỹỵ", "d": "đ",
}

var id: String = ""
var mood: String = ""
## Drawn on the right side, mirrored.
var mirrored: bool = false
var talking: bool = false

var _time: float = 0.0
var _slide: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Enlarge approved 128px art by 2x; nearest sampling keeps pixels crisp.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## "Rin" + "vui" -> portraits/rin/vui.png (or rin/base.png, or the placeholder).
## While talking, an optional matching `<mood>_open.png` frame is shown.
func set_speaker(speaker_id: String, speaker_mood: String, on_right: bool) -> void:
	var changed := speaker_id != id or on_right != mirrored
	id = speaker_id
	mood = speaker_mood
	mirrored = on_right
	if changed:
		_slide = 1.0
	queue_redraw()


## "Cô Năm" -> "co_nam".
static func slug(speaker: String) -> String:
	var out := ""
	for ch in speaker.to_lower():
		var plain := ch
		for base: String in ACCENTS:
			if (ACCENTS[base] as String).contains(ch):
				plain = base
		if plain == " ":
			plain = "_"
		if plain.is_valid_identifier() or plain.is_valid_int():
			out += plain
	return out


func _closed_sprite() -> String:
	if mood != "" and Art.has("portraits/%s/%s" % [id, mood]):
		return "portraits/%s/%s" % [id, mood]
	return "portraits/%s/base" % id


func sprite() -> String:
	var closed := _closed_sprite()
	if talking and fmod(_time, 0.24) < 0.12:
		var open := closed + "_open"
		if Art.has(open):
			return open
	return closed


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var real := delta / maxf(Engine.time_scale, 0.01)  # cutscene slow-mo
	_time += real
	_slide = maxf(_slide - real * 7.0, 0.0)
	modulate.a = 1.0 - _slide
	queue_redraw()


func _draw() -> void:
	if id == "":
		return
	var side := -1.0 if mirrored else 1.0
	var bob := -1.0 if talking and fmod(_time, 0.24) < 0.12 else 0.0
	var shift := Vector2(-side * 28.0 * _slide, bob).round()
	var rect := Rect2(shift, size)
	if Art.draw(self, sprite(), rect, mirrored):
		return
	_draw_placeholder(rect, side)


func _draw_placeholder(rect: Rect2, side: float) -> void:
	var s := rect.size.x / 64.0  # designed on a 64 px grid
	var o := rect.position
	var p := func(x: float, y: float) -> Vector2:
		return o + Vector2((32.0 + (x - 32.0) * side) * s, y * s)
	if id == "cat":
		_draw_cat(p, s)
		return
	var colors: Array = PALETTES.get(id, [Color(0.9, 0.74, 0.6), Color(0.25, 0.2, 0.18),
		Color.from_hsv(float(hash(id) % 360) / 360.0, 0.45, 0.75)])
	var skin: Color = colors[0]
	var hair: Color = colors[1]
	var shirt: Color = colors[2]
	var outline := Color(0.08, 0.07, 0.1)
	# Shoulders.
	draw_colored_polygon(PackedVector2Array([p.call(6, 64), p.call(12, 46), p.call(24, 40),
		p.call(42, 40), p.call(54, 46), p.call(60, 64)]), outline)
	draw_colored_polygon(PackedVector2Array([p.call(8, 64), p.call(13, 47), p.call(25, 42),
		p.call(41, 42), p.call(53, 47), p.call(58, 64)]), shirt)
	draw_rect(Rect2(p.call(29 if side > 0 else 37, 34), Vector2(8, 9) * s), skin.darkened(0.15))  # neck
	# Head.
	var head: Vector2 = p.call(33, 24)
	draw_circle(head, 14.0 * s, outline)
	draw_circle(head, 13.0 * s, skin)
	draw_circle(p.call(31, 17), 13.0 * s, hair, true)  # hair cap, cut by the face below
	draw_circle(p.call(37, 27), 10.0 * s, skin)
	# Eye + mouth on the side facing the bubble.
	var blink := fmod(_time, 3.2) < 0.12
	var eye: Vector2 = p.call(42, 25)
	if blink:
		draw_rect(Rect2(eye - Vector2(1.5, 0) * s, Vector2(3, 1) * s), outline)
	else:
		draw_rect(Rect2(eye - Vector2(1, 2) * s, Vector2(2.5, 4) * s), outline)
	var mouth_open := talking and fmod(_time, 0.24) < 0.12
	draw_rect(Rect2(p.call(41 if side > 0 else 44, 32), Vector2(3, 2 if mouth_open else 1) * s), outline)
	if id == "rin":  # nón lá
		draw_colored_polygon(PackedVector2Array([p.call(10, 15), p.call(33, -2), p.call(56, 15)]), outline)
		draw_colored_polygon(PackedVector2Array([p.call(12, 14), p.call(33, 0), p.call(54, 14)]),
			Color(0.92, 0.82, 0.55))


func _draw_cat(p: Callable, s: float) -> void:
	var fur := Color(1.0, 0.75, 0.35)
	var outline := Color(0.08, 0.07, 0.1)
	draw_circle(p.call(32, 52), 20.0 * s, fur.darkened(0.1))
	draw_circle(p.call(34, 32), 15.0 * s, fur)
	draw_colored_polygon(PackedVector2Array([p.call(21, 24), p.call(22, 10), p.call(30, 19)]), fur)
	draw_colored_polygon(PackedVector2Array([p.call(38, 19), p.call(46, 10), p.call(47, 24)]), fur)
	var blink := fmod(_time, 2.7) < 0.12
	for x: float in [29.0, 40.0]:
		draw_rect(Rect2(p.call(x, 30), Vector2(2.5, 1 if blink else 4) * s), outline)
