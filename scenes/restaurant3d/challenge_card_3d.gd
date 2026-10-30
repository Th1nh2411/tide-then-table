class_name ChallengeCard3D
extends PanelContainer
## Small "today's challenges" card on the 3D restaurant HUD (top right, under
## the pinned buttons). Almost no text: a trophy header, then per challenge
## its icon + a thin progress bar + "2/5", a check icon when done; the full
## sentence is the row's tooltip. Bounces on progress, flashes gold when done.
## RestaurantGoals3D feeds it; hidden while a cutscene or a full panel is up.

const WIDTH := 96.0
const GOLD := Color("f2d98a")
const TEXT := Color("e9dfc5")
const FAILED := Color("c98a7a")
const BAR := Color("73bed3")

## () -> bool: hide now (cutscene / panel).
var hidden_when: Callable
var _rows: VBoxContainer
var _lines: Array[Dictionary] = []  # {"row", "bar", "count", "check", "progress", "done"}
var _shown := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = WIDTH
	position = Vector2(640.0 - WIDTH - 6.0, 32.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.15, 0.2, 0.86)
	style.border_color = Color("8a7a52")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(3)
	add_theme_stylebox_override("panel", style)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 2)
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rows)
	var head := GoalIcons.rect("trophy", 16)
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.tooltip_text = "Thử thách hôm nay"
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	_rows.add_child(head)
	hide()


## New list: one {"icon": id, "text": full sentence (tooltip)} per challenge.
func bind(entries: Array[Dictionary]) -> void:
	for line in _lines:
		(line["row"] as Control).queue_free()
	_lines.clear()
	for entry in entries:
		_lines.append(_make_row(str(entry["icon"]), str(entry["text"])))
	_shown = false


## Updates one line; animates when it moved forward or just finished.
## `money`: show "60k" style counts.
func set_line(index: int, progress: int, target: int, done: bool, failed: bool, money: bool = false) -> void:
	if index < 0 or index >= _lines.size():
		return
	var line: Dictionary = _lines[index]
	var count: Label = line["count"]
	var bar: ProgressBar = line["bar"]
	bar.max_value = target
	bar.value = progress
	count.text = ("%dk" % progress) if money else ("%d/%d" % [progress, target])
	var color := GOLD if done else (FAILED if failed else TEXT)
	count.add_theme_color_override("font_color", color)
	(bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = GOLD if done else (FAILED if failed else BAR)
	(line["check"] as TextureRect).modulate.a = 1.0 if done else 0.0
	if done and not bool(line["done"]):
		UiFx.flash(line["row"] as Control, Color(1.8, 1.5, 0.7))
		UiFx.pop_in(line["check"] as Control)
		Sfx.play("ok")
	elif progress > int(line["progress"]) and is_visible_in_tree():
		UiFx.bounce(line["icon"] as Control, 0.25)
	line["progress"] = progress
	line["done"] = done


func _process(_delta: float) -> void:
	var want: bool = not _lines.is_empty() and not (hidden_when.is_valid() and hidden_when.call())
	if want and not visible:
		show()
		if not _shown:
			_shown = true
			UiFx.slide_in(self, Vector2(40, 0))
	elif not want and visible:
		hide()


func _make_row(icon_id: String, words: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.tooltip_text = words
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	_rows.add_child(row)
	var icon := GoalIcons.rect(icon_id, 16)
	row.add_child(icon)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(30, 4)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = BAR
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.07, 0.1)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	row.add_child(bar)
	var count := Label.new()
	count.text = "0/0"
	count.custom_minimum_size.x = 22
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.add_theme_font_size_override("font_size", 8)
	count.add_theme_color_override("font_color", TEXT)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(count)
	var check := GoalIcons.rect("check", 8)
	check.modulate.a = 0.0
	row.add_child(check)
	return {"row": row, "icon": icon, "bar": bar, "count": count, "check": check, "progress": 0, "done": false}
