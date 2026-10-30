extends RefCounted
## Paints the placeholder nine-patch frames (assets/sprites/ui/frames/*.png)
## in the "Xóm Đèn" palette: square/stepped corners, 2 px ink outline, 1 px
## bevel, hard (2,2) shadow, a little grain. Only writes files that do not
## exist yet, so final art dropped in by file name is never overwritten.

const XAM1 := Color("090a14")
const XAM2 := Color("151d28")
const XAM3 := Color("202e37")
const XAM4 := Color("394a50")
const XAM5 := Color("577277")
const XAM6 := Color("819796")
const XAM7 := Color("c7cfcc")
const XAM8 := Color("ebede9")
const DAT2 := Color("7a4841")
const DAT3 := Color("ad7757")
const DAT4 := Color("c09473")
const DAT5 := Color("d7b594")
const DAT6 := Color("e7d5b3")
const NAU3 := Color("be772b")
const NAU4 := Color("de9e41")
const NAU5 := Color("e8c170")
const DO1 := Color("752438")
const DO2 := Color("a53030")
const SIGN := Color("e0302b")
const TUBE := Color("e6f6ff")
const LA1 := Color("25562e")
const BIEN1 := Color("172038")
const GOLD := Color("f2d98a")
const SHADOW := Color(0.035, 0.04, 0.08, 0.6)

## name -> [size, margin]; the builder reads margins from here too.
const FRAMES: Dictionary = {
	"board": [48, 8], "paper": [48, 8], "chalk": [64, 10], "wood": [48, 8],
	"sign": [32, 8], "cardboard": [48, 8], "phone": [40, 14], "strip": [48, 8],
	"btn_wood": [32, 6], "btn_wood_hover": [32, 6], "btn_wood_pressed": [32, 6], "btn_wood_disabled": [32, 6],
	"btn_sign": [32, 6], "btn_sign_hover": [32, 6], "btn_sign_pressed": [32, 6], "btn_sign_disabled": [32, 6],
	"btn_paper": [32, 6], "btn_paper_hover": [32, 6], "btn_paper_pressed": [32, 6], "btn_paper_disabled": [32, 6],
	"btn_chalk": [32, 6], "btn_chalk_hover": [32, 6],
	"keycap": [12, 4], "stamp": [12, 4],
	"receipt": [48, 8], "tag": [24, 6],
}

var _rng := RandomNumberGenerator.new()


func paint_all(dir: String) -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var written := 0
	for name: String in FRAMES:
		var path := dir + name + ".png"
		if FileAccess.file_exists(path):
			continue
		var spec: Array = FRAMES[name]
		var image := paint(name, int(spec[0]))
		image.save_png(ProjectSettings.globalize_path(path))
		written += 1
	return written


func paint(name: String, s: int) -> Image:
	_rng.seed = hash(name)
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var size := s
	match name:
		"board": _box(img, XAM2, XAM4, XAM1, XAM3, 0.025)
		"paper": _box(img, DAT6, XAM8, DAT5, DAT5, 0.05)
		"strip": _box(img, DAT6, XAM8, DAT5, DAT5, 0.03)
		"receipt":
			_box(img, XAM8, Color.WHITE, XAM7, XAM7, 0.03, 1)
			_zigzag(img)
		"tag": _box(img, NAU5, Color("f2d98a"), NAU4, NAU4, 0.04)  # HUD paper tag
		"wood":
			_box(img, DAT3, DAT4, DAT2, DAT2, 0.0)
			_grain_rows(img, DAT2, range(6, size - 6, 7))
		"cardboard":
			_box(img, DAT4, DAT5, DAT3, DAT3, 0.06)
			_line(img, 4, DAT3)  # box flap fold
		"sign":
			_box(img, SIGN, Color("ef6b5f"), DO1, DO2, 0.0)
			_inset_rect(img, 4, TUBE)  # tube light
		"chalk":
			_box(img, DAT2, DAT3, Color("4d2b32"), Color("4d2b32"), 0.0)
			_fill_inner(img, 6, LA1, Color(XAM7, 0.35), 0.012)
		"phone":
			# Thick dark bezel with a lighter rim, the screen inset 10 px.
			_box(img, XAM2, XAM5, XAM1, XAM3, 0.0)
			_inset_rect(img, 3, XAM3)
			_fill_inner(img, 10, BIEN1, BIEN1, 0.0)
		"keycap": _box(img, XAM3, XAM5, XAM1, XAM3, 0.0, 1)
		"stamp": _box(img, DO2, Color("cf573c"), DO1, DO1, 0.0, 1)
		_:
			_button(img, name)
	return img


func _button(img: Image, name: String) -> void:
	var pressed := name.ends_with("_pressed")
	var hover := name.ends_with("_hover")
	var disabled := name.ends_with("_disabled")
	if name.begins_with("btn_wood"):
		var fill := DAT4 if hover else (DAT2 if pressed else DAT3)
		_box(img, XAM4 if disabled else fill, XAM5 if disabled else NAU5 if hover else DAT4,
			XAM3 if disabled else DAT2, DAT2, 0.0, 2, not pressed, 2 if pressed else 0)
	elif name.begins_with("btn_sign"):
		var fill := Color("ef4a3c") if hover else (DO2 if pressed else SIGN)
		_box(img, XAM4 if disabled else fill, XAM5 if disabled else Color("f07a6e"),
			XAM3 if disabled else DO1, DO1, 0.0, 2, not pressed, 2 if pressed else 0)
	elif name.begins_with("btn_paper"):
		var fill := XAM8 if hover else (NAU5 if pressed else DAT6)
		_box(img, XAM6 if disabled else fill, XAM7 if disabled else XAM8,
			XAM5 if disabled else DAT5, DAT5, 0.025, 2, not pressed, 2 if pressed else 0)
	elif name.begins_with("btn_chalk"):
		# Chalk outline on transparent: dashed rectangle, gold when hovered.
		var c := GOLD if hover else Color(XAM7, 0.8)
		for i in img.get_width():
			if i % 3 != 2:
				for e: int in [1, img.get_height() - 2]:
					img.set_pixel(i, e, c)
					img.set_pixel(e, i, c)


## Body with 2 px outline (stepped corners), 1 px light bevel top/left,
## dark bevel bottom/right, hard shadow, optional grain.
func _box(img: Image, fill: Color, light: Color, dark: Color, grain: Color, grain_rate: float,
		outline: int = 2, shadow: bool = true, offset: int = 0) -> void:
	var s := img.get_width()
	var body := s - 2  # room for the (2,2) shadow
	if shadow:
		_rect(img, Rect2i(2, 2, body, body), SHADOW)
	var o := Vector2i(offset, offset)
	_rect(img, Rect2i(o, Vector2i(body, body)), XAM1)
	_rect(img, Rect2i(o + Vector2i(outline, outline), Vector2i(body - outline * 2, body - outline * 2)), fill)
	var a := outline
	var b := body - outline - 1
	for i in range(a, b + 1):
		img.set_pixelv(o + Vector2i(i, a), light)
		img.set_pixelv(o + Vector2i(a, i), light)
		img.set_pixelv(o + Vector2i(i, b), dark)
		img.set_pixelv(o + Vector2i(b, i), dark)
	# Stepped corners: knock out the outer corner pixel.
	for c: Vector2i in [Vector2i(0, 0), Vector2i(body - 1, 0), Vector2i(0, body - 1), Vector2i(body - 1, body - 1)]:
		img.set_pixelv(o + c, Color(0, 0, 0, 0))
	if grain_rate > 0.0:
		for y in range(a + 1, b):
			for x in range(a + 1, b):
				if _rng.randf() < grain_rate:
					img.set_pixelv(o + Vector2i(x, y), grain)


## Torn (zigzag) top and bottom edges: thermal receipt paper.
func _zigzag(img: Image) -> void:
	var s := img.get_width()
	for x in s:
		var tooth := x % 4 if x % 4 < 2 else 4 - x % 4
		for y in range(0, 2 - tooth + 1):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
		for y in range(s - 2 - (2 - tooth) - 1, s):
			img.set_pixel(x, y, Color(0, 0, 0, 0))


func _grain_rows(img: Image, color: Color, rows: Array) -> void:
	var s := img.get_width() - 2
	for y: int in rows:
		for x in range(3, s - 3):
			if _rng.randf() < 0.7:
				img.set_pixel(x, y, color)


func _line(img: Image, y: int, color: Color) -> void:
	for x in range(3, img.get_width() - 5):
		img.set_pixel(x, y, color)


func _inset_rect(img: Image, inset: int, color: Color) -> void:
	var e := img.get_width() - 2 - inset - 1
	for i in range(inset, e + 1):
		for p: Vector2i in [Vector2i(i, inset), Vector2i(inset, i), Vector2i(i, e), Vector2i(e, i)]:
			img.set_pixelv(p, color)


func _fill_inner(img: Image, inset: int, fill: Color, dust: Color, rate: float) -> void:
	var e := img.get_width() - 2 - inset
	_rect(img, Rect2i(inset - 1, inset - 1, e - inset + 2, e - inset + 2), XAM1)
	for y in range(inset, e):
		for x in range(inset, e):
			img.set_pixel(x, y, dust if _rng.randf() < rate else fill)


func _rect(img: Image, r: Rect2i, color: Color) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			img.set_pixel(x, y, color)
