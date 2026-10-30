class_name MenuPicker3D
extends VBoxContainer
## Dish picker inside MenuPanel3D: a grid of small paper cards (key number,
## picture, name, coin price, servings it can make, chili if HOT). Dishes
## already on the menu or out of seafood are greyed with a lock / empty-fish
## mark. Keys 1-9 are handled by the panel.

signal chosen(dish: DishData)
signal back_requested

const INK := Color("2a2230")
const CHILI := Color("cf573c")

var _grid: GridContainer


func _init() -> void:
	add_theme_constant_override("separation", 4)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(572, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_grid)
	var back := UiIcons.dress(Button.new(), "back", 14)
	back.text = "Esc"
	back.tooltip_text = "Quay lại"
	back.focus_mode = Control.FOCUS_NONE
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.add_theme_font_size_override("font_size", 10)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)


func fill(dishes: Array[DishData], previous: DishData, on_menu: Array[DishData], available: Array) -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for i in dishes.size():
		var dish := dishes[i]
		var blocked := ""
		if dish != previous and dish in on_menu:
			blocked = "check"
		elif not KitchenLogic.can_cook(dish, available):
			blocked = "lock"
		_grid.add_child(_item(i, dish, blocked, available))
	if dishes.is_empty():
		var empty := UiIcons.pair("boat", "Chưa có cá: ra khơi trước", 16, UiIcons.SEA, &"BoldLabel", 11)
		_grid.add_child(empty)


func animate_in() -> void:
	UiFx.stagger(_grid, 0.03)


## `blocked`: "" = can pick, "check" = already on the menu, "lock" = no seafood.
func _item(index: int, dish: DishData, blocked: String, available: Array) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"CardFace"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(137, 44)
	button.disabled = blocked != ""
	button.tooltip_text = dish.display_name + {"": "", "check": " · đã có", "lock": " · hết hải sản"}[blocked]
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 4
	row.offset_right = -4
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var key := Label.new()
	key.theme_type_variation = &"KeyLabel"
	key.add_theme_font_size_override("font_size", 8)
	key.text = str(index + 1)
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(key)
	var picture := TextureRect.new()
	picture.texture = Art.texture("dishes/" + dish.id)
	picture.custom_minimum_size = Vector2(32, 32)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(picture)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name_label := Label.new()
	name_label.theme_type_variation = &"CardLabel"
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.text = dish.display_name
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.custom_minimum_size.x = 70
	text.add_child(name_label)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 2)
	text.add_child(facts)
	if blocked != "":
		facts.add_child(UiIcons.make(blocked, 12, INK))
	else:
		facts.add_child(UiIcons.make("money", 10, Color("be772b")))
		facts.add_child(_fact("%dk" % roundi(dish.base_price * DailyTrend.price_scale(dish))))
		facts.add_child(UiIcons.make("meal", 10, INK))
		facts.add_child(_fact("x%d" % MenuPlan.max_portions(dish, available)))
		if DailyTrend.is_hot(dish):
			facts.add_child(UiIcons.make("hot", 11, CHILI))
		UiFx.hover_lift(button, 0.05)
	if button.disabled:
		button.modulate = Color(0.85, 0.85, 0.85, 0.8)
	button.pressed.connect(func() -> void: chosen.emit(dish))
	return button


func _fact(text: String) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"CardLabel"
	label.add_theme_font_size_override("font_size", 9)
	label.text = text
	return label
