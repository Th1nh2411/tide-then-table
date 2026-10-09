class_name MenuSetupPanel
extends PanelContainer
## Pre-shift menu builder (Dave the Diver style). One row per dish with
## +/- portion buttons. Seafood dishes need a free menu slot and enough
## ingredients in storage. Always-available dishes (rau muống) aren't planned:
## a note line says they're on anyway (produce from the stall next door).
## Opened by clicking the LED sign (MenuBoard); "Đóng" hides it (the plan is
## kept), "Mở quán" opens the shop.

signal confirmed
signal closed

@export var font_size: int = 10
@export var swatch_size: Vector2 = Vector2(10, 10)
## Dims rows that can't be added and have no portions.
@export var unavailable_alpha: float = 0.45

var _plan: MenuPlan
var _menu: DishCatalog
var _fish_names: Dictionary = {}  # fish_id -> display name
var _variety_table: Array[float] = []
## DishData -> { "row", "stock", "count", "plus", "minus" }
var _rows: Dictionary = {}

@onready var _title_label: Label = %MenuTitleLabel
@onready var _rows_box: VBoxContainer = %RowsBox
@onready var _auto_button: Button = %AutoButton
@onready var _clear_button: Button = %ClearButton
@onready var _open_button: Button = %OpenButton


func setup(plan: MenuPlan, menu: DishCatalog, fish_catalog: FishCatalog,
		variety_table: Array[float]) -> void:
	$Margin/VBox/HintLabel.visible = GameState.is_first_day()
	_plan = plan
	_menu = menu
	_variety_table = variety_table
	for fish in fish_catalog.fish:
		_fish_names[fish.id] = fish.display_name
	for dish in menu.dishes:
		if dish.always_available:
			_rows_box.add_child(_label("%s · %dk: luôn có, mua ở tạp hoá bên cạnh (%s)" % [
				dish.display_name, dish.base_price, dish.market_text()], 0))
		else:
			_build_row(dish)
	_plan.changed.connect(_refresh)
	_auto_button.pressed.connect(func() -> void: _plan.auto_fill(_menu.dishes, GameState.storage))
	_clear_button.pressed.connect(func() -> void: _plan.clear(GameState.storage))
	_open_button.pressed.connect(func() -> void: confirmed.emit())
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

	var name_label := _label("%s · %dk" % [dish.display_name, dish.base_price], 150)
	row.add_child(name_label)
	var stock_label := _label("", 140)
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
	_title_label.text = "Chuẩn bị menu   (%d/%d món hải sản · %d phần)" % [
		_plan.used_slots(), _plan.slots, _plan.total_portions()]
	var variety := MenuPlan.variety_multiplier(_plan.variety_count(), _variety_table)
	if variety < 1.0:
		_title_label.text += "\nMenu đơn điệu: giá mọi món x%.1f (thêm món để hết phạt)" % variety
	var counts := KitchenLogic.count_by_fish(GameState.storage)
	for dish: DishData in _rows:
		var widgets: Dictionary = _rows[dish]
		var portions := _plan.get_portion_count(dish)
		var can_add := _plan.can_add(dish, GameState.storage)
		widgets.count.text = str(portions)
		widgets.plus.disabled = not can_add
		widgets.minus.disabled = portions == 0
		widgets.stock.text = _stock_text(dish, counts)
		widgets.row.modulate.a = 1.0 if can_add or portions > 0 else unavailable_alpha
	_clear_button.disabled = _plan.total_portions() == 0
	# Auto only plans seafood, so it's useless when no seafood dish can be added.
	_auto_button.disabled = _menu.dishes.all(func(d: DishData) -> bool:
		return not _plan.can_add(d, GameState.storage))
	_open_button.text = "Mở quán" if _plan.total_portions() > 0 else "Mở quán (chưa có hải sản)"
	if OS.is_debug_build() and GameState.storage.is_empty() and _plan.total_portions() == 0:
		_title_label.text += "\n[debug] Kho trống — F1: thêm cá mẫu, F2: thêm bia"


## e.g. "Ốc hương 3/phần · kho 5".
func _stock_text(dish: DishData, counts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for fish_id in dish.ingredients:
		parts.append("%s %d/phần · kho %d" % [
			_fish_names.get(fish_id, fish_id), dish.ingredients[fish_id], counts.get(fish_id, 0)])
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
