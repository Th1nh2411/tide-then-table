class_name HudChips
extends RefCounted
## Building blocks for the in-game HUDs (restaurant + sea): icon + big number
## chips (Paytone, ink outline), icon + MeterBar chips, a row on a material
## (wood plank / paper tag), and numbers that count up and bounce when they
## change. Icons are UiIcons stickers; the tooltip carries the words.

const INK := Color("090a14")


## Horizontal row on a theme material ("WoodPanel", "PaperPanel"...).
static func plank(variation: StringName, separation: int = 6) -> Array:
	var panel := PanelContainer.new()
	panel.theme_type_variation = variation
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	return [panel, row]


## Icon + number. Returns the number label (its parent is the chip).
## `ink`: dark text for paper, else cream with an outline for wood / night.
static func stat(parent: Control, id: String, icon_color: Color, tooltip: String,
		font_size: int = 11, ink: bool = false, icon_size: float = 12.0) -> Label:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 2)
	chip.tooltip_text = tooltip
	chip.mouse_filter = Control.MOUSE_FILTER_PASS if tooltip != "" else Control.MOUSE_FILTER_IGNORE
	parent.add_child(chip)
	chip.add_child(UiIcons.make(id, icon_size, icon_color))
	var label := number(font_size, ink)
	chip.add_child(label)
	return label


## Paytone number: cream + ink outline (night / wood) or ink on paper.
static func number(font_size: int = 11, ink: bool = false) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"TitleLabel"
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ink:
		label.add_theme_color_override("font_color", INK)
		label.add_theme_constant_override("outline_size", 0)
	else:
		label.add_theme_color_override("font_color", Color("ebede9"))
		label.add_theme_constant_override("outline_size", 3)
	return label


## Icon + meter (oil, hull, hold). Returns the MeterBar.
static func meter(parent: Control, id: String, icon_color: Color, tooltip: String,
		bar_color: Color, width: float = 30.0) -> MeterBar:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 2)
	chip.tooltip_text = tooltip
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(chip)
	chip.add_child(UiIcons.make(id, 12, icon_color))
	var bar := MeterBar.new()
	bar.color = bar_color
	bar.custom_minimum_size = Vector2(width, 6)
	chip.add_child(bar)
	return bar


## Shows `value` with `format`; counts from the old value and bounces when it
## changed (first call is instant).
static func show_number(label: Label, value: int, format: String = "%d") -> void:
	if not label.has_meta("hud_value"):
		label.set_meta("hud_value", value)
		label.text = format % value
		return
	var old: int = label.get_meta("hud_value")
	if old == value:
		return
	label.set_meta("hud_value", value)
	if label.has_meta("hud_tween"):
		var running: Tween = label.get_meta("hud_tween")
		if running and running.is_valid():
			running.kill()
	if not label.is_inside_tree():
		label.text = format % value
		return
	label.set_meta("hud_tween", UiFx.count_to(label, old, value, format, 0.5))
	UiFx.bounce(label.get_parent() as Control, 0.15)


## Thin vertical ink divider between chips on a plank.
static func divider(parent: Control, height: float = 12.0) -> void:
	var line := ColorRect.new()
	line.color = Color(INK, 0.55)
	line.custom_minimum_size = Vector2(1, height)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
