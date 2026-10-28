class_name RestaurantHud3D
extends CanvasLayer
## 3D restaurant HUD like the 2D one: day / clock / money bar, shift counters,
## order tickets, and pinned buttons (Thực đơn, Sửa quán, Đóng sớm, Ra khơi).
## Reads the scene each frame; the scene only listens to the button signals.

signal menu_requested
signal renovate_requested
signal close_requested
signal sail_requested

const CONFIRM_SECONDS := 3.0

var room: Node3D
var bar: Label
var counters: Label
var ticket_row: HBoxContainer
var menu_button: Button
var renovate_button: Button
var close_button: Button
var sail_button: Button
var _confirm_left: float = 0.0


func setup(room_node: Node3D, theme: Theme, style: StyleBoxFlat) -> void:
	room = room_node
	bar = _label(Vector2(12, 6), Color("f2d98a"), style)
	counters = _label(Vector2(12, 28), Color("e7d5b3"), style)
	ticket_row = HBoxContainer.new()
	ticket_row.position = Vector2(12, 50)
	ticket_row.add_theme_constant_override("separation", 3)
	ticket_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ticket_row)
	menu_button = _button("Thực đơn", Vector2(528, 6), theme)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	renovate_button = _button("Sửa quán", Vector2(528, 30), theme)
	renovate_button.pressed.connect(func() -> void: renovate_requested.emit())
	close_button = _button("Đóng sớm", Vector2(528, 6), theme)
	close_button.pressed.connect(_on_close_pressed)
	sail_button = _button("Ra khơi  →", Vector2(520, 290), theme)
	sail_button.pressed.connect(func() -> void: sail_requested.emit())
	sail_button.custom_minimum_size = Vector2(114, 32)


func _label(pos: Vector2, color: Color, style: StyleBoxFlat) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _button(words: String, pos: Vector2, theme: Theme) -> Button:
	var button := Button.new()
	button.text = words
	button.theme = theme
	button.position = pos
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button


## Two presses: the first asks, the second closes (keeps T as the quick key).
func _on_close_pressed() -> void:
	if _confirm_left > 0.0:
		_confirm_left = 0.0
		close_requested.emit()
	else:
		_confirm_left = CONFIRM_SECONDS
		close_button.text = "Chắc chưa?"


func _process(delta: float) -> void:
	if room == null:
		return
	if _confirm_left > 0.0:
		_confirm_left -= delta
		if _confirm_left <= 0.0:
			close_button.text = "Đóng sớm"
	var running: bool = room.shift_running
	var over: bool = room.shift_over
	var state := "ĐÃ ĐÓNG CỬA" if over else ("ĐANG BÁN" if running else "LÊN THỰC ĐƠN")
	if running and room.seconds_left <= 0.0:
		state = "SẮP ĐÓNG"
	bar.text = "NGÀY %d · %s · %s · %dk" % [GameState.day, DayClock.get_time_text(), state, GameState.money]
	counters.text = "Phục vụ %d · Bỏ về %d · Thu %dk · Chợ %dk · %d sao" % [room.served, room.lost, room.earned, room.market_spent, GameState.last_rating]
	menu_button.visible = not running and not over
	renovate_button.visible = not running and not room.is_renovating()
	renovate_button.position.y = 30.0 if menu_button.visible else 6.0
	close_button.visible = running and room.seconds_left > 0.0
	sail_button.visible = over and not room.is_renovating()
	if not close_button.visible:
		_confirm_left = 0.0
		close_button.text = "Đóng sớm"
	_refresh_tickets()


func _refresh_tickets() -> void:
	for old in ticket_row.get_children():
		old.queue_free()
	if not room.shift_running:
		return
	for i: int in range(room.orders.size()):
		var order: Dictionary = room.orders[i]
		if order.is_empty():
			continue
		var dish: DishData = order["dish"]
		var phase := str(order.get("phase", "waiting"))
		var tag := "đang ăn" if phase == "eating" else ("xong" if bool(order.get("cooked", false)) else "%ds" % int(float(order["patience"])))
		var ticket := Label.new()
		ticket.text = "B%d %s · %s" % [i + 1, dish.display_name, tag]
		ticket.add_theme_font_size_override("font_size", 10)
		var urgent: bool = phase != "eating" and float(order["patience"]) < 15.0
		ticket.add_theme_color_override("font_color", Color("ff9a8a") if urgent else Color("e9dfc5"))
		ticket.add_theme_stylebox_override("normal", room._panel_style())
		ticket_row.add_child(ticket)
