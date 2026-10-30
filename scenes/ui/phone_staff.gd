class_name PhoneStaff
extends ScrollContainer
## "Nhân viên" tab of the phone (from StaffCatalog.unlock_day): who works at
## the restaurant (one line each: name, rank, skills, wage per shift,
## "Nghỉ"), who wants the job ("Thuê"; their line shows on hover), and the
## job ads (one a day, a pricier ad brings better people). Works on
## GameState.staff through a StaffRoster; StaffCrew follows the changes.
## Look: app cards (colour swatch, name, rank pips, coin wage, paper button);
## ads as paper price tags with a coin; the words live in tooltips.

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
	var head := PhoneCards.header(_box, "staff", "%d/%d" % [roster.hired().size(), roster.catalog.max_hired])
	head.add_child(PhoneCards.coin("%dk" % GameState.money, Color("5ff2e0")))
	for person in roster.hired():
		_box.add_child(_row(person, "Nghỉ", roster.dismiss.bind(person), false))
	if not roster.candidates().is_empty():
		PhoneCards.header(_box, "people", "%d" % roster.candidates().size())
	for person in roster.candidates():
		_box.add_child(_row(person, "Thuê", roster.hire.bind(person), not roster.can_hire()))
	var can_post := roster.can_post(GameState.day)
	var ad_head := PhoneCards.header(_box, "follower", "" if can_post else "...")
	ad_head.tooltip_text = "Đăng tin tuyển" + ("" if can_post else " (mai đăng tiếp)")
	ad_head.mouse_filter = Control.MOUSE_FILTER_PASS
	var ads := HFlowContainer.new()
	ads.add_theme_constant_override("h_separation", 4)
	for i in roster.catalog.ad_costs.size():
		var cost := roster.catalog.ad_costs[i]
		var ad := _button("%dk" % cost)
		ad.theme_type_variation = &"PaperButton"
		UiIcons.dress(ad, "money", 10, Color("de9e41"))
		ad.tooltip_text = "%s · ứng viên hạng %d" % [roster.catalog.ad_labels[i], i + 1]
		ad.disabled = not can_post or GameState.money < cost
		ad.pressed.connect(_post_ad.bind(i + 1, cost))
		ads.add_child(ad)
	_box.add_child(ads)


func _post_ad(tier: int, cost: int) -> void:
	if GameState.spend_money(cost):
		roster.post_ad(tier, GameState.day, _rng)


func _row(person: StaffData, action: String, on_pressed: Callable, disabled: bool) -> Control:
	var holder := VBoxContainer.new()
	var row := PhoneCards.card(holder, 4)
	row.tooltip_text = "%s\n%s" % [person.skill_text(), person.pitch]
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(8, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = person.body_color
	row.add_child(swatch)
	var text := PhoneCards.neo(person.display_name, 10)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(text)
	var rank := PipBar.new()
	rank.pip_color = Color("de9e41")
	rank.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rank)
	rank.set_count(person.tier)
	row.add_child(PhoneCards.coin("%dk" % person.wage))
	var button := _button(action)
	button.theme_type_variation = &"PaperButton" if action == "Thuê" else &"Button"
	button.disabled = disabled
	button.pressed.connect(func() -> void: on_pressed.call())
	row.add_child(button)
	return holder


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	return button
