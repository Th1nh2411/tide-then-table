class_name MenuSlotCard
extends VBoxContainer
## A large menu picture; the main button opens the dish picker.

signal picked
signal added
signal removed

var choose_button: Button
var picture: TextureRect
var dish_name: Label
var detail: Label
var minus: Button
var plus: Button
var count: Label


func _init() -> void:
	custom_minimum_size = Vector2(104, 0)
	add_theme_constant_override("separation", 4)
	choose_button = Button.new()
	choose_button.custom_minimum_size = Vector2(104, 124)
	choose_button.pressed.connect(func() -> void: picked.emit())
	add_child(choose_button)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_right = -4
	content.offset_top = 5
	content.offset_bottom = -5
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	choose_button.add_child(content)
	picture = TextureRect.new()
	picture.custom_minimum_size = Vector2(64, 64)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(picture)
	dish_name = _label("")
	dish_name.custom_minimum_size.y = 26
	dish_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(dish_name)
	detail = _label("")
	content.add_child(detail)
	var portions := HBoxContainer.new()
	portions.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(portions)
	minus = _button("−")
	minus.pressed.connect(func() -> void: removed.emit())
	portions.add_child(minus)
	count = _label("")
	count.custom_minimum_size.x = 44
	portions.add_child(count)
	plus = _button("+")
	plus.pressed.connect(func() -> void: added.emit())
	portions.add_child(plus)


func display(dish: DishData, portions: int, can_add: bool) -> void:
	picture.visible = dish != null
	picture.texture = Art.texture("dishes/" + dish.id) if dish else null
	choose_button.text = "" if dish else "+\nChọn món"
	dish_name.visible = dish != null
	detail.visible = dish != null
	dish_name.text = dish.display_name if dish else ""
	detail.text = "%dk%s" % [dish.base_price, " · HOT" if DailyTrend.is_hot(dish) else ""] if dish else ""
	choose_button.tooltip_text = "Bấm để đổi món" if dish else "Chọn món cho ô này"
	count.text = "%d phần" % portions if dish else "—"
	minus.disabled = dish == null
	plus.disabled = dish == null or not can_add


static func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(24, 22)
	button.add_theme_font_size_override("font_size", 12)
	return button
