extends RefCounted
## More placeholder materials for ui_frame_painter.gd (same rules: palette
## only, 2 px ink outline, hard shadow, a little grain), plus small stickers
## (pins, tape, the NEW! burst) written to assets/sprites/ui/stickers/.
## Only missing files are painted: final art dropped in by name wins.

const STICKERS_DIR := "res://assets/sprites/ui/stickers/"
const XAM1 := Color("090a14")
const XAM3 := Color("202e37")
const XAM4 := Color("394a50")
const XAM6 := Color("819796")
const XAM7 := Color("c7cfcc")
const XAM8 := Color("ebede9")
const DAT1 := Color("4d2b32")
const DAT2 := Color("7a4841")
const DAT3 := Color("ad7757")
const DAT4 := Color("c09473")
const DAT5 := Color("d7b594")
const DAT6 := Color("e7d5b3")
const NAU4 := Color("de9e41")
const NAU5 := Color("e8c170")
const DO1 := Color("752438")
const DO2 := Color("a53030")
const DO3 := Color("cf573c")
const BIEN5 := Color("73bed3")
const BIEN6 := Color("a4dddb")
const GOLD := Color("f2d98a")
const NONE := Color(0, 0, 0, 0)

## name -> [size, margin] (nine-patch frames in assets/sprites/ui/frames/).
const FRAMES: Dictionary = {
	"journal": [48, 8],    # narration: aged parchment strip, torn edges
	"crate": [48, 12],     # boat hold: wooden crate, wet dark inside
	"hold_slot": [20, 4],  # one wet wooden slot of the hold grid (drawn per cell)
	"notebook": [48, 10],  # rest card: Rin's notebook page
	"clipping": [48, 8],   # ending: newspaper clipping
	"app_card": [24, 6],   # phone app card (flat white, blue bevel)
}
## name -> size (stickers, not stretched).
const STICKERS: Dictionary = {
	"pin": Vector2i(9, 10), "tape": Vector2i(26, 10), "burst_new": Vector2i(64, 44),
}


static func paint(p: RefCounted, img: Image, name: String) -> bool:
	var s := img.get_width()
	match name:
		"journal":
			p.call("_box", img, DAT5, DAT6, DAT4, DAT4, 0.06)
			_ragged(img, p.get("_rng"), 3)
		"crate":
			p.call("_box", img, DAT2, DAT3, DAT1, DAT1, 0.0)
			p.call("_grain_rows", img, DAT1, [3, 44 - 3])
			for c: Vector2i in [Vector2i(4, 4), Vector2i(s - 7, 4), Vector2i(4, s - 7), Vector2i(s - 7, s - 7)]:
				img.set_pixelv(c, XAM7)  # nail heads
				img.set_pixelv(c + Vector2i.ONE, XAM4)
			p.call("_fill_inner", img, 9, XAM3, Color(BIEN5, 0.25), 0.02)
		"hold_slot":
			img.fill(XAM1)
			_fill(img, Rect2i(1, 1, s - 2, s - 2), DAT1)
			for x in range(1, s - 1):
				img.set_pixel(x, 1, DAT2)  # lit top edge
				if x % 5 != 0:
					img.set_pixel(x, 7, Color(XAM1, 0.35))  # plank grain
					img.set_pixel(x, 13, Color(XAM1, 0.35))
			img.set_pixel(3, 3, Color(BIEN6, 0.5))  # wet glint
			img.set_pixel(4, 3, Color(BIEN6, 0.3))
		"notebook":
			p.call("_box", img, DAT6, XAM8, DAT5, DAT5, 0.02)
			for y in range(12, s - 6, 5):
				for x in range(3, s - 5):
					img.set_pixel(x, y, Color(DAT4, 0.6))  # ruled lines
			for y in range(3, s - 5):
				img.set_pixel(8, y, Color(DO3, 0.7))  # red margin
			for x in range(5, s - 6, 6):
				img.set_pixel(x, 4, XAM6)  # spiral holes
				img.set_pixel(x + 1, 4, XAM6)
		"clipping":
			p.call("_box", img, DAT5, DAT6, DAT3, DAT3, 0.07)  # yellowed newsprint
			_ragged(img, p.get("_rng"), 2)
		"app_card":
			p.call("_box", img, XAM8, Color.WHITE, BIEN6, BIEN6, 0.0)
		_:
			return false
	return true


## Torn paper: knocks irregular bites out of the top and bottom rows.
static func _ragged(img: Image, rng: RandomNumberGenerator, depth: int) -> void:
	var s := img.get_width()
	for x in s:
		var top := rng.randi_range(0, depth)
		var bottom := rng.randi_range(0, depth)
		for y in top:
			img.set_pixel(x, y, NONE)
		for y in bottom:
			img.set_pixel(x, s - 3 - y, NONE)  # above the shadow rows


static func paint_stickers() -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STICKERS_DIR))
	var written := 0
	for name: String in STICKERS:
		var path := STICKERS_DIR + name + ".png"
		if FileAccess.file_exists(path):
			continue
		var size: Vector2i = STICKERS[name]
		var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		match name:
			"pin": _pin(img)
			"tape": _tape(img)
			"burst_new": _burst(img)
		img.save_png(ProjectSettings.globalize_path(path))
		written += 1
	return written


## Red push pin seen from the top: round head, ink outline, light spot.
static func _pin(img: Image) -> void:
	var c := Vector2(4.0, 4.0)
	for y in 9:
		for x in 9:
			var d := Vector2(x, y).distance_to(c)
			if d <= 4.2:
				img.set_pixel(x, y, XAM1 if d > 3.2 else DO3)
	img.set_pixel(3, 3, DAT6)
	img.set_pixel(4, 9, XAM1)  # needle shadow


## Strip of masking tape: translucent cream, zigzag ends.
static func _tape(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var cut := 1 if (y % 3 == 1) else 0
			if x >= cut and x < w - cut:
				img.set_pixel(x, y, Color(DAT6, 0.82) if (x + y * 3) % 11 else Color(DAT5, 0.85))


## Yellow starburst sticker with ink outline and a hard shadow.
static func _burst(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var c := Vector2(w * 0.5 - 1.0, h * 0.5 - 1.0)
	var radius := Vector2(w * 0.5 - 2.0, h * 0.5 - 2.0)
	# shadow, ink outline, gold body (smaller)
	for layer: Array in [[Vector2(2, 2), 0.0, Color(XAM1, 0.6)], [Vector2.ZERO, 0.0, XAM1], [Vector2.ZERO, 0.12, GOLD]]:
		var offset: Vector2 = layer[0]
		var inset: float = layer[1]
		var color: Color = layer[2]
		for y in h:
			for x in w:
				var v := (Vector2(x, y) - c - offset) / radius
				var edge := 0.78 + 0.22 * absf(sin(v.angle() * 6.0))
				if v.length() <= edge - inset:
					img.set_pixel(x, y, color)
	img.set_pixel(int(c.x) - 12, int(c.y) - 9, XAM8)  # glint
	img.set_pixel(int(c.x) - 11, int(c.y) - 9, XAM8)


static func _fill(img: Image, r: Rect2i, color: Color) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			img.set_pixel(x, y, color)

