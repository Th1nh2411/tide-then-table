class_name GoalIcons
extends RefCounted
## Placeholder pixel icons for challenges / achievements, built from tiny
## ASCII bitmaps ("#" = colour, "o" = dark outline). The one entry point is
## `icon(id)`; swap its body for the shared icon set (UiIcons) later.
## Ids: money, clock, star, guest, fire, beer, fish, chili, check, lock,
## trophy, heart, tip.

const COLORS := {
	"money": Color("f2c94c"), "clock": Color("8fd3ff"), "star": Color("ffd84a"),
	"guest": Color("e9b48a"), "fire": Color("ff7a3a"), "beer": Color("f5b83d"),
	"fish": Color("7fc8e0"), "chili": Color("e8413a"), "check": Color("7be07b"),
	"lock": Color("a0a8b0"), "trophy": Color("f2d98a"), "heart": Color("ff6b8a"),
	"tip": Color("9be38a"),
}
const SHAPES := {
	"money": ["...oooooo...", "..o######o..", ".o##oooo##o.", "o##o####o##o", "o###oo###o#o", "o####oo####o",
		"o#o###o###o.", "o##o####o##o", ".o##oooo##o.", "..o######o..", "...oooooo...", "............"],
	"clock": ["...oooooo...", "..o######o..", ".o####o###o.", "o#####o####o", "o#####o####o", "o#####oooo#o",
		"o##########o", "o##########o", ".o########o.", "..o######o..", "...oooooo...", "............"],
	"star": [".....oo.....", ".....##.....", "....o##o....", "oooo####oooo", ".o########o.", "..o######o..",
		"...o####o...", "..o##oo##o..", "..o#o..o#o..", ".o#o....o#o.", ".oo......oo.", "............"],
	"guest": ["....oooo....", "...o####o...", "...o####o...", "...o####o...", "....oooo....", "..oo####oo..",
		".o########o.", "o##########o", "o##########o", "o##########o", "oooooooooooo", "............"],
	"fire": [".....o......", "....o#o.....", "....o##o....", "...o###o.o..", "..o####oo#o.", "..o#######o.",
		".o###oo###o.", ".o##o..o##o.", ".o##o..o##o.", "..o##oo##o..", "...oooooo...", "............"],
	"beer": ["..oooooo....", ".o......o...", ".oooooooooo.", ".o######o.o.", ".o######o..o", ".o######o..o",
		".o######o..o", ".o######o.o.", ".o######oo..", ".o######o...", ".oooooooo...", "............"],
	"fish": ["............", "....oooo....", "..oo####o..o", ".o#o#####oo#", "o#########o#", "o#########o#",
		".o#######oo#", "..oo####o..o", "....oooo....", "............", "............", "............"],
	"chili": ["........oo..", ".......o.o..", "......oooo..", ".....o###o..", "....o####o..", "...o####o...",
		"..o####o....", ".o####o.....", "o####o......", "o###o.......", ".ooo........", "............"],
	"check": ["............", "..........oo", ".........o#o", "........o#o.", "oo.....o#o..", "o#o...o#o...",
		".o#o.o#o....", "..o#o#o.....", "...o#o......", "....o.......", "............", "............"],
	"lock": ["....oooo....", "...o....o...", "..o......o..", "..o......o..", ".oooooooooo.", ".o########o.",
		".o###oo###o.", ".o###oo###o.", ".o####o###o.", ".o########o.", ".oooooooooo.", "............"],
	"trophy": ["oooooooooooo", "o#o######o#o", "o#o######o#o", ".oo######oo.", "..o######o..", "...o####o...",
		"....o##o....", ".....##.....", "....o##o....", "...o####o...", "...oooooo...", "............"],
	"heart": ["............", ".ooo...ooo..", "o###o.o###o.", "o####o####o.", "o#########o.", "o#########o.",
		".o#######o..", "..o#####o...", "...o###o....", "....o#o.....", ".....o......", "............"],
	"tip": ["...oooooo...", "..o######o..", ".o###oo###o.", "o###o##o###o", "o####oo####o", "o###o##o###o",
		".o###oo###o.", "..o######o..", "...oooooo...", ".....o#o....", "....o###o...", ".....ooo...."],
}

static var _cache: Dictionary = {}


## Square icon texture for `id` (unknown ids get the star).
static func icon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var shape: Array = SHAPES.get(id, SHAPES["star"])
	var color: Color = COLORS.get(id, COLORS["star"])
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	for y in shape.size():
		var row: String = shape[y]
		for x in row.length():
			if row[x] == "#":
				image.set_pixel(x, y, color)
			elif row[x] == "o":
				image.set_pixel(x, y, Color("1d1712"))
	var texture := ImageTexture.create_from_image(image)
	_cache[id] = texture
	return texture


## TextureRect showing `id` at `px` pixels, nearest filtering.
static func rect(id: String, px: float) -> TextureRect:
	var view := TextureRect.new()
	view.texture = icon(id)
	view.custom_minimum_size = Vector2(px, px)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view
