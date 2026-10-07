class_name PhoneShop
extends ScrollContainer
## "Nâng cấp" tab of the phone: the gear shop app (like the shop apps on
## Dave's phone in Dave the Diver). One row per upgrade with its current and
## next effect and a buy button; usable anywhere. Purchases are "delivered"
## for the next trip / next shift (each system reads its level when it starts).

@export var font_size: int = 8

var upgrades: Array[UpgradeData] = []

var _rows_box: VBoxContainer
var _money_label: Label
## UpgradeData -> {"label": Label, "button": Button}
var _rows: Dictionary = {}


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	add_child(box)
	_money_label = _label("", Color(1, 0.9, 0.5))
	box.add_child(_money_label)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 3)
	box.add_child(_rows_box)
	GameState.money_changed.connect(func(_money: int) -> void: refresh())


## Builds the rows once `upgrades` is set (called by the phone).
func setup(list: Array[UpgradeData]) -> void:
	upgrades = list
	for child in _rows_box.get_children():
		child.queue_free()
	_rows.clear()
	for upgrade in upgrades:
		var row := HBoxContainer.new()
		var label := _label("", Color(0.9, 0.92, 0.95))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(62, 0)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", font_size)
		button.pressed.connect(_buy.bind(upgrade))
		row.add_child(button)
		_rows_box.add_child(row)
		_rows[upgrade] = {"label": label, "button": button}
	refresh()


func refresh() -> void:
	if _money_label == null:
		return
	_money_label.text = "CHỢ ĐỒ NGHỀ   Tiền: %dk   (giao hàng cho chuyến / ca sau)" % GameState.money
	for upgrade: UpgradeData in _rows:
		var widgets: Dictionary = _rows[upgrade]
		var level := GameState.get_upgrade_level(upgrade.id)
		var cost := upgrade.next_cost(level)
		var label: Label = widgets["label"]
		var button: Button = widgets["button"]
		if cost < 0:
			label.text = "%s: %s (tối đa)" % [upgrade.display_name, upgrade.label_at(level)]
			button.text = "Tối đa"
			button.disabled = true
		else:
			label.text = "%s: %s -> %s" % [upgrade.display_name, upgrade.label_at(level), upgrade.label_at(level + 1)]
			button.text = "Mua %dk" % cost
			button.disabled = GameState.money < cost


func _buy(upgrade: UpgradeData) -> void:
	if GameState.buy_upgrade(upgrade):
		refresh()


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
