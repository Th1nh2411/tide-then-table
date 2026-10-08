class_name MarketPanel
extends PanelContainer
## Cô Năm's list (opened by E on the stall counter): one row per product
## (MarketStall.products) with its price (per portion or per crate), how many portions Rin already has
## and a "Mua" button (or number keys 1-9). E / Esc / "Đóng" closes it.
## The shift keeps running while it's open (Rin just stands there). Built in
## code.

signal closed

@export var stall: MarketStall
@export var font_size: int = 10

var _money_label: Label
var _rows: Array[Dictionary] = []  # {"dish", "have": Label, "buy": Button}


func _ready() -> void:
	hide()
	position = Vector2(248, 150)  # below-left of the stall: Rin and the counter stay visible
	custom_minimum_size = Vector2(230, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(_label("Tạp hoá %s" % stall.seller_name))
	_money_label = _label("")
	box.add_child(_money_label)
	for i in stall.products.size():
		box.add_child(_build_row(i, stall.products[i]))
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
			stall.buy(_rows[index]["dish"])


func _build_row(index: int, dish: DishData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(10, 10)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = dish.color
	row.add_child(swatch)
	var name_label := _label("%d. %s · %s" % [index + 1, dish.display_name, dish.market_text()])
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var have := _label("")
	row.add_child(have)
	var buy := _button("Mua")
	buy.pressed.connect(func() -> void: stall.buy(dish))
	row.add_child(buy)
	_rows.append({"dish": dish, "have": have, "buy": buy})
	return row


func _refresh() -> void:
	_money_label.text = "Tiền: %dk" % GameState.money
	for row in _rows:
		var dish: DishData = row["dish"]
		var in_bag := stall.bag.count(dish)
		(row["have"] as Label).text = "tủ %d%s" % [stall.stock.count(dish), (" +%d túi" % in_bag) if in_bag > 0 else ""]
		(row["buy"] as Button).disabled = GameState.money < dish.market_cost


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
