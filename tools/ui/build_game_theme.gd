extends SceneTree
## Builds assets/ui/game_theme.tres (project-wide theme, gui/theme/custom).
## Run: Godot --headless --path . --script res://tools/ui/build_game_theme.gd
## Fonts: Be Vietnam Pro (body), Paytone One (titles, signs, money: type
## variation "TitleLabel"), VT323 (NEO and the phone app: "NeoLabel").

const OUT := "res://assets/ui/game_theme.tres"
const NAVY := Color("1b2030")
const NAVY_LIGHT := Color("2b3247")
const CREAM := Color("e7d5b3")
const GOLD := Color("f2d98a")
const AMBER := Color("de9e41")
const CHILI := Color("cf573c")
const SEA := Color("73bed3")


func _init() -> void:
	var theme := Theme.new()
	var body := load("res://assets/fonts/BeVietnamPro-Medium.ttf") as FontFile
	var bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as FontFile
	var title := load("res://assets/fonts/PaytoneOne-Regular.ttf") as FontFile
	var neo := load("res://assets/fonts/VT323-Regular.ttf") as FontFile
	theme.default_font = body
	# Panels: dark navy card, warm amber rim, soft drop shadow.
	var panel := _box(Color(NAVY, 0.94), AMBER, 2, 8)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 4
	panel.shadow_offset = Vector2(0, 2)
	panel.set_content_margin_all(8)
	for type: String in ["Panel", "PanelContainer", "PopupPanel"]:
		theme.set_stylebox("panel", type, panel)
	# Buttons: amber outline; hover brightens to gold; pressed turns chili red.
	var normal := _box(NAVY_LIGHT, AMBER, 1, 6)
	var hover := _box(Color("3c4766"), GOLD, 2, 6)
	var pressed := _box(CHILI, GOLD, 2, 6)
	var disabled := _box(Color(NAVY_LIGHT, 0.5), Color(CREAM, 0.25), 1, 6)
	var focus := _box(Color(0, 0, 0, 0), GOLD, 1, 6)
	for box: StyleBoxFlat in [normal, hover, pressed, disabled]:
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 3
		box.content_margin_bottom = 3
	for type: String in ["Button", "OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", type, normal)
		theme.set_stylebox("hover", type, hover)
		theme.set_stylebox("pressed", type, pressed)
		theme.set_stylebox("hover_pressed", type, pressed)
		theme.set_stylebox("disabled", type, disabled)
		theme.set_stylebox("focus", type, focus)
		theme.set_font("font", type, bold)
		theme.set_color("font_color", type, CREAM)
		theme.set_color("font_hover_color", type, GOLD)
		theme.set_color("font_pressed_color", type, Color.WHITE)
		theme.set_color("font_disabled_color", type, Color(CREAM, 0.4))
	theme.set_color("font_color", "Label", CREAM)
	# Scrollbars / progress: thin, warm.
	var bar_bg := _box(Color(NAVY, 0.8), Color(AMBER, 0.6), 1, 4)
	var bar_fill := _box(AMBER, AMBER, 0, 4)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)
	theme.set_stylebox("grabber", "VScrollBar", bar_fill)
	theme.set_stylebox("scroll", "VScrollBar", bar_bg)
	# Tooltips.
	var tip := _box(Color(NAVY, 0.97), GOLD, 1, 4)
	tip.set_content_margin_all(5)
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_font("font", "TooltipLabel", body)
	theme.set_color("font_color", "TooltipLabel", CREAM)
	# Type variations used with `theme_type_variation`.
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", title)
	theme.set_color("font_color", "TitleLabel", GOLD)
	theme.set_color("font_outline_color", "TitleLabel", Color("3a1f1b"))
	theme.set_constant("outline_size", "TitleLabel", 4)
	theme.set_type_variation("NeoLabel", "Label")
	theme.set_font("font", "NeoLabel", neo)
	theme.set_color("font_color", "NeoLabel", SEA)
	theme.set_type_variation("BoldLabel", "Label")
	theme.set_font("font", "BoldLabel", bold)
	theme.set_type_variation("ChipButton", "Button")
	var chip := _box(Color(NAVY_LIGHT, 0.9), Color(AMBER, 0.7), 1, 10)
	chip.content_margin_left = 6
	chip.content_margin_right = 6
	theme.set_stylebox("normal", "ChipButton", chip)
	var err := ResourceSaver.save(theme, OUT)
	print("theme saved " + OUT if err == OK else "theme save failed %d" % err)
	quit()


func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box
