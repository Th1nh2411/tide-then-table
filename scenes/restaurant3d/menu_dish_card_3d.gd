class_name MenuDishCard3D
extends VBoxContainer
## One menu slot in the 3D planning panel, Dave-style: a paper card (big
## picture, small name, coin + price chip, chili HOT badge, slot key) that
## opens the dish picker, then servings as dots with − / + under it.
## Only the view; MenuPanel3D owns the rules.

signal picked
signal added
signal removed

const CARD_SIZE := Vector2(104, 112)
const INK := Color("2a2230")
const CHILI := Color("cf573c")

var choose_button: Button
var picture: TextureRect
var dish_name: Label
var price: Label
var count: Label
var dots: PipBar
var minus: Button
var plus: Button
var _hot: Control
var _content: VBoxContainer
var _empty_hint: Control
var _dish: DishData
var _portions: int = -1


func _init(slot_number: int = 1, width: float = CARD_SIZE.x) -> void:
	add_theme_constant_override("separation", 3)
	choose_button = Button.new()
	choose_button.custom_minimum_size = Vector2(width, CARD_SIZE.y)
	choose_button.focus_mode = Control.FOCUS_NONE
	choose_button.theme_type_variation = &"CardFace"
	choose_button.pressed.connect(func() -> void: picked.emit())
	add_child(choose_button)
	UiFx.hover_lift(choose_button, 0.05)
	_content = VBoxContainer.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = 4
	_content.offset_bottom = -4
	_content.offset_left = 4
	_content.offset_right = -4
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_theme_constant_override("separation", 0)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choose_button.add_child(_content)
	picture = TextureRect.new()
	picture.custom_minimum_size = Vector2(60, 58)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(picture)
	dish_name = _label(&"CardLabel", 8)
	dish_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	dish_name.clip_text = true
	_content.add_child(dish_name)
	var chip := HBoxContainer.new()
	chip.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_theme_constant_override("separation", 2)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(UiIcons.make("money", 13, Color("e8c170")))
	price = _label(&"PriceLabel", 16)
	chip.add_child(price)
	_content.add_child(chip)
	_empty_hint = _empty_face()
	choose_button.add_child(_empty_hint)
	var key := _label(&"KeyLabel", 8)
	key.text = str(slot_number)
	key.position = Vector2(4, 4)
	choose_button.add_child(key)
	_hot = _hot_badge()
	_hot.position = Vector2(width - 20, -6)
	choose_button.add_child(_hot)
	UiFx.pulse(_hot, 0.16, 0.8)
	_build_stepper()


func _build_stepper() -> void:
	var stepper := HBoxContainer.new()
	stepper.alignment = BoxContainer.ALIGNMENT_CENTER
	stepper.add_theme_constant_override("separation", 3)
	add_child(stepper)
	minus = _step_button("−")
	minus.tooltip_text = "Bớt 1 phần"
	minus.pressed.connect(func() -> void: removed.emit())
	stepper.add_child(minus)
	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", 0)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.custom_minimum_size.x = 50
	stepper.add_child(middle)
	count = _label(&"ChalkLabel", 9)
	middle.add_child(count)
	dots = PipBar.new()
	dots.max_pips = 8
	dots.pip_size = 4.0
	dots.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	middle.add_child(dots)
	plus = _step_button("+")
	plus.tooltip_text = "Thêm 1 phần"
	plus.pressed.connect(func() -> void: added.emit())
	stepper.add_child(plus)


func display(dish: DishData, portions: int, can_add: bool) -> void:
	var changed_dish := dish != _dish
	_dish = dish
	_content.visible = dish != null
	_empty_hint.visible = dish == null
	_hot.visible = dish != null and DailyTrend.is_hot(dish)
	choose_button.theme_type_variation = &"CardFace" if dish else &"CardEmpty"
	choose_button.tooltip_text = dish.display_name if dish else "Chọn món"
	minus.disabled = dish == null
	plus.disabled = dish == null or not can_add
	dots.visible = dish != null
	if dish == null:
		count.text = "—"
		_portions = -1
		return
	picture.texture = Art.texture("dishes/" + dish.id)
	dish_name.text = dish.display_name
	price.text = "%dk" % roundi(dish.base_price * DailyTrend.price_scale(dish))
	dots.pip_color = Color("f2d98a") if can_add else Color("de9e41")
	dots.set_count(portions, portions)
	if changed_dish or _portions < 0:
		count.text = "x%d" % portions
	elif portions != _portions:
		UiFx.count_to(count, _portions, portions, "x%d", 0.25)
		UiFx.bounce(count, 0.18)
	_portions = portions


## A dish was just put on this slot: lift and flash.
func celebrate() -> void:
	UiFx.bounce(choose_button, 0.14)
	UiFx.flash(choose_button)


func _empty_face() -> Control:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := UiIcons.make("meal", 28, Color("c7cfcc"))
	icon.modulate.a = 0.6
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var plus_label := _label(&"ChalkLabel", 18)
	plus_label.text = "+"
	box.add_child(plus_label)
	return box


## Chili on a red disc, top-right corner of the card.
func _hot_badge() -> Control:
	var badge := PanelContainer.new()
	var disc := StyleBoxFlat.new()
	disc.bg_color = CHILI
	disc.border_color = Color("090a14")
	disc.set_border_width_all(2)
	disc.set_content_margin_all(2)
	disc.anti_aliasing = false
	badge.add_theme_stylebox_override("panel", disc)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.tooltip_text = "HOT x1.5"
	badge.add_child(UiIcons.make("hot", 16, Color("ebede9")))
	badge.rotation = deg_to_rad(12)  # slapped-on sticker
	return badge


func _label(variation: StringName, font_size: int) -> Label:
	var label := Label.new()
	if variation != &"":
		label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _step_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(22, 20)
	button.add_theme_font_size_override("font_size", 12)
	return button
