class_name MenuSetupPanel
extends PanelContainer
## Empty slots open a catalog; selected dishes show a large picture and portions.

signal confirmed
signal closed

var _plan: MenuPlan
var _menu: DishCatalog
var _variety_table: Array[float] = []
var _slot_dishes: Array[DishData] = []
var _cards: Array[MenuSlotCard] = []
var _editing_slot: int = -1
var _picker: MenuDishPicker
var _slots_box: HBoxContainer
var _always_label: Label
var _buttons: HBoxContainer

@onready var _title_label: Label = %MenuTitleLabel
@onready var _rows_box: VBoxContainer = %RowsBox
@onready var _auto_button: Button = %AutoButton
@onready var _clear_button: Button = %ClearButton
@onready var _open_button: Button = %OpenButton


func get_open_button() -> Button:
	return _open_button


func setup(plan: MenuPlan, menu: DishCatalog, _fish_catalog: FishCatalog,
		variety_table: Array[float]) -> void:
	$Margin/VBox/HintLabel.hide()
	custom_minimum_size.x = 584
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	background.border_color = Color(1.0, 0.85, 0.3, 0.5)
	background.set_border_width_all(1)
	add_theme_stylebox_override("panel", background)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	self_modulate = Color.WHITE
	_plan = plan
	_menu = menu
	_variety_table = variety_table
	_buttons = _open_button.get_parent() as HBoxContainer
	_slots_box = HBoxContainer.new()
	_slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_box.add_theme_constant_override("separation", 8)
	_rows_box.add_child(_slots_box)
	_always_label = MenuSlotCard._label("")
	_rows_box.add_child(_always_label)
	_picker = MenuDishPicker.new()
	_picker.selected.connect(_select_dish)
	_picker.cancelled.connect(_close_picker)
	_rows_box.add_child(_picker)
	_picker.hide()
	_plan.changed.connect(_refresh)
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh()
		else:
			_close_picker())
	_auto_button.pressed.connect(func() -> void: _plan.auto_fill(_menu.dishes, GameState.storage))
	_clear_button.pressed.connect(func() -> void: _plan.clear(GameState.storage))
	_open_button.pressed.connect(func() -> void: confirmed.emit())
	_auto_button.text = "Tự chọn"
	_clear_button.text = "Xóa hết"
	var close_button := Button.new()
	close_button.text = "Đóng"
	close_button.pressed.connect(func() -> void:
		hide()
		closed.emit())
	_open_button.add_sibling(close_button)
	_refresh()


func _build_slots() -> void:
	for card in _cards:
		_slots_box.remove_child(card)
		card.queue_free()
	_cards.clear()
	_slot_dishes.resize(_plan.slots)
	for index in _plan.slots:
		var card := MenuSlotCard.new()
		card.picked.connect(func() -> void: _open_picker(index))
		card.added.connect(func() -> void:
			var dish := _slot_dishes[index]
			if dish:
				_plan.add_portion(dish, GameState.storage))
		card.removed.connect(func() -> void:
			var dish := _slot_dishes[index]
			if dish:
				_plan.remove_portion(dish, GameState.storage))
		_slots_box.add_child(card)
		_cards.append(card)


func _refresh() -> void:
	if _cards.size() != _plan.slots:
		_build_slots()
	var dishes := _plan.get_dishes()
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
		_cards[index].display(dish, _plan.get_portion_count(dish),
			_plan.can_add(dish, GameState.storage) if dish else false)
	var always: PackedStringArray = []
	for dish in _menu.dishes:
		if dish.on_menu_today():
			always.append(dish.display_name)
	_always_label.text = "Luôn có: %s · mua ở tạp hoá" % ", ".join(always)
	_clear_button.disabled = _plan.total_portions() == 0
	_auto_button.disabled = _menu.dishes.all(func(d: DishData) -> bool:
		return not _plan.can_add(d, GameState.storage))
	if _editing_slot < 0:
		_update_title()
	else:
		_picker.show_dishes(_menu, _plan, _slot_dishes[_editing_slot])


func _update_title() -> void:
	_title_label.text = "Menu hôm nay · %d/%d món · %d phần" % [
		_plan.used_slots(), _plan.slots, _plan.total_portions()]
	var variety := MenuPlan.variety_multiplier(_plan.variety_count(), _variety_table)
	if variety != 1.0:
		_title_label.text += " · giá x%s" % str(snappedf(variety, 0.01))


func _open_picker(index: int) -> void:
	_editing_slot = index
	_title_label.text = "Chọn món · ô %d" % (index + 1)
	_slots_box.hide()
	_always_label.hide()
	_buttons.hide()
	_picker.show_dishes(_menu, _plan, _slot_dishes[index])


func _select_dish(dish: DishData) -> void:
	var previous := _slot_dishes[_editing_slot]
	# Reserve the chosen slot before the model emits changed (including holes).
	_slot_dishes[_editing_slot] = dish
	if not _plan.replace_dish(previous, dish, GameState.storage):
		_slot_dishes[_editing_slot] = previous
		_refresh()
		return
	_close_picker()


func _close_picker() -> void:
	_editing_slot = -1
	if not is_instance_valid(_picker):
		return
	_picker.hide()
	_slots_box.show()
	_always_label.show()
	_buttons.show()
	_update_title()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _editing_slot >= 0 and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close_picker()
