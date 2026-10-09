class_name PhoneStaff
extends ScrollContainer
## "Nhân viên" tab of the phone (from StaffCatalog.unlock_day): who works at
## the restaurant (one line each: name, rank, skills, wage per shift,
## "Nghỉ"), who wants the job ("Thuê"; their line shows on hover), and the
## job ads (one a day, a pricier ad brings better people). Works on
## GameState.staff through a StaffRoster; StaffCrew follows the changes.

@export var font_size: int = 8

var roster: StaffRoster

var _box: VBoxContainer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 2)
	add_child(_box)


func setup(catalog: StaffCatalog) -> void:
	roster = StaffRoster.new(catalog, GameState.staff)
	roster.changed.connect(refresh)
	roster.changed.connect(GameState.staff_changed.emit)


func refresh() -> void:
	if roster == null:
		return
	if not is_same(roster.data, GameState.staff):  # a save was loaded / new game
		setup(roster.catalog)
	for child in _box.get_children():
		child.queue_free()
	_box.add_child(_label("Đang làm %d/%d · tiền %dk" % [roster.hired().size(), roster.catalog.max_hired,
		GameState.money], Color(1, 0.9, 0.5)))
	for person in roster.hired():
		_box.add_child(_row(person, "Nghỉ", roster.dismiss.bind(person), false))
	if not roster.candidates().is_empty():
		_box.add_child(_label("Ứng viên", Color(0.6, 0.85, 1.0)))
	for person in roster.candidates():
		_box.add_child(_row(person, "Thuê", roster.hire.bind(person), not roster.can_hire()))
	var can_post := roster.can_post(GameState.day)
	_box.add_child(_label("Đăng tin tuyển" + ("" if can_post else " (mai đăng tiếp)"), Color(0.6, 0.85, 1.0)))
	var ads := HBoxContainer.new()
	for i in roster.catalog.ad_costs.size():
		var cost := roster.catalog.ad_costs[i]
		var ad := _button("%s %dk" % [roster.catalog.ad_labels[i], cost])
		ad.disabled = not can_post or GameState.money < cost
		ad.tooltip_text = "Ứng viên hạng %d" % (i + 1)
		ad.pressed.connect(_post_ad.bind(i + 1, cost))
		ads.add_child(ad)
	_box.add_child(ads)


func _post_ad(tier: int, cost: int) -> void:
	if GameState.spend_money(cost):
		roster.post_ad(tier, GameState.day, _rng)


func _row(person: StaffData, action: String, on_pressed: Callable, disabled: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.tooltip_text = person.pitch
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(6, 6)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = person.body_color
	row.add_child(swatch)
	var text := _label("%s h%d · %s · %dk" % [person.display_name, person.tier, person.skill_text(), person.wage],
		Color(0.9, 0.92, 0.95))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.tooltip_text = person.pitch
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(text)
	var button := _button(action)
	button.disabled = disabled
	button.pressed.connect(func() -> void: on_pressed.call())
	row.add_child(button)
	return row


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	return button
