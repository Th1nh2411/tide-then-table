class_name MenuPanel3D
extends PanelContainer
## 3D restaurant menu planning: header (MenuPanelHeader3D: stats, HOT chip,
## takings chart), slot cards (MenuDishCard3D), dish picker (MenuPicker3D),
## pantry pictures, icon buttons and "Mở cửa". Pure rules live in MenuPlan /
## DishBook / DailyTrend; this is only the view.

signal shop_requested
signal open_requested
signal renovate_requested
signal sail_requested
signal closed

const VARIETY_TABLE: Array[float] = [0.8, 0.8, 0.9, 1.0, 1.05, 1.1]

var plan: MenuPlan
var menu: DishCatalog
var market_stock: MarketStock
var has_stock: Callable
var header: MenuPanelHeader3D
var heading: Label
var title_label: Label
var revenue_label: Label
var auto_button: Button
var clear_button: Button
var open_button: Button
var sail_button: Button
var picker_dishes: Array[DishData] = []
var editing_slot: int = -1
var _slot_dishes: Array[DishData] = []
var _cards: Array[MenuDishCard3D] = []
var _slots_box: HBoxContainer
var _picker: MenuPicker3D
var _pantry: HBoxContainer
var _buttons: HBoxContainer
var _open_pulse: Tween


## Seafood dishes the player may see: known fish and a kitchen that can cook them.
static func visible_dishes(dishes: Array[DishData], level: int) -> Array[DishData]:
	var result: Array[DishData] = []
	for dish in dishes:
		if dish.ingredients.is_empty() or dish.always_available:
			continue
		if dish.kitchen_level > level or not DishBook.is_known(dish):
			continue
		result.append(dish)
	return result


## `theme_` comes from the scene (RestaurantPanels3D, text size); `style` is
## kept for the API but the board is the "ChalkPanel" material.
func setup(p_plan: MenuPlan, p_menu: DishCatalog, p_stock: MarketStock, p_has_stock: Callable,
		theme_: Theme, style: StyleBoxFlat) -> void:
	plan = p_plan
	menu = p_menu
	market_stock = p_stock
	has_stock = p_has_stock
	theme = theme_
	theme_type_variation = &"ChalkPanel"
	if style == null:
		push_warning("MenuPanel3D: no style")
	position = Vector2(28, 64)  # below the HUD bar + quest line
	custom_minimum_size = Vector2(584, 0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	add_child(box)
	header = MenuPanelHeader3D.new()
	heading = header.heading
	title_label = header.title_label
	revenue_label = header.revenue_label
	box.add_child(header)
	_slots_box = HBoxContainer.new()
	_slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_box.add_theme_constant_override("separation", 10)
	_slots_box.custom_minimum_size.y = 146
	box.add_child(_slots_box)
	_picker = MenuPicker3D.new()
	_picker.chosen.connect(func(dish: DishData) -> void: select_dish(dish))
	_picker.back_requested.connect(_close_picker)
	box.add_child(_picker)
	_picker.hide()
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 4)
	box.add_child(_buttons)
	_build_buttons()
	plan.changed.connect(refresh)
	hide()
	refresh()


## Icon + a word for the main actions, icon-only (tooltip) for the rest.
func _build_buttons() -> void:
	auto_button = _button("auto", "Tự xếp", "Tự xếp món (Q)", func() -> void:
		plan.auto_fill(menu.dishes, GameState.storage))
	clear_button = _button("trash", "", "Xóa hết", func() -> void: plan.clear(GameState.storage))
	_button("hammer", "", "Sửa quán", func() -> void: renovate_requested.emit())
	_button("close", "", "Đóng (Esc)", close)
	# Market goods in stock: tiny pictures + counts, then the button to buy more.
	_pantry = HBoxContainer.new()
	_pantry.add_theme_constant_override("separation", 4)
	_pantry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pantry.alignment = BoxContainer.ALIGNMENT_END
	_buttons.add_child(_pantry)
	_button("cart", "Cô Năm", "Mua rau, bia ở Cô Năm", func() -> void: shop_requested.emit())
	sail_button = _button("boat", "Ra khơi", "", func() -> void: sail_requested.emit())
	open_button = _button("shop", "Mở cửa", "", func() -> void: open_requested.emit())
	open_button.theme_type_variation = &"AccentButton"
	open_button.custom_minimum_size.x = 92
	_open_pulse = UiFx.pulse(open_button, 0.05, 1.1)


func open() -> void:
	_close_picker()
	refresh()
	show()
	UiFx.pop_in(self)
	UiFx.stagger(_slots_box, 0.07, 0.1)
	header.count_up()


func close() -> void:
	_close_picker()
	hide()
	closed.emit()


func _button(icon: String, text: String, tooltip: String, action: Callable) -> Button:
	var button: Button
	if text == "":
		button = UiIcons.icon_button(icon, tooltip, 14)
	else:
		button = UiIcons.dress(Button.new(), icon, 14)
		button.text = text
		button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 10)
	button.pressed.connect(action)
	_buttons.add_child(button)
	UiFx.hover_lift(button, 0.06)
	return button


func _build_slots() -> void:
	for card in _cards:
		_slots_box.remove_child(card)
		card.queue_free()
	_cards.clear()
	_slot_dishes.resize(plan.slots)
	# Fewer slots = wider cards; five still fit the panel.
	var card_width := clampf((560.0 - 10.0 * (plan.slots - 1)) / plan.slots, 100.0, 124.0)
	for index in plan.slots:
		var card := MenuDishCard3D.new(index + 1, card_width)
		UiFx.tilt(card.choose_button, 1.5 if index % 2 == 0 else -1.2)  # pinned slips, a bit crooked
		card.picked.connect(_open_picker.bind(index))
		card.added.connect(func() -> void:
			if _slot_dishes[index]:
				plan.add_portion(_slot_dishes[index], GameState.storage))
		card.removed.connect(func() -> void:
			if _slot_dishes[index]:
				plan.remove_portion(_slot_dishes[index], GameState.storage))
		_slots_box.add_child(card)
		_cards.append(card)


func refresh() -> void:
	if plan == null:
		return
	if _cards.size() != plan.slots:
		_build_slots()
	var dishes := plan.get_dishes()
	for index in _slot_dishes.size():
		if _slot_dishes[index] not in dishes:
			_slot_dishes[index] = null
	for dish in dishes:
		if dish not in _slot_dishes:
			var free := _slot_dishes.find(null)
			if free >= 0:
				_slot_dishes[free] = dish
	for index in _cards.size():
		var dish := _slot_dishes[index]
		_cards[index].display(dish, plan.get_portion_count(dish),
			plan.can_add(dish, GameState.storage) if dish else false)
	_fill_pantry()
	var seafood := visible_dishes(menu.dishes, plan.kitchen_level)
	clear_button.disabled = plan.total_portions() == 0
	auto_button.disabled = seafood.all(func(d: DishData) -> bool:
		return not plan.can_add(d, GameState.storage))
	var stocked: bool = has_stock.call()
	open_button.disabled = not stocked
	if stocked:
		_open_pulse.play()
	else:
		_open_pulse.pause()
		open_button.scale = Vector2.ONE
	sail_button.visible = not stocked
	_update_revenue()
	if editing_slot < 0:
		_update_title()
	else:
		_fill_picker()


## Rough takings if every serving sells (today's dish and variety included).
func expected_revenue() -> int:
	var total := 0
	for value in _revenue_per_slot():
		total += roundi(value)
	return total


func _revenue_per_slot() -> Array[float]:
	var variety := MenuPlan.variety_multiplier(plan.variety_count(), VARIETY_TABLE)
	var values: Array[float] = []
	for dish in _slot_dishes:
		values.append(plan.get_portion_count(dish) * dish.base_price * DailyTrend.price_scale(dish) * variety
			if dish else 0.0)
	return values


func _update_revenue() -> void:
	var hot := -1
	for index in _slot_dishes.size():
		if _slot_dishes[index] and DailyTrend.is_hot(_slot_dishes[index]):
			hot = index
	var labels: Array[String] = []
	for index in _slot_dishes.size():
		labels.append(str(index + 1))
	header.set_revenue(_revenue_per_slot(), labels, hot, expected_revenue(), visible)


func _fill_pantry() -> void:
	for child in _pantry.get_children():
		_pantry.remove_child(child)
		child.queue_free()
	for dish in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 1)
			row.tooltip_text = dish.display_name
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			var picture := TextureRect.new()
			picture.texture = Art.texture("dishes/" + dish.id)
			picture.custom_minimum_size = Vector2(18, 18)
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(picture)
			var count := Label.new()
			count.text = "x%d" % market_stock.portions(dish)
			count.theme_type_variation = &"ChalkLabel"
			count.add_theme_font_size_override("font_size", 10)
			if market_stock.portions(dish) == 0:
				count.add_theme_color_override("font_color", Color("f0a08a"))
			row.add_child(count)
			_pantry.add_child(row)


func _update_title() -> void:
	var variety := MenuPlan.variety_multiplier(plan.variety_count(), VARIETY_TABLE)
	header.show_plan(plan, menu, variety, not visible_dishes(menu.dishes, plan.kitchen_level).is_empty())


func _open_picker(index: int) -> void:
	editing_slot = index
	_slots_box.hide()
	_buttons.hide()
	_picker.show()
	_fill_picker()
	_picker.animate_in()


func _fill_picker() -> void:
	header.show_picker(editing_slot)
	var previous := _slot_dishes[editing_slot]
	var available := plan.storage_after_returning(previous, GameState.storage)
	picker_dishes = visible_dishes(menu.dishes, plan.kitchen_level)
	_picker.fill(picker_dishes, previous, plan.get_dishes(), available)


func select_dish(dish: DishData) -> bool:
	if editing_slot < 0:
		return false
	var previous := _slot_dishes[editing_slot]
	_slot_dishes[editing_slot] = dish
	var slot := editing_slot
	if not plan.replace_dish(previous, dish, GameState.storage):
		_slot_dishes[editing_slot] = previous
		refresh()
		return false
	_close_picker()
	if slot < _cards.size():
		_cards[slot].celebrate()
	return true


func _close_picker() -> void:
	editing_slot = -1
	if _picker == null:
		return
	_picker.hide()
	_slots_box.show()
	_buttons.show()
	if plan:
		_update_title()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var number := key.physical_keycode - KEY_1
	if key.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if editing_slot >= 0:
			_close_picker()
		else:
			close()
	elif editing_slot >= 0 and number >= 0 and number < picker_dishes.size():
		get_viewport().set_input_as_handled()
		select_dish(picker_dishes[number])
	elif editing_slot < 0 and number >= 0 and number < plan.slots:
		get_viewport().set_input_as_handled()
		_open_picker(number)
	elif editing_slot < 0 and key.physical_keycode == KEY_Q and not auto_button.disabled:
		get_viewport().set_input_as_handled()
		auto_button.pressed.emit()
