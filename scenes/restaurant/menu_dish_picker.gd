class_name MenuDishPicker
extends VBoxContainer
## Scrollable catalog. Unavailable dishes stay visible with a reason.

signal selected(dish: DishData)
signal cancelled

var _scroll: ScrollContainer
var _grid: GridContainer
var _back: Button


func _init() -> void:
	add_theme_constant_override("separation", 6)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(552, 216)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	_scroll.add_child(_grid)
	_back = MenuSlotCard._button("Quay lại")
	_back.pressed.connect(func() -> void: cancelled.emit())
	add_child(_back)


func show_dishes(menu: DishCatalog, plan: MenuPlan, previous: DishData) -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var available := plan.storage_after_returning(previous, GameState.storage)
	for dish in menu.dishes:
		var reason := ""
		if dish.always_available:
			reason = "Luôn có" if dish.on_menu_today() else "Từ ngày %d" % dish.unlock_day
		elif dish.kitchen_level > plan.kitchen_level:
			reason = "Cần bếp cấp %d" % dish.kitchen_level
		elif dish != previous and dish in plan.get_dishes():
			reason = "Đã có trên menu"
		elif not KitchenLogic.can_cook(dish, available):
			reason = "Thiếu nguyên liệu"
		var button := _dish_button(dish, reason, available)
		button.pressed.connect(func() -> void: selected.emit(dish))
		_grid.add_child(button)
	_scroll.scroll_vertical = 0
	show()
	_back.grab_focus()


func _dish_button(dish: DishData, reason: String, available: Array) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(130, 120)
	button.disabled = reason != ""
	button.tooltip_text = reason
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_right = -4
	content.offset_top = 4
	content.offset_bottom = -4
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(64, 64)
	image.texture = Art.texture("dishes/" + dish.id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(image)
	var title := MenuSlotCard._label(dish.display_name)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.y = 26
	content.add_child(title)
	var status := MenuSlotCard._label(reason if reason != "" else "%dk · %d phần%s" % [
		dish.base_price, MenuPlan.max_portions(dish, available), " · HOT" if DailyTrend.is_hot(dish) else ""])
	status.add_theme_font_size_override("font_size", 9)
	content.add_child(status)
	if button.disabled:
		content.modulate = Color(0.65, 0.65, 0.7)
	return button
