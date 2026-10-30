class_name ShiftReceipt3D
extends Control
## End-of-shift scoreboard as a till receipt (hoá đơn): the paper rises out of
## the cash register line by line (icon + dotted leader + number), earnings
## count up, a 7-day earnings chart prints last, then the red star stamp slams
## on with a small shake. Not modal (Rin keeps walking); the register's
## button closes it. Rows come from ShiftReceiptRows (pure), their controls
## from ReceiptLines3D.

signal closed

const WIDTH := 172.0
const SLOT_Y := 294.0  # top of the register body
const STAMP_ZONE := 40.0  # blank foot of the paper where the stamp lands
const LINE_SECONDS := 0.16
const INK := Color("090a14")

## Full text version (tooltip, and for tests / logs).
var summary_text: Label
var printing := false
var _paper: PanelContainer
var _lines: VBoxContainer
var _register: Control
var _stamp: RatingStamp
var _close: Button
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(8, 0)  # left edge, clear of the tables
	size = Vector2(WIDTH + 24.0, SLOT_Y + 24.0)
	_paper = PanelContainer.new()
	_paper.theme_type_variation = &"ReceiptPanel"
	_paper.mouse_filter = Control.MOUSE_FILTER_PASS
	_paper.custom_minimum_size.x = WIDTH
	# The column keeps the paper's bottom on the register slot: it grows upward.
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.position = Vector2(12, 0)
	column.size = Vector2(WIDTH, SLOT_Y)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	column.add_child(_paper)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 1)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.add_child(_lines)
	_register = Control.new()
	_register.position = Vector2(0, SLOT_Y - 2.0)
	_register.size = Vector2(WIDTH + 24.0, 22)
	_register.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_register.draw.connect(_draw_register)
	add_child(_register)
	_close = UiIcons.icon_button("check", "Đóng", 12, UiIcons.CREAM)
	_close.theme_type_variation = &"SignButton"
	_close.focus_mode = Control.FOCUS_NONE
	_close.custom_minimum_size = Vector2(28, 20)
	_close.position = Vector2(WIDTH - 14.0, SLOT_Y + 1.0)
	_close.pressed.connect(close)
	add_child(_close)
	_stamp = RatingStamp.new()
	_stamp.hide()
	add_child(_stamp)
	summary_text = Label.new()
	summary_text.visible = false
	add_child(summary_text)
	hide()


## Prints the receipt. `rows` from ShiftReceiptRows.build; `chart` = recent
## days' earnings (last = today); `stars` for the stamp.
func open(words: String, rows: Array[Dictionary], chart: Array[float], chart_days: Array[String], stars: int) -> void:
	summary_text.text = words
	_paper.tooltip_text = words
	for child in _lines.get_children():
		child.queue_free()
	var rows_built: Array[Control] = []
	for row in rows:
		var view := ReceiptLines3D.row(row)
		view.hide()
		_lines.add_child(view)
		rows_built.append(view)
	var graph := ReceiptLines3D.chart(chart, chart_days)
	graph.hide()
	_lines.add_child(graph)
	rows_built.append(graph)
	var zone := Control.new()
	zone.custom_minimum_size.y = STAMP_ZONE
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.hide()
	_lines.add_child(zone)
	rows_built.append(zone)
	_stamp.hide()
	_stamp.set_stars(stars)
	show()
	printing = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_interval(0.25)
	for i in rows_built.size():
		_tween.tween_callback(_print_line.bind(rows_built[i], rows[i] if i < rows.size() else {}))
		_tween.tween_interval(LINE_SECONDS if i < rows.size() else 0.35)
	_tween.tween_callback(_slam)


func close() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	printing = false
	hide()
	closed.emit()


## Skips the printing (tests, impatient players clicking the paper).
func finish_now() -> void:
	if not printing:
		return
	_tween.kill()
	for child in _lines.get_children():
		var line := child as Control
		line.show()
		line.modulate.a = 1.0
		if line is MiniChart:
			(line as MiniChart).set_values(line.get_meta("values"), line.get_meta("labels"))
	_slam()


func _print_line(view: Control, row: Dictionary) -> void:
	view.show()
	view.modulate.a = 0.0
	var fade := view.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(view, "modulate:a", 1.0, 0.1)
	Sfx.play("print")
	if row.get("count", false) and view.has_meta("value"):
		var label: Label = view.get_meta("value")
		UiFx.count_to(label, 0, int(row["value"]), str(row["format"]), 0.6)
	if view is MiniChart:
		(view as MiniChart).set_values((view as MiniChart).get_meta("values"), (view as MiniChart).get_meta("labels"))


func _slam() -> void:
	printing = false
	_stamp.show()
	_stamp.position = _stamp_spot()
	UiFx.tilt(_stamp, -11.0)
	UiFx.stamp(_stamp, _paper)
	get_tree().create_timer(0.11, true).timeout.connect(func() -> void: Sfx.play("stamp"))
	UiFx.pulse(_close, 0.06)


## Stamp in the blank foot, a bit right of centre and over the edge.
func _stamp_spot() -> Vector2:
	return Vector2(12.0 + WIDTH - _stamp.size.x + 8.0, SLOT_Y - STAMP_ZONE - 2.0)


## Cash register body under the paper: dark till with a slit, a coin tray.
func _draw_register() -> void:
	var r := Rect2(Vector2.ZERO, _register.size)
	if Art.draw(_register, "ui/frames/receipt_register", r):
		return
	_register.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(INK, 0.6))  # hard shadow
	_register.draw_rect(r, INK)
	_register.draw_rect(r.grow(-2.0), Color("394a50"))
	_register.draw_rect(Rect2(2, 2, r.size.x - 4.0, 1), Color("577277"))
	_register.draw_rect(Rect2(10, 4, WIDTH + 4.0, 3), INK)  # paper slit
	for i in 3:
		_register.draw_rect(Rect2(12 + i * 9, 11, 6, 5), Color("202e37"))  # keys
		_register.draw_rect(Rect2(12 + i * 9, 11, 6, 1), Color("819796"))
