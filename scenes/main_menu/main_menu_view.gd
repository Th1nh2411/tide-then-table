class_name MainMenuView
extends RefCounted
## Builds the main menu's nodes: key art + lamp glow, a dark wash over the
## left third, "RIN" + subtitle, the button column, a small build note.

const KEYART := preload("res://assets/textures/horror/title_keyart.png")
const TITLE_FONT := preload("res://assets/fonts/BeVietnamPro-Bold.ttf")
const SUBTITLE: String = "Tháng Bảy ở Xóm Đèn"
const BUILD_NOTE: String = "bản chơi thử"


static func build(menu: Control) -> void:
	var art := TextureRect.new()
	art.texture = KEYART
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(art)
	var lamp := TextureRect.new()
	lamp.texture = _glow()
	lamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	lamp.material = add
	lamp.self_modulate = Color(1.0, 0.62, 0.25)
	art.add_child(lamp)
	menu.add_child(_left_wash())
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	column.offset_left = 40
	column.offset_top = 70
	column.offset_right = 230
	column.offset_bottom = -20
	column.add_theme_constant_override("separation", 0)
	menu.add_child(column)
	var title := HorrorUi.label("RIN", 64, Color(0.88, 0.85, 0.78))
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_constant_override("line_spacing", -12)
	column.add_child(title)
	var subtitle := HorrorUi.label(SUBTITLE, 13, Color(0.78, 0.62, 0.45))
	column.add_child(subtitle)
	var gap := Control.new()
	gap.custom_minimum_size.y = 34
	column.add_child(gap)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 2)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(buttons)
	var status := HorrorUi.label("", 10, HorrorUi.BLOOD)
	status.custom_minimum_size.x = 150
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var note := HorrorUi.label(BUILD_NOTE, 8, Color(HorrorUi.DIM, 0.6))
	note.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	note.offset_top = -18
	note.offset_bottom = -6
	note.offset_left = 12
	menu.add_child(note)
	menu.call("set_parts", art, lamp, title, subtitle, buttons, status)


## Black from the left edge fading out by ~45% of the width: keeps the text readable.
static func _left_wash() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.75))
	gradient.set_color(1, Color(0, 0, 0, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	tex.width = 64
	tex.height = 4
	var wash := TextureRect.new()
	wash.texture = tex
	wash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash.stretch_mode = TextureRect.STRETCH_SCALE
	wash.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	wash.anchor_right = 0.45
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return wash


static func _glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.9))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.25, Color(1, 1, 1, 0.35))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex
