class_name ChallengeCard3D
extends Control
## "Today's challenges" on the 3D restaurant HUD: a paper slip pinned under
## the right-hand buttons, a little crooked, a trophy sticker over its corner.
## Per challenge: its icon, a pencil-ink meter, "2/5" and a green check when
## done; the full sentence is the row's tooltip. Bounces on progress, flashes
## when done. RestaurantGoals3D feeds it; hidden while a cutscene, a full
## panel or the shift receipt is up.

const WIDTH := 100.0
const INK := Color("090a14")
const RED := Color("a53030")
const GREEN := Color("468232")
const BAR := Color("3c5e8b")

## () -> bool: hide now (cutscene / panel).
var hidden_when: Callable
var _panel: PanelContainer
var _rows: VBoxContainer
var _lines: Array[Dictionary] = []  # {"row", "icon", "bar", "count", "check", "progress", "done"}
var _shown := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(640.0 - WIDTH - 8.0, 58.0)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"PaperPanel"
	_panel.custom_minimum_size.x = WIDTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_rows)
	var gap := Control.new()  # room under the trophy sticker
	gap.custom_minimum_size.y = 4
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_child(gap)
	var head := UiIcons.make("trophy", 16, UiIcons.GOLD, RED)
	head.position = Vector2(-6, -8)
	head.rotation_degrees = -8.0
	head.tooltip_text = "Thử thách hôm nay"
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(head)
	var pin := Control.new()
	pin.position = Vector2(WIDTH * 0.5 - 3.0, -3.0)
	pin.size = Vector2(7, 7)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.draw.connect(func() -> void:
		pin.draw_rect(Rect2(1, 1, 6, 6), Color(INK, 0.5))
		pin.draw_rect(Rect2(0, 0, 6, 6), INK)
		pin.draw_rect(Rect2(1, 1, 4, 4), Color("cf573c"))
		pin.draw_rect(Rect2(1, 1, 2, 1), Color("ebede9")))
	add_child(pin)
	UiFx.tilt(self, 1.5)
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
	var bar: MeterBar = line["bar"]
	bar.set_value(float(progress) / maxf(float(target), 1.0))
	bar.color = GREEN if done else (Color("819796") if failed else BAR)
	count.text = ("%dk" % progress) if money else ("%d/%d" % [progress, target])
	count.add_theme_color_override("font_color", GREEN if done else (RED if failed else INK))
	(line["check"] as TextureRect).modulate.a = 1.0 if done else 0.0
	if done and not bool(line["done"]):
		UiFx.flash(line["row"] as Control, Color(1.5, 1.4, 0.8))
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
			UiFx.settle(self, Vector2(30, -10), 0.0, 8.0)
	elif not want and visible:
		hide()
	size = _panel.size


func _make_row(icon_id: String, words: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.tooltip_text = words
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	_rows.add_child(row)
	var icon := GoalIcons.rect(icon_id, 14)
	row.add_child(icon)
	var bar := MeterBar.new()
	bar.well = Color("d7b594")
	bar.low = 0.0
	bar.color = BAR
	bar.custom_minimum_size = Vector2(28, 5)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.set_value(0.0, true)
	row.add_child(bar)
	var count := HudChips.number(9, true)
	count.text = "0/0"
	count.custom_minimum_size.x = 22
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(count)
	var check := UiIcons.make("check", 8, GREEN)
	check.modulate.a = 0.0
	row.add_child(check)
	return {"row": row, "icon": icon, "bar": bar, "count": count, "check": check, "progress": 0, "done": false}
