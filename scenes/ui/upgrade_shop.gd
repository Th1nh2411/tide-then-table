class_name UpgradeShop
extends PanelContainer
## End-of-day upgrade shop. One row per upgrade: current effect, next effect
## and a buy button. Purchases take effect from the next day.

signal finished

@export var upgrades: Array[UpgradeData] = []
@export var font_size: int = 10

## UpgradeData -> { "level": Label, "button": Button }
var _rows: Dictionary = {}

@onready var _money_label: Label = %ShopMoneyLabel
@onready var _rows_box: VBoxContainer = %ShopRows
@onready var _done_button: Button = %ShopDoneButton


func _ready() -> void:
	hide()
	for upgrade in upgrades:
		_build_row(upgrade)
	_done_button.pressed.connect(func() -> void:
		hide()
		finished.emit())


func open() -> void:
	_refresh()
	show()
	_done_button.grab_focus()


func _build_row(upgrade: UpgradeData) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size.x = 300
	text_box.add_theme_constant_override("separation", 0)
	var name_label := _label("%s — %s" % [upgrade.display_name, upgrade.description], font_size)
	text_box.add_child(name_label)
	var level_label := _label("", font_size - 1)
	level_label.modulate = Color(0.85, 0.85, 0.85)
	text_box.add_child(level_label)
	row.add_child(text_box)

	var button := Button.new()
	button.custom_minimum_size = Vector2(90, 0)
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(func() -> void:
		if GameState.buy_upgrade(upgrade):
			_refresh())
	row.add_child(button)

	_rows_box.add_child(row)
	_rows[upgrade] = {"level": level_label, "button": button}


func _refresh() -> void:
	_money_label.text = "Tiền: %dk   (nâng cấp có hiệu lực từ ngày mai)" % GameState.money
	for upgrade: UpgradeData in _rows:
		var widgets: Dictionary = _rows[upgrade]
		var level := GameState.get_upgrade_level(upgrade.id)
		var cost := upgrade.next_cost(level)
		if cost < 0:
			widgets.level.text = "Cấp %d/%d: %s (tối đa)" % [level, upgrade.max_level(), upgrade.label_at(level)]
			widgets.button.text = "Tối đa"
			widgets.button.disabled = true
		else:
			widgets.level.text = "Cấp %d/%d: %s  →  %s" % [
				level, upgrade.max_level(), upgrade.label_at(level), upgrade.label_at(level + 1)]
			widgets.button.text = "Mua %dk" % cost
			widgets.button.disabled = GameState.money < cost


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
