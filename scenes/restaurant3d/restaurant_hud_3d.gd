class_name RestaurantHud3D
extends CanvasLayer
## 3D restaurant HUD, icon first: a wooden plank (day, clock, phase sticker,
## money counting), a yellow paper tag with the shift's tallies (served, left,
## takings, market, stars), the order slips on a ticket rail (OrderTicket3D),
## and the pinned Đóng sớm button (leaving is a walk to a street end). Words live in
## tooltips. Reads the scene each frame; the scene only listens to the signals.

signal close_requested

const CONFIRM_SECONDS := 3.0
## Ticket rail: between the left plank and the right buttons.
const RAIL := Rect2(232, 0, 290, 56)
const PHASES := {
	# id: [icon, plate, glyph, words]
	"plan": ["menu", Color("f2d98a"), Color("090a14"), "Lên thực đơn"],
	"open": ["shop", Color("884b2b"), Color("f2d98a"), "Đang bán"],
	"closing": ["clock", Color("de9e41"), Color("090a14"), "Sắp đóng cửa"],
	"over": ["moon", Color("253a5e"), Color("f2d98a"), "Đã đóng cửa"],
}

var room: Node3D
var plank: PanelContainer
var tally: PanelContainer
## The rail holding the order slips (kept under its old name).
var ticket_row: TicketRail3D
var close_button: Button
var _day: Label
var _time: Label
var _money: Label
var _phase: TextureRect
var _phase_id := ""
var _served: Label
var _lost: Label
var _earned: Label
var _market: Label
var _stars: Array[TextureRect] = []
var _confirm_left: float = 0.0


func setup(room_node: Node3D, theme: Theme, _style: StyleBoxFlat = null) -> void:
	room = room_node
	_build_plank()
	_build_tally()
	ticket_row = TicketRail3D.new()
	ticket_row.position = RAIL.position
	ticket_row.size = RAIL.size
	add_child(ticket_row)
	close_button = _button("Đóng sớm", "moon", Vector2(528, 6), theme)
	close_button.pressed.connect(_on_close_pressed)


func _build_plank() -> void:
	var parts := HudChips.plank(&"WoodPanel", 7)
	plank = parts[0]
	plank.position = Vector2(6, 4)
	add_child(plank)
	var row: HBoxContainer = parts[1]
	_day = HudChips.stat(row, "calendar", UiIcons.CREAM, "Ngày", 12)
	_time = HudChips.stat(row, "clock", Color("a4dddb"), "Giờ", 12)
	_phase = UiIcons.make("menu", 14, UiIcons.INK, Color("f2d98a"))
	_phase.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_phase)
	_money = HudChips.stat(row, "money", UiIcons.GOLD, "Tiền", 13)
	_money.add_theme_color_override("font_color", UiIcons.GOLD)


func _build_tally() -> void:
	var parts := HudChips.plank(&"TagPanel", 6)
	tally = parts[0]
	tally.position = Vector2(12, 30)
	add_child(tally)
	UiFx.tilt(tally, -1.2)
	var row: HBoxContainer = parts[1]
	_served = HudChips.stat(row, "guest", Color("4f8fba"), "Khách đã phục vụ", 11, true, 11)
	_lost = HudChips.stat(row, "leave", Color("cf573c"), "Khách bỏ về", 11, true, 11)
	_earned = HudChips.stat(row, "money", Color("de9e41"), "Thu trong ca", 11, true, 11)
	_market = HudChips.stat(row, "cart", Color("577277"), "Tiền chợ", 11, true, 11)
	var stars := HBoxContainer.new()
	stars.add_theme_constant_override("separation", 0)
	stars.tooltip_text = "Đánh giá"
	stars.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(stars)
	for i in DayRating.MAX_STARS:
		var star := UiIcons.make("star", 9, Color("a53030"))
		stars.add_child(star)
		_stars.append(star)


func _button(words: String, icon: String, pos: Vector2, theme: Theme) -> Button:
	var button := Button.new()
	button.text = words
	button.theme = theme
	button.position = pos
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	UiIcons.dress(button, icon, 12)
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
		UiFx.shake(close_button, 2.0)


func _process(delta: float) -> void:
	if room == null:
		return
	if _confirm_left > 0.0:
		_confirm_left -= delta
		if _confirm_left <= 0.0:
			close_button.text = "Đóng sớm"
	var running: bool = room.shift_running
	var over: bool = room.shift_over
	var phase := "over" if over else ("open" if running else "plan")
	if running and room.seconds_left <= 0.0:
		phase = "closing"
	_set_phase(phase)
	_day.text = str(GameState.day)
	_time.text = DayClock.get_time_text()
	HudChips.show_number(_money, GameState.money, "%dk")
	tally.visible = running or over
	HudChips.show_number(_served, room.served)
	HudChips.show_number(_lost, room.lost)
	HudChips.show_number(_earned, room.earned, "%dk")
	HudChips.show_number(_market, room.market_spent, "%dk")
	_lost.add_theme_color_override("font_color", Color("a53030") if room.lost > 0 else HudChips.INK)
	for i in _stars.size():
		_stars[i].modulate.a = 1.0 if i < GameState.last_rating else 0.25
	var modal: bool = room.modal_open()
	close_button.visible = running and room.seconds_left > 0.0 and not modal
	if not close_button.visible:
		_confirm_left = 0.0
		close_button.text = "Đóng sớm"
	var orders: Array[Dictionary] = []
	if running:
		orders = room.orders
	ticket_row.refresh(orders)


func _set_phase(phase: String) -> void:
	if phase == _phase_id:
		return
	var first := _phase_id == ""
	_phase_id = phase
	var spec: Array = PHASES[phase]
	_phase.texture = UiIcons.sticker(str(spec[0]), 14, spec[2], spec[1])
	_phase.tooltip_text = str(spec[3])
	if not first:
		UiFx.pop_in(_phase)
