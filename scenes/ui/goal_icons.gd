class_name GoalIcons
extends RefCounted
## Icons for challenges / achievements. Final art is dropped in by file name
## (assets/sprites/ui/icons/<id>.png, like `Art`); until then a placeholder
## from tiny ASCII bitmaps ("#" = colour, "o" = dark outline). The one entry
## point is `icon(id)`.
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


## Square icon texture for `id`: the final art
## res://assets/sprites/ui/icons/<id>.png if it exists (via Art), else the
## placeholder (unknown ids get the star). List: docs/ui_art_needed_goals.md.
static func icon(id: String) -> Texture2D:
	var art := Art.texture("ui/icons/" + id)
	if art:
		return art
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


## Achievement badge: assets/sprites/ui/badges/<achievement_id>.png (24x24,
## full colour; locked = greyed in code) if it exists, else its icon.
static func badge(achievement_id: String, icon_id: String) -> Texture2D:
	var art := Art.texture("ui/badges/" + achievement_id)
	return art if art else icon(icon_id)


## TextureRect showing `id` at `px` pixels, nearest filtering.
static func rect(id: String, px: float) -> TextureRect:
	return show(icon(id), px)


## TextureRect for any texture at `px` pixels, nearest filtering.
static func show(texture: Texture2D, px: float) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.custom_minimum_size = Vector2(px, px)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view
