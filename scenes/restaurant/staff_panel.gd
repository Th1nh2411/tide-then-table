class_name StaffPanel
extends PanelContainer
## "Nhân viên" (pinned button, while the shop isn't serving): who works here
## (skills, wage per shift, "Cho nghỉ"), who is asking for the job (their
## line, "Thuê"), and the job ads (one a day; a pricier ad brings better
## people). Built in code; rebuilt whenever the roster changes. E / Esc closes.

signal closed

@export var crew: StaffCrew
@export var font_size: int = 9

var _rng := RandomNumberGenerator.new()
var _box: VBoxContainer


func _ready() -> void:
	hide()
	_rng.randomize()
	position = Vector2(150, 30)
	custom_minimum_size = Vector2(340, 0)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.1, 0.1, 0.13, 0.96)
	background.set_content_margin_all(6)
	add_theme_stylebox_override("panel", background)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 3)
	add_child(_box)
	crew.roster.changed.connect(_rebuild)


func open_panel() -> void:
	_rebuild()
	show()
	move_to_front()


func close_panel() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close_panel()


func _rebuild() -> void:
	for child in _box.get_children():
		child.queue_free()
	var roster := crew.roster
	_box.add_child(_label("Nhân viên quán (tối đa %d)   ·   Tiền: %dk" % [roster.catalog.max_hired, GameState.money], 10))
	_box.add_child(_label("Đang làm (lương trả cuối mỗi ca):"))
	if roster.hired().is_empty():
		_box.add_child(_label("  Chưa có ai. Rin tự bưng tự dọn."))
	for person in roster.hired():
		var dismiss := _button("Cho nghỉ")
		dismiss.pressed.connect(func() -> void: roster.dismiss(person))
		_box.add_child(_row(person, dismiss))
	_box.add_child(_label("Ứng viên:"))
	if roster.candidates().is_empty():
		_box.add_child(_label("  Chưa ai xin việc. Đăng tin tuyển dụng đi!"))
	for person in roster.candidates():
		var hire := _button("Thuê")
		hire.disabled = not roster.can_hire()
		hire.pressed.connect(func() -> void: roster.hire(person))
		_box.add_child(_row(person, hire))
		var pitch := _label("  \"%s\"" % person.pitch, font_size - 1)
		pitch.autowrap_mode = TextServer.AUTOWRAP_WORD
		pitch.modulate = Color(0.8, 0.8, 0.8)
		_box.add_child(pitch)
	var can_post := roster.can_post(GameState.day)
	_box.add_child(_label("Đăng tin tuyển dụng%s:" % ("" if can_post else " (hôm nay đã đăng)")))
	var ads := HBoxContainer.new()
	for i in roster.catalog.ad_costs.size():
		var cost := roster.catalog.ad_costs[i]
		var ad := _button("%s %dk" % [roster.catalog.ad_labels[i], cost])
		ad.disabled = not can_post or GameState.money < cost
		ad.pressed.connect(_post_ad.bind(i + 1, cost))
		ads.add_child(ad)
	_box.add_child(ads)
	var close := _button("Đóng (E)")
	close.pressed.connect(close_panel)
	_box.add_child(close)


func _post_ad(tier: int, cost: int) -> void:
	if not GameState.spend_money(cost):
		return
	var people := crew.roster.post_ad(tier, GameState.day, _rng)
	if people.is_empty():
		crew.message_requested.emit("Không ai mới tới xin việc...")


func _row(person: StaffData, action: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(8, 8)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = person.body_color
	row.add_child(swatch)
	var text := _label("%s (hạng %d) · %s · %dk/ca" % [person.display_name, person.tier, person.skill_text(), person.wage])
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	row.add_child(action)
	return row


func _label(text: String, size: int = font_size) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE  # Space must not press it
	button.add_theme_font_size_override("font_size", font_size)
	return button
