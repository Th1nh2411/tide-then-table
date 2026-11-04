class_name HorrorUi
extends RefCounted
## Shared look of the horror build's menus (main menu, pause, settings):
## the same handwriting and dim off-white as the in-game prompt
## (InteractPrompt), on near-black glass, a faded lamp colour for focus /
## hover. No bright game-UI colours.

const HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const INK := InteractPrompt.INK
const DIM := Color(0.55, 0.53, 0.5)
const LAMP := Color(0.8, 0.62, 0.42)
const BLOOD := Color(0.72, 0.36, 0.32)
const GLASS := Color(0.02, 0.022, 0.03, 0.9)
const EDGE := Color(0.86, 0.83, 0.76, 0.1)


static func panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = GLASS
	box.border_color = EDGE
	box.set_border_width_all(1)
	box.set_content_margin_all(12)
	return box


## Text-only menu button: a thin lamp bar on the left when hovered / focused.
static func button(text: String, font_size: int = 13) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", HAND)
	b.add_theme_font_size_override("font_size", font_size + 2)
	for state: String in ["normal", "disabled"]:
		b.add_theme_stylebox_override(state, _flat(Color(0, 0, 0, 0), 0))
	for state: String in ["hover", "focus", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, _flat(Color(LAMP, 0.06), 1))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_focus_color", LAMP)
	b.add_theme_color_override("font_hover_color", LAMP)
	b.add_theme_color_override("font_pressed_color", LAMP)
	b.add_theme_color_override("font_hover_pressed_color", LAMP)
	b.add_theme_color_override("font_disabled_color", DIM)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	b.add_theme_constant_override("outline_size", 3)
	return b


static func label(text: String, font_size: int = 11, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", HAND)
	l.add_theme_font_size_override("font_size", font_size + 2)
	l.add_theme_color_override("font_color", color)
	return l


## Thin line slider with a small lamp-coloured knob.
static func slider(min_value: float, max_value: float, step: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_value
	s.max_value = max_value
	s.step = step
	s.custom_minimum_size = Vector2(110, 14)
	var track := _flat(Color(INK, 0.18), 0)
	track.content_margin_top = 1
	track.content_margin_bottom = 1
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", _flat(Color(LAMP, 0.6), 0))
	s.add_theme_stylebox_override("grabber_area_highlight", _flat(LAMP, 0))
	var knob := _knob(LAMP)
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", _knob(Color(1, 0.88, 0.6)))
	s.add_theme_icon_override("grabber_disabled", knob)
	return s


static func _flat(color: Color, left_border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = LAMP
	box.border_width_left = left_border
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box


static func _knob(color: Color) -> ImageTexture:
	var image := Image.create(6, 10, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)
