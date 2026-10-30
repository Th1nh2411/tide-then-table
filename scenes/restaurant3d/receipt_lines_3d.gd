class_name ReceiptLines3D
extends RefCounted
## Controls for the shift receipt's rows (ShiftReceiptRows specs): a line
## (icon, dotted leader, Paytone number in ink / red ink), two lines side by
## side, the challenges as stickers, a heading, a dashed rule, the 7-day chart.

const INK := Color("090a14")
const RED := Color("a53030")
const GREEN := Color("468232")


## One receipt row: a line (icon, dotted leader, number), two side by side,
## the day's challenges as stickers, a heading or a dashed rule.
static func row(spec: Dictionary) -> Control:
	var kind := str(spec.get("kind", "line"))
	if kind == "rule":
		var rule := Control.new()
		rule.custom_minimum_size = Vector2(0, 5)
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rule.draw.connect(func() -> void: _dashes(rule, 2.0, Color(INK, 0.6), 3.0))
		return rule
	if kind == "pair" or kind == "goals":
		var both := HBoxContainer.new()
		both.add_theme_constant_override("separation", 8 if kind == "pair" else 4)
		both.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for item: Dictionary in spec["items"]:
			var part := _line(item, "line" if kind == "pair" else "goal")
			part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			both.add_child(part)
		return both
	return _line(spec, kind)


static func _line(spec: Dictionary, kind: String) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 2)
	line.mouse_filter = Control.MOUSE_FILTER_PASS
	line.tooltip_text = str(spec.get("tip", ""))
	var texture: Texture2D = null
	if spec.has("badge"):
		texture = GoalIcons.badge(str(spec["badge"]), str(spec["goal_icon"]))
	elif spec.has("goal_icon"):
		texture = GoalIcons.icon(str(spec["goal_icon"]))
	var icon := GoalIcons.show(texture, 12) if texture else UiIcons.make(str(spec["icon"]), 12, spec.get("color", UiIcons.AMBER))
	icon.modulate.a = 0.45 if spec.get("dim", false) else 1.0
	line.add_child(icon)
	if kind == "head":
		var title := HudChips.number(13, true)
		title.text = str(spec["text"])
		line.add_child(title)
	if kind == "goal" and spec.get("done", false):
		line.add_child(UiIcons.make("check", 8, GREEN))
	var leader := Control.new()
	leader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader.custom_minimum_size.y = 12
	leader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	leader.draw.connect(func() -> void: _dashes(leader, leader.size.y - 3.0, Color(INK, 0.35), 2.0))
	line.add_child(leader)
	var value := HudChips.number(15 if kind == "total" else (9 if kind == "goal" else 11), true)
	value.text = str(spec.get("value_text", ""))
	if spec.get("red", false):
		value.add_theme_color_override("font_color", RED)
	elif spec.get("dim", false):
		value.add_theme_color_override("font_color", Color(INK, 0.5))
	line.add_child(value)
	line.set_meta("value", value)
	return line


static func chart(values: Array[float], days: Array[String]) -> MiniChart:
	var chart := MiniChart.new()
	chart.custom_minimum_size = Vector2(0, 30)
	chart.bar_color = Color("ad7757")
	chart.highlight_color = Color("cf573c")
	chart.label_color = Color(INK, 0.7)
	chart.font_size = 8
	chart.highlight = values.size() - 1
	chart.tooltip_text = "Thu 7 ngày gần nhất"
	chart.mouse_filter = Control.MOUSE_FILTER_PASS
	chart.set_meta("values", values)
	chart.set_meta("labels", days)
	return chart


static func _dashes(control: Control, y: float, color: Color, step: float) -> void:
	var x := 0.0
	while x < control.size.x:
		control.draw_rect(Rect2(roundf(x), roundf(y), 1, 1), color)
		x += step
