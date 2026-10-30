extends SceneTree
## Builds assets/ui/game_theme.tres (project-wide theme, gui/theme/custom).
## Run:  Godot --headless --path . --script res://tools/ui/build_game_theme.gd
## First run paints missing placeholder frames into assets/sprites/ui/frames/
## (tools/ui/ui_frame_painter.gd); run `--import`, then run this again.
## Final art: replace a frames/<name>.png (same size + margins), re-run.
##
## Look: diegetic pixel materials from the night street (no rounded glass
## boxes): 2 px ink outline, 1 px bevel, hard (2,2) shadow, palette only.
## Fonts: Be Vietnam Pro (body), Paytone One (signs, big numbers: "TitleLabel"),
## VT323 (NEO / phone: "NeoLabel").
##
## Materials (theme_type_variation):
##   Panels (PanelContainer): default = dark board; "PaperPanel" (cream slip),
##     "ChalkPanel" (chalkboard in a wood frame: menu planning), "WoodPanel"
##     (hand-painted plank), "SignPanel" (red shop sign + tube light: main /
##     pause menu), "CardboardPanel" (Cô Năm's boxes), "PhoneScreen" (phone
##     bezel), "StripPanel" (paper strip: speech note), "RowPanel" = paper
##     note, "CardPanel" = paper.
##   Buttons: default = wood plank; "SignButton" / "AccentButton" (red sign,
##     main call to action), "PaperButton" (price tag), "ChalkButton" (chalk
##     outline), "ChipButton" (small tab: wood, paper when toggled),
##     "CardFace" (paper card you click), "CardEmpty" (chalk dashed slot).
##   Labels: "TitleLabel", "NeoLabel", "BoldLabel", "InkLabel" (dark ink on
##     paper), "CardLabel" (= ink, bold), "ChalkLabel", "PriceLabel" (red ink
##     number), "MutedLabel", "HeadingLabel" (red ink heading on paper),
##     "KeyLabel" (key cap), "BadgeLabel" (red stamp).

const OUT := "res://assets/ui/game_theme.tres"
const FRAMES_DIR := "res://assets/sprites/ui/frames/"
const Painter := preload("res://tools/ui/ui_frame_painter.gd")
const XAM1 := Color("090a14")
const XAM6 := Color("819796")
const XAM8 := Color("ebede9")
const CREAM := Color("e7d5b3")
const GOLD := Color("f2d98a")
const AMBER := Color("de9e41")
const DO2 := Color("a53030")
const TUBE := Color("e6f6ff")
const SEA := Color("73bed3")

var _theme := Theme.new()


func _init() -> void:
	var written := Painter.new().paint_all(FRAMES_DIR)
	if written > 0 or not ResourceLoader.exists(FRAMES_DIR + "board.png"):
		print("painted %d frames: run --import, then this script again" % written)
		quit()
		return
	var body := load("res://assets/fonts/BeVietnamPro-Medium.ttf") as FontFile
	var bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as FontFile
	var title := load("res://assets/fonts/PaytoneOne-Regular.ttf") as FontFile
	var neo := load("res://assets/fonts/VT323-Regular.ttf") as FontFile
	_theme.default_font = body
	_panels()
	_buttons(bold)
	_labels(body, bold, title, neo)
	_bars()
	var err := ResourceSaver.save(_theme, OUT)
	print("theme saved " + OUT if err == OK else "theme save failed %d" % err)
	quit()


func _panels() -> void:
	for type: String in ["Panel", "PanelContainer", "PopupPanel"]:
		_theme.set_stylebox("panel", type, frame("board", 10))
	var materials := {"PaperPanel": "paper", "ChalkPanel": "chalk", "WoodPanel": "wood",
		"SignPanel": "sign", "CardboardPanel": "cardboard", "PhoneScreen": "phone",
		"StripPanel": "strip", "RowPanel": "paper", "CardPanel": "paper"}
	for variation: String in materials:
		_theme.set_type_variation(variation, "PanelContainer")
		var pad := 12 if materials[variation] in ["chalk", "phone"] else 8
		_theme.set_stylebox("panel", variation, frame(str(materials[variation]), pad))
	_theme.set_stylebox("panel", "TooltipPanel", frame("paper", 6))


func _buttons(bold: Font) -> void:
	var looks := {"Button": "btn_wood", "OptionButton": "btn_wood", "MenuButton": "btn_wood",
		"SignButton": "btn_sign", "AccentButton": "btn_sign", "PaperButton": "btn_paper",
		"CardFace": "btn_paper", "ChalkButton": "btn_chalk", "CardEmpty": "btn_chalk",
		"ChipButton": "btn_wood"}
	for type: String in looks:
		if not type in ["Button", "OptionButton", "MenuButton"]:
			_theme.set_type_variation(type, "Button")
		var base := str(looks[type])
		var hover := base + "_hover"
		var pressed := base + "_pressed" if base != "btn_chalk" else base + "_hover"
		var disabled := base + "_disabled" if base != "btn_chalk" else base
		_theme.set_stylebox("normal", type, frame(base, 4))
		_theme.set_stylebox("hover", type, frame(hover, 4))
		_theme.set_stylebox("pressed", type, frame(pressed, 4, 2))
		_theme.set_stylebox("hover_pressed", type, frame(pressed, 4, 2))
		_theme.set_stylebox("disabled", type, frame(disabled, 4))
		_theme.set_stylebox("focus", type, StyleBoxEmpty.new())
		_theme.set_font("font", type, bold)
		var ink := type in ["PaperButton", "CardFace"]
		var text := XAM1 if ink else (TUBE if base == "btn_sign" else CREAM)
		_theme.set_color("font_color", type, text)
		_theme.set_color("font_focus_color", type, text)
		_theme.set_color("font_hover_color", type, XAM1 if ink else GOLD)
		_theme.set_color("font_pressed_color", type, XAM1 if ink else XAM8)
		_theme.set_color("font_hover_pressed_color", type, XAM1 if ink else XAM8)
		_theme.set_color("font_disabled_color", type, Color(XAM1, 0.5) if ink else XAM6)
		_theme.set_color("font_outline_color", type, XAM1)
		_theme.set_constant("outline_size", type, 0 if ink else 3)
		# Icons are baked pixel stickers (UiIcons): never tint them here.
		for state: String in ["normal", "focus", "hover", "pressed", "hover_pressed"]:
			_theme.set_color("icon_%s_color" % state, type, Color.WHITE)
		_theme.set_color("icon_disabled_color", type, Color(1, 1, 1, 0.45))
	# Toggled chip = a paper tab pulled up.
	_theme.set_stylebox("pressed", "ChipButton", frame("btn_paper", 4))
	_theme.set_stylebox("hover_pressed", "ChipButton", frame("btn_paper_hover", 4))
	_theme.set_color("font_pressed_color", "ChipButton", XAM1)
	_theme.set_color("font_hover_pressed_color", "ChipButton", XAM1)


func _labels(body: Font, bold: Font, title: Font, neo: Font) -> void:
	_theme.set_color("font_color", "Label", CREAM)
	_label("TitleLabel", title, GOLD, XAM1, 4)
	_label("NeoLabel", neo, SEA)
	_label("BoldLabel", bold, null)
	_label("InkLabel", body, XAM1)
	_label("CardLabel", bold, XAM1)
	_label("ChalkLabel", bold, XAM8)
	_label("PriceLabel", title, DO2, CREAM, 2)
	_label("MutedLabel", body, XAM6)
	_label("HeadingLabel", title, DO2)
	_label("KeyLabel", bold, CREAM, XAM1, 0)
	_theme.set_stylebox("normal", "KeyLabel", frame("keycap", 3, 0, 1))
	_label("BadgeLabel", title, XAM8, XAM1, 2)
	_theme.set_stylebox("normal", "BadgeLabel", frame("stamp", 4, 0, 1))
	_theme.set_font("font", "TooltipLabel", body)
	_theme.set_color("font_color", "TooltipLabel", XAM1)


func _label(variation: String, font: Font, color: Variant, outline: Variant = null, size: int = 0) -> void:
	_theme.set_type_variation(variation, "Label")
	_theme.set_font("font", variation, font)
	if color is Color:
		_theme.set_color("font_color", variation, color)
	if outline is Color:
		_theme.set_color("font_outline_color", variation, outline)
		_theme.set_constant("outline_size", variation, size)


## Flat crisp bars (no rounding): progress + scrollbars.
func _bars() -> void:
	var bg := _flat(Color("151d28"), XAM1, 1)
	var fill := _flat(AMBER, XAM1, 1)
	_theme.set_stylebox("background", "ProgressBar", bg)
	_theme.set_stylebox("fill", "ProgressBar", fill)
	for bar: String in ["VScrollBar", "HScrollBar"]:
		_theme.set_stylebox("scroll", bar, bg)
		_theme.set_stylebox("grabber", bar, fill)
		_theme.set_stylebox("grabber_highlight", bar, _flat(GOLD, XAM1, 1))
		_theme.set_stylebox("grabber_pressed", bar, _flat(GOLD, XAM1, 1))


## Nine-patch from frames/<name>.png; `pad` = content margin inside the art,
## `shift` moves the content (pressed buttons sink by 2 px).
func frame(name: String, pad: int, shift: int = 0, pad_y: int = -1) -> StyleBoxTexture:
	var spec: Array = Painter.FRAMES[name]
	var margin := int(spec[1])
	var box := StyleBoxTexture.new()
	box.texture = load(FRAMES_DIR + name + ".png")
	box.set_texture_margin_all(margin)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	var py := pad if pad_y < 0 else pad_y
	box.content_margin_left = pad + shift
	box.content_margin_top = py + shift
	box.content_margin_right = pad + 2 - shift  # +2: the baked shadow
	box.content_margin_bottom = py + 2 - shift
	return box


func _flat(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.anti_aliasing = false
	return box
