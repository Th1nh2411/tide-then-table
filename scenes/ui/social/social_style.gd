class_name SocialStyle
extends RefCounted
## Look of the "Xóm Đèn Review" phone app (PhoneReview, SocialMoment): a flat
## social app on Rin's phone, palette "Xóm Đèn" only, pixel-crisp frames
## (2 px dark outline, 1 px light bevel, hard (2,2) shadow, stepped corners).
## Frames are nine-patches: final art res://assets/sprites/ui/frames/<name>.png
## (via Art) if present; ids that have a project theme material use it
## (THEME_MATCH: paper card = "PaperPanel", red sticker = "BadgeLabel"
## stamp), the app-only ones (blue header, tabs, notification strip, avatar
## ring) are generated here.

const INK := Color("090a14")        # Xam 1
const NIGHT := Color("151d28")      # Xam 2
const MUTED := Color("577277")      # Xam 5
const GREY := Color("819796")       # Xam 6
const LIGHT := Color("ebede9")      # Xam 8
const PAPER := Color("e7d5b3")      # Dat da 6
const PAPER_DARK := Color("d7b594") # Dat da 5
const APP := Color("4f8fba")        # Xanh bien 4
const APP_DARK := Color("253a5e")   # Xanh bien 2
const SIGN_RED := Color("e0302b")   # Do bien hieu
const INK_RED := Color("a53030")    # Do 2
const GOLD := Color("f2d98a")       # Vang non la
const GLOW := Color("5ff2e0")       # Xanh ngoc phat sang
const TIER_COLORS: Array[Color] = [Color("ad7757"), Color("73bed3"), Color("de9e41"), Color("e0302b")]
## Frame ids -> [fill, bevel, has shadow, accent strip colour or transparent].
const FRAMES := {
	"social_card": [PAPER, LIGHT, true, Color(0, 0, 0, 0)],
	"social_notif": [PAPER, LIGHT, true, APP],
	"social_header": [APP, Color("73bed3"), false, Color(0, 0, 0, 0)],
	"rank_sticker": [SIGN_RED, Color("cf573c"), true, Color(0, 0, 0, 0)],
	"avatar_frame": [LIGHT, LIGHT, false, Color(0, 0, 0, 0)],
	"social_tab_on": [GOLD, LIGHT, true, Color(0, 0, 0, 0)],
	"social_tab_off": [Color("73bed3"), Color("a4dddb"), false, Color(0, 0, 0, 0)],
}
## Frame id -> [theme type, stylebox name] in assets/ui/game_theme.tres.
const THEME_MATCH := {
	"social_card": ["PaperPanel", "panel"],
	"rank_sticker": ["BadgeLabel", "normal"],
}
const SIZE := 16
const OUTLINE := 2
const SHADOW := 2

static var _textures: Dictionary = {}


## Nine-patch StyleBox for a frame id (see FRAMES), `pad` = content margin.
static func frame(id: String, pad: int = 4) -> StyleBoxTexture:
	var themed := _themed(id, pad)
	if themed:
		return themed
	var box := StyleBoxTexture.new()
	box.texture = frame_texture(id)
	var shadow: bool = FRAMES.get(id, FRAMES["social_card"])[2]
	box.texture_margin_left = 5 if id == "social_notif" else 4
	box.texture_margin_top = 4
	box.texture_margin_right = 4 + (SHADOW if shadow else 0)
	box.texture_margin_bottom = 4 + (SHADOW if shadow else 0)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.set_content_margin_all(pad)
	box.content_margin_right = pad + (SHADOW if shadow else 0)
	box.content_margin_bottom = pad + (SHADOW if shadow else 0)
	box.content_margin_left = pad + (3 if id == "social_notif" else 0)
	return box


## The project theme's material for `id` (no own art dropped in), else null.
static func _themed(id: String, pad: int) -> StyleBoxTexture:
	if not THEME_MATCH.has(id) or Art.texture("ui/frames/" + id) != null:
		return null
	var spec: Array = THEME_MATCH[id]
	var theme := ThemeDB.get_project_theme()
	if theme == null or not theme.has_stylebox(str(spec[1]), str(spec[0])):
		return null
	var box := theme.get_stylebox(str(spec[1]), str(spec[0])).duplicate() as StyleBoxTexture
	if box == null:
		return null
	box.set_content_margin_all(pad)
	box.content_margin_right = pad + SHADOW
	box.content_margin_bottom = pad + SHADOW
	return box


static func frame_texture(id: String) -> Texture2D:
	var art := Art.texture("ui/frames/" + id)
	if art:
		return art
	if not _textures.has(id):
		_textures[id] = ImageTexture.create_from_image(frame_image(id))
	return _textures[id]


## The placeholder nine-patch image (also written to disk by the art tool).
static func frame_image(id: String) -> Image:
	var spec: Array = FRAMES.get(id, FRAMES["social_card"])
	var fill: Color = spec[0]
	var bevel: Color = spec[1]
	var shadow: bool = spec[2]
	var strip: Color = spec[3]
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var box := SIZE - (SHADOW if shadow else 0)
	for y in SIZE:
		for x in SIZE:
			var color := Color(0, 0, 0, 0)
			if x < box and y < box:
				var edge := mini(mini(x, y), mini(box - 1 - x, box - 1 - y))
				var corner := (x == 0 or x == box - 1) and (y == 0 or y == box - 1)
				if corner:
					continue  # 1 px stepped corner
				if edge < OUTLINE:
					color = INK
				elif x == OUTLINE or y == OUTLINE:
					color = bevel
				else:
					color = fill
					if strip.a > 0.0 and x <= OUTLINE + 2:
						color = strip
					elif (x * 7 + y * 3) % 23 == 0:  # a little paper grain
						color = fill.darkened(0.06)
			elif shadow and x >= SHADOW and y >= SHADOW:
				color = INK
			image.set_pixel(x, y, color)
	return image


## Label in the phone's VT323 ("NeoLabel"), sizes as in PhoneApp.
static func label(text: String, px: int, color: Color = INK) -> Label:
	var view := Label.new()
	view.text = text
	view.theme_type_variation = &"NeoLabel"
	view.add_theme_font_size_override("font_size", roundi(px * PhoneApp.NEO_FONT_SCALE))
	view.add_theme_color_override("font_color", color)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


## Big chunky number (Paytone One "TitleLabel") with a dark outline.
static func number(text: String, px: int, color: Color = LIGHT) -> Label:
	var view := Label.new()
	view.text = text
	view.theme_type_variation = &"TitleLabel"
	view.add_theme_font_size_override("font_size", px)
	view.add_theme_color_override("font_color", color)
	view.add_theme_color_override("font_outline_color", INK)
	view.add_theme_constant_override("outline_size", 4)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


## Money as the game shows it: "70k".
static func money(k: int) -> String:
	return "%dk" % k
