class_name MenuSetupPanel
extends PanelContainer
## Pre-shift menu builder (Dave the Diver style), kept short: a one-line
## title (slots, portions, variety penalty), one row per seafood dish that can
## be made or has portions (+/- buttons; the rest are hidden), one line for
## the always-available dishes (goods from the grocery next door).
## Opened by clicking the LED sign (MenuBoard); "Đóng" hides it (the plan is
## kept), "Mở quán" opens the shop.

signal confirmed
signal closed

@export var font_size: int = 10
@export var swatch_size: Vector2 = Vector2(10, 10)

var _plan: MenuPlan
var _menu: DishCatalog
var _variety_table: Array[float] = []
## DishData -> { "row", "stock", "count", "plus", "minus" }
var _rows: Dictionary = {}
var _empty_label: Label

@onready var _title_label: Label = %MenuTitleLabel
@onready var _rows_box: VBoxContainer = %RowsBox
@onready var _auto_button: Button = %AutoButton
@onready var _clear_button: Button = %ClearButton
@onready var _open_button: Button = %OpenButton


## The "Mở quán" button (RestaurantGuide points at it).
func get_open_button() -> Button:
	return _open_button


func setup(plan: MenuPlan, menu: DishCatalog, _fish_catalog: FishCatalog,
		variety_table: Array[float]) -> void:
	$Margin/VBox/HintLabel.visible = false  # first-time pointers teach it (RestaurantGuide)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.09, 0.12, 0.97)
	background.border_color = Color(1.0, 0.85, 0.3, 0.5)
	background.set_border_width_all(1)
	add_theme_stylebox_override("panel", background)
	self_modulate = Color.WHITE
	_plan = plan
	_menu = menu
	_variety_table = variety_table
	var always: PackedStringArray = []
	for dish in menu.dishes:
		if dish.always_available:
			if dish.on_menu_today():
				always.append(dish.display_name)
		else:
			_build_row(dish)
	_empty_label = _label("Kho chưa có hải sản: ra khơi câu cá đã.", 0)
	_rows_box.add_child(_empty_label)
	if not always.is_empty():
		var note := _label("Luôn có: %s (mua ở tạp hoá)" % ", ".join(always), 0)
		note.modulate = Color(0.75, 0.75, 0.8)
		_rows_box.add_child(note)
	_plan.changed.connect(_refresh)
	_auto_button.pressed.connect(func() -> void: _plan.auto_fill(_menu.dishes, GameState.storage))
	_clear_button.pressed.connect(func() -> void: _plan.clear(GameState.storage))
	_open_button.pressed.connect(func() -> void: confirmed.emit())
	_auto_button.text = "Tự chọn"
	_clear_button.text = "Xóa"
	var close_button := Button.new()
	close_button.text = "Đóng"
	close_button.pressed.connect(func() -> void:
		hide()
		closed.emit())
	_open_button.add_sibling(close_button)
	_refresh()
	_open_button.grab_focus()


func _build_row(dish: DishData) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = swatch_size
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = dish.color
	row.add_child(swatch)

	var name_label := _label("%s %dk" % [dish.display_name, dish.base_price], 140)
	row.add_child(name_label)
	var stock_label := _label("", 90)
	row.add_child(stock_label)

	var minus := _button("−")
	minus.pressed.connect(func() -> void: _plan.remove_portion(dish, GameState.storage))
	row.add_child(minus)
	var count_label := _label("0", 22)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(count_label)
	var plus := _button("+")
	plus.pressed.connect(func() -> void: _plan.add_portion(dish, GameState.storage))
	row.add_child(plus)

	_rows_box.add_child(row)
	_rows[dish] = {"row": row, "stock": stock_label, "count": count_label, "plus": plus, "minus": minus}


func _refresh() -> void:
	_title_label.text = "Menu hôm nay · %d/%d món · %d phần" % [
		_plan.used_slots(), _plan.slots, _plan.total_portions()]
	var variety := MenuPlan.variety_multiplier(_plan.variety_count(), _variety_table)
	if variety != 1.0:
		_title_label.text += " · %s x%s" % ["đơn điệu" if variety < 1.0 else "đa dạng", str(snappedf(variety, 0.01))]
	var shown := 0
	var counts := KitchenLogic.count_by_fish(GameState.storage)
	for dish: DishData in _rows:
		var widgets: Dictionary = _rows[dish]
		var portions := _plan.get_portion_count(dish)
		var can_add := _plan.can_add(dish, GameState.storage)
		widgets.count.text = str(portions)
		widgets.plus.disabled = not can_add
		widgets.minus.disabled = portions == 0
		widgets.stock.text = _stock_text(dish, counts)
		widgets.row.visible = can_add or portions > 0
		shown += 1 if widgets.row.visible else 0
	_empty_label.visible = shown == 0
	_clear_button.disabled = _plan.total_portions() == 0
	# Auto only plans seafood, so it's useless when no seafood dish can be added.
	_auto_button.disabled = _menu.dishes.all(func(d: DishData) -> bool:
		return not _plan.can_add(d, GameState.storage))
	_open_button.text = "Mở quán"
	if OS.is_debug_build() and GameState.storage.is_empty() and _plan.total_portions() == 0:
		_empty_label.text = "Kho trống. [debug] F1: cá mẫu · F2: bia"


## e.g. "kho 5 (3/phần)": fish in storage, fish per portion.
func _stock_text(dish: DishData, counts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for fish_id in dish.ingredients:
		parts.append("kho %d (%d/phần)" % [counts.get(fish_id, 0), dish.ingredients[fish_id]])
	return ", ".join(parts)


func _label(text: String, min_width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = min_width
	label.add_theme_font_size_override("font_size", font_size)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(20, 0)
	button.add_theme_font_size_override("font_size", font_size)
	return button
