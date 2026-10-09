class_name MarketPanel
extends PanelContainer
## Cô Năm's list (opened by E on the stall counter): one row per product
## (MarketStall.products) with how much Rin already has and two buy buttons
## with their price: one pack, and the cheaper bulk buy (number keys 1-9
## buy one, Shift + number buys bulk). E / Esc / "Đóng" closes it.
## The shift keeps running while it's open (Rin just stands there). Built in
## code.

signal closed

@export var stall: MarketStall
@export var font_size: int = 10

var _money_label: Label
var _rows: Array[Dictionary] = []  # {"dish", "have": Label, "buy": Button, "bulk": Button?}


func _ready() -> void:
	hide()
	position = Vector2(248, 150)  # below-left of the stall: Rin and the counter stay visible
	custom_minimum_size = Vector2(280, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(_label("Tạp hoá %s" % stall.seller_name))
	_money_label = _label("")
	box.add_child(_money_label)
	for dish in stall.products:
		if dish.unlock_day <= GameState.day:
			box.add_child(_build_row(_rows.size(), dish))
	var close := _button("Đóng (E)")
	close.pressed.connect(close_panel)
	box.add_child(close)
	stall.stock.changed.connect(_refresh)


func open_panel() -> void:
	_refresh()
	show()
	move_to_front()


func close_panel() -> void:
	hide()
	closed.emit()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close_panel()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var index := key.physical_keycode - KEY_1
		if index >= 0 and index < _rows.size():
			get_viewport().set_input_as_handled()
			stall.buy(_rows[index]["dish"], key.shift_pressed)


func _build_row(index: int, dish: DishData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(10, 10)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = dish.color
	row.add_child(swatch)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(_label("%d. %s" % [index + 1, dish.display_name]))
	var have := _label("")
	have.add_theme_font_size_override("font_size", font_size - 2)
	text.add_child(have)
	row.add_child(text)
	var entry := {"dish": dish, "have": have}
	entry["buy"] = _buy_button(dish, false, row)
	if dish.has_bulk():
		entry["bulk"] = _buy_button(dish, true, row)
	_rows.append(entry)
	return row


func _buy_button(dish: DishData, bulk: bool, row: HBoxContainer) -> Button:
	var button := _button(dish.buy_text(bulk))
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bulk:
		button.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
		button.tooltip_text = "Mua sỉ, rẻ hơn (Shift + số)"
	button.pressed.connect(func() -> void: stall.buy(dish, bulk))
	row.add_child(button)
	return button


func _refresh() -> void:
	_money_label.text = "Tiền: %dk" % GameState.money
	for row in _rows:
		var dish: DishData = row["dish"]
		var in_bag := stall.bag.count(dish)
		var fresh := stall.stock.freshness(dish)
		(row["have"] as Label).text = "tủ %d %s%s%s" % [stall.stock.count(dish), dish.unit_name,
			(" · tươi %d" % roundi(fresh)) if fresh < MarketStock.FULL_FRESHNESS and stall.stock.count(dish) > 0 else "",
			(" +%d túi" % in_bag) if in_bag > 0 else ""]
		(row["buy"] as Button).disabled = GameState.money < dish.buy_cost(false)
		if row.has("bulk"):
			(row["bulk"] as Button).disabled = GameState.money < dish.buy_cost(true)


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE  # Space must not press it
	button.add_theme_font_size_override("font_size", font_size)
	return button
