class_name MenuPanel3D
extends PanelContainer
## 3D restaurant menu planning: slot cards (picture, price, HOT, servings), a
## dish picker, pantry line, auto-fill and the "Mở cửa" start. Pure rules live
## in MenuPlan / DishBook / DailyTrend; this is only the view.

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
var title_label: Label
var always_label: Label
var auto_button: Button
var clear_button: Button
var open_button: Button
var sail_button: Button
var picker_dishes: Array[DishData] = []
var editing_slot: int = -1
var _slot_dishes: Array[DishData] = []
var _cards: Array[MenuSlotCard] = []
var _slots_box: HBoxContainer
var _picker: ScrollContainer
var _grid: GridContainer
var _buttons: HBoxContainer


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


func setup(p_plan: MenuPlan, p_menu: DishCatalog, p_stock: MarketStock, p_has_stock: Callable,
		theme_: Theme, style: StyleBoxFlat) -> void:
	plan = p_plan
	menu = p_menu
	market_stock = p_stock
	has_stock = p_has_stock
	theme = theme_
	add_theme_stylebox_override("panel", style)
	position = Vector2(28, 66)  # below the HUD bar + quest line
	custom_minimum_size = Vector2(584, 0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	title_label = Label.new()
	box.add_child(title_label)
	_slots_box = HBoxContainer.new()
	_slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_box.add_theme_constant_override("separation", 6)
	box.add_child(_slots_box)
	_picker = ScrollContainer.new()
	_picker.custom_minimum_size = Vector2(572, 170)
	_picker.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_picker)
	_grid = GridContainer.new()
	_grid.columns = 4
	_picker.add_child(_grid)
	_picker.hide()
	always_label = Label.new()
	always_label.add_theme_font_size_override("font_size", 10)
	box.add_child(always_label)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 4)
	box.add_child(_buttons)
	auto_button = _button("Tự xếp", func() -> void:
		plan.auto_fill(menu.dishes, GameState.storage))
	clear_button = _button("Xóa hết", func() -> void: plan.clear(GameState.storage))
	_button("Mua ở Cô Năm", func() -> void: shop_requested.emit())
	_button("Sửa quán", func() -> void: renovate_requested.emit())
	_button("Đóng", close)
	open_button = _button("Mở cửa", func() -> void: open_requested.emit())
	sail_button = _button("Ra khơi", func() -> void: sail_requested.emit())
	plan.changed.connect(refresh)
	hide()
	refresh()


func open() -> void:
	_close_picker()
	refresh()
	show()


func close() -> void:
	_close_picker()
	hide()
	closed.emit()


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func _build_slots() -> void:
	for card in _cards:
		_slots_box.remove_child(card)
		card.queue_free()
	_cards.clear()
	_slot_dishes.resize(plan.slots)
	for index in plan.slots:
		var card := MenuSlotCard.new()
		card.custom_minimum_size = Vector2(100, 0)
		card.choose_button.custom_minimum_size = Vector2(100, 100)
		card.picture.custom_minimum_size = Vector2(48, 48)
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
	always_label.text = _pantry_text()
	var seafood := visible_dishes(menu.dishes, plan.kitchen_level)
	clear_button.disabled = plan.total_portions() == 0
	auto_button.disabled = seafood.all(func(d: DishData) -> bool:
		return not plan.can_add(d, GameState.storage))
	var stocked: bool = has_stock.call()
	open_button.disabled = not stocked
	sail_button.visible = not stocked
	if editing_slot < 0:
		_update_title()
	else:
		_fill_picker()


func _pantry_text() -> String:
	var parts: PackedStringArray = []
	for dish in menu.dishes:
		if dish.is_market_dish() and dish.unlock_day <= GameState.day:
			parts.append("%s %d" % [dish.display_name, market_stock.portions(dish)])
	return "Luôn có (tạp hoá): " + ", ".join(parts)


func _update_title() -> void:
	var text := "Thực đơn · %d/%d món · %d phần · kho %d con" % [
		plan.used_slots(), plan.slots, plan.total_portions(), GameState.storage.size()]
	var hot := DailyTrend.dish_id()
	if hot != "":
		for dish in menu.dishes:
			if dish.id == hot:
				text += " · HOT: " + dish.display_name
	var variety := MenuPlan.variety_multiplier(plan.variety_count(), VARIETY_TABLE)
	if variety != 1.0:
		text += " · giá x%s" % str(snappedf(variety, 0.01))
	title_label.text = text
	if visible_dishes(menu.dishes, plan.kitchen_level).is_empty():
		title_label.text += "\nChưa có cá nấu được. Ra biển bắt cá trước."


func _open_picker(index: int) -> void:
	editing_slot = index
	_slots_box.hide()
	_buttons.hide()
	_picker.show()
	_fill_picker()


func _fill_picker() -> void:
	title_label.text = "Chọn món · ô %d (số 1-9, Esc quay lại)" % (editing_slot + 1)
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var previous := _slot_dishes[editing_slot]
	var available := plan.storage_after_returning(previous, GameState.storage)
	picker_dishes = visible_dishes(menu.dishes, plan.kitchen_level)
	for i in picker_dishes.size():
		var dish := picker_dishes[i]
		var reason := ""
		if dish != previous and dish in plan.get_dishes():
			reason = "Đã có trên menu"
		elif not KitchenLogic.can_cook(dish, available):
			reason = "Hết nguyên liệu"
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(138, 40)
		button.clip_text = true
		button.icon = Art.texture("dishes/" + dish.id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.add_theme_font_size_override("font_size", 10)
		button.disabled = reason != ""
		var detail := reason if reason != "" else "%dk · %d phần%s" % [
			dish.base_price, MenuPlan.max_portions(dish, available),
			" · HOT" if DailyTrend.is_hot(dish) else ""]
		button.text = "%d. %s\n%s" % [i + 1, dish.display_name, detail]
		button.pressed.connect(select_dish.bind(dish))
		_grid.add_child(button)
	if picker_dishes.is_empty():
		var empty := Label.new()
		empty.text = "Chưa có món nào nấu được.\nRa biển bắt cá, rồi quay lại lên thực đơn."
		empty.add_theme_font_size_override("font_size", 11)
		_grid.add_child(empty)


func select_dish(dish: DishData) -> bool:
	if editing_slot < 0:
		return false
	var previous := _slot_dishes[editing_slot]
	_slot_dishes[editing_slot] = dish
	if not plan.replace_dish(previous, dish, GameState.storage):
		_slot_dishes[editing_slot] = previous
		refresh()
		return false
	_close_picker()
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
