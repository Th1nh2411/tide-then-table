class_name PhoneShop
extends ScrollContainer
## "Nâng cấp" tab of the phone: the gear shop app (like the shop apps on
## Dave's phone in Dave the Diver). One row per upgrade with its current and
## next effect and a buy button; usable anywhere. Purchases are "delivered"
## for the next trip / next shift (each system reads its level when it starts).
## Look: one white app card per upgrade (icon, name, level pips, "now ->
## next" in VT323 small) and a paper price-tag buy button with a coin.

## Upgrade id -> icon (others: "upgrade").
const ICONS := {"boat": "boat", "rod": "rod", "lamp": "lamp", "fridge": "crate", "kitchen": "pot",
	"seats": "people", "decor": "lantern"}

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
	var head := PhoneCards.header(box, "shop", "")
	_money_label = head.get_child(1) as Label
	head.tooltip_text = "Chợ đồ nghề: giao hàng cho chuyến / ca sau"
	head.mouse_filter = Control.MOUSE_FILTER_PASS
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
		var row := PhoneCards.card(_rows_box, 5)
		row.add_child(UiIcons.make(icon_for(upgrade), 16, PhoneCards.SEA))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 0)
		row.add_child(text)
		var title := HBoxContainer.new()
		title.add_theme_constant_override("separation", 4)
		text.add_child(title)
		title.add_child(PhoneCards.neo(upgrade.display_name, 10))
		var pips := PipBar.new()
		pips.pip_color = Color("4f8fba")
		pips.empty_color = Color(PhoneCards.INK, 0.25)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title.add_child(pips)
		var label := PhoneCards.neo("", 8, Color("577277"))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(label)
		var button := Button.new()
		button.theme_type_variation = &"PaperButton"
		button.custom_minimum_size = Vector2(54, 0)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", font_size + 1)
		UiIcons.dress(button, "money", 10, Color("de9e41"))
		button.pressed.connect(_buy.bind(upgrade))
		UiFx.hover_lift(button, 0.05)
		row.add_child(button)
		_rows[upgrade] = {"label": label, "button": button, "pips": pips}
	refresh()


func refresh() -> void:
	if _money_label == null:
		return
	_money_label.text = "%dk" % GameState.money
	for upgrade: UpgradeData in _rows:
		var widgets: Dictionary = _rows[upgrade]
		var level := GameState.get_upgrade_level(upgrade.id)
		var cost := upgrade.next_cost(level)
		var label: Label = widgets["label"]
		var button: Button = widgets["button"]
		(widgets["pips"] as PipBar).set_count(level, upgrade.max_level())
		button.tooltip_text = "Mua"
		if cost < 0:
			label.text = upgrade.label_at(level)
			button.text = "MAX"
			button.disabled = true
		else:
			label.text = "%s -> %s" % [upgrade.label_at(level), upgrade.label_at(level + 1)]
			button.text = "%dk" % cost
			button.disabled = GameState.money < cost


func _buy(upgrade: UpgradeData) -> void:
	if GameState.buy_upgrade(upgrade):
		refresh()


static func icon_for(upgrade: UpgradeData) -> String:
	for key: String in ICONS:
		if upgrade.id.begins_with(key):
			return str(ICONS[key])
	return "upgrade"
