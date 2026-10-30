class_name UiIcons
extends RefCounted
## Shared UI icon set. Final pixel art: `assets/sprites/ui/icons/<id>.png`
## (drop the file in, no code change; used as drawn). Until then the
## placeholder is a game-icons.net glyph (assets/icons/<id>.svg, credits in
## assets/icons/CREDITS.md) baked into a pixel sticker: solid colour
## silhouette at the exact pixel size + 1 px ink outline, optionally on a
## small coloured plate. `make("money", 14, GOLD)`.

const DIR := "res://assets/icons/"
const ART_DIR := "res://assets/sprites/ui/icons/"
const INK := Color("090a14")
const GOLD := Color("f2d98a")
const AMBER := Color("de9e41")
const CREAM := Color("e7d5b3")
const CHILI := Color("cf573c")
const RED := Color("a53030")
const SEA := Color("73bed3")
const CHALK := Color("ebede9")
const NONE := Color(0, 0, 0, 0)

static var _cache: Dictionary = {}


## Raw texture: final art PNG, else the placeholder SVG; null if unknown.
static func texture(id: String) -> Texture2D:
	var key := "raw|" + id
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	for path: String in [ART_DIR + id + ".png", DIR + id + ".svg"]:
		if ResourceLoader.exists(path):
			tex = load(path)
			break
	_cache[key] = tex
	return tex


static func is_pixel_art(id: String) -> bool:
	return ResourceLoader.exists(ART_DIR + id + ".png")


## The icon as a crisp `size` x `size` pixel sticker in `color` (final art is
## returned as is). `plate`: background tile colour, NONE for none.
static func sticker(id: String, size: int = 14, color: Color = CREAM, plate: Color = NONE) -> Texture2D:
	if is_pixel_art(id):
		return texture(id)
	var key := "%s|%d|%s|%s" % [id, size, color.to_html(), plate.to_html()]
	if _cache.has(key):
		return _cache[key]
	var raw := texture(id)
	var tex: Texture2D = null
	if raw:
		tex = ImageTexture.create_from_image(_bake(raw.get_image(), size, color, plate))
	_cache[key] = tex
	return tex


## Baked at 2x (one screen pixel at the game's x2 scale) so placeholder
## glyphs stay readable; the outline is 2 of those = 1 game pixel.
static func _bake(source: Image, size: int, color: Color, plate: Color) -> Image:
	var px := size * 2
	var glyph := source.duplicate() as Image
	if glyph.is_compressed():
		glyph.decompress()
	glyph.convert(Image.FORMAT_RGBA8)
	var inset := 4 if plate.a > 0.0 else 2
	var g := maxi(px - inset * 2, 4)
	while glyph.get_width() > g * 2:  # halve first: keeps thin strokes
		glyph.resize(glyph.get_width() / 2, glyph.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	glyph.resize(g, g, Image.INTERPOLATE_BILINEAR)
	var out := Image.create_empty(px, px, false, Image.FORMAT_RGBA8)
	if plate.a > 0.0:
		out.fill(INK)
		out.fill_rect(Rect2i(2, 2, px - 4, px - 4), plate)
	var solid := {}
	for y in g:
		for x in g:
			if glyph.get_pixel(x, y).a >= 0.45:
				solid[Vector2i(x + inset, y + inset)] = true
	for p: Vector2i in solid:
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var q := p + Vector2i(dx, dy)
				if absi(dx) + absi(dy) <= 3 and q.x >= 0 and q.y >= 0 and q.x < px and q.y < px \
						and not solid.has(q):
					out.set_pixelv(q, INK)
	for p: Vector2i in solid:
		out.set_pixelv(p, color)
	return out


## A sticker icon control (mouse passes through).
static func make(id: String, size: float = 14.0, color: Color = CREAM, plate: Color = NONE) -> TextureRect:
	var px := roundi(size)
	var rect := TextureRect.new()
	rect.texture = sticker(id, px, color, plate)
	rect.custom_minimum_size = Vector2(px, px)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect


## Icon + short text side by side ("money" + "70k").
static func pair(id: String, text: String, size: float = 12.0, color: Color = GOLD,
		variation: StringName = &"BoldLabel", font_size: int = 10) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(make(id, size, color))
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


## Puts a sticker icon on a button (the theme never tints button icons).
static func dress(button: Button, id: String, icon_size: int = 14, color: Color = CREAM) -> Button:
	button.icon = sticker(id, icon_size, color)
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", icon_size)  # textures are baked at 2x
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_constant_override("h_separation", 4)
	return button


## Icon-only button with a tooltip (settings, sound, quit, help).
static func icon_button(id: String, tooltip: String, icon_size: int = 16, color: Color = CREAM) -> Button:
	var button := Button.new()
	dress(button, id, icon_size, color)
	button.tooltip_text = tooltip
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(icon_size + 14, icon_size + 10)
	return button
