class_name RenovationMode
extends Control
## "Sửa quán": renovate the restaurant in place (only while not serving).
## People are hidden by the restaurant; every upgradable thing gets a pulsing
## green outline. Click one to list its levels; picking a level previews it
## right away. Bottom bar: Hủy (revert) / Xác nhận (pay the total shown).
## Only upgrades (no going back to a lower level). Built in code.

## `applied` = the player confirmed and paid.
signal finished(applied: bool)

@export var room: StreetRoom
@export var seats_upgrade: UpgradeData
@export var decor_upgrade: UpgradeData
@export var kitchen_upgrade: UpgradeData
@export var fridge_upgrade: UpgradeData
@export var outline_color: Color = Color(0.3, 1.0, 0.45)

## UpgradeData -> previewed level.
var _preview: Dictionary = {}
var _time: float = 0.0
var _options: PanelContainer
var _options_box: VBoxContainer
var _confirm_button: Button
var _title: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	hide()


func open() -> void:
	_preview.clear()
	for upgrade in _upgrades():
		_preview[upgrade] = GameState.get_upgrade_level(upgrade.id)
	_options.hide()
	_apply_preview()
	show()


## Total price of the previewed levels over the owned ones.
func total_cost() -> int:
	var total := 0
	for upgrade: UpgradeData in _preview:
		for level in range(GameState.get_upgrade_level(upgrade.id), int(_preview[upgrade])):
			total += upgrade.next_cost(level)
	return total


func _upgrades() -> Array[UpgradeData]:
	var list: Array[UpgradeData] = [seats_upgrade, decor_upgrade, kitchen_upgrade, fridge_upgrade]
	return list


## The clickable areas, in the same order as _upgrades().
func _areas() -> Array[Rect2]:
	var list: Array[Rect2] = [room.tables_area(), room.decor_area(), room.stove_area(), room.fridge_area()]
	return list


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var areas := _areas()
	for i in areas.size():
		if areas[i].has_point(click.position):
			accept_event()
			_show_options(_upgrades()[i], areas[i])
			return
	_options.hide()


func _show_options(upgrade: UpgradeData, area: Rect2) -> void:
	for child in _options_box.get_children():
		child.queue_free()
	var owned := GameState.get_upgrade_level(upgrade.id)
	var title := Label.new()
	title.text = upgrade.display_name
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	_options_box.add_child(title)
	for level in range(owned, upgrade.max_level() + 1):
		var cost := 0
		for l in range(owned, level):
			cost += upgrade.next_cost(l)
		var button := Button.new()
		var marker := "> " if int(_preview[upgrade]) == level else "   "
		button.text = "%s%s  %s" % [marker, upgrade.label_at(level), "(đang có)" if level == owned else "+%dk" % cost]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(func() -> void:
			_preview[upgrade] = level
			_apply_preview()
			_show_options(upgrade, area))
		_options_box.add_child(button)
	_options.reset_size()
	var at := Vector2(area.position.x, area.end.y + 4)
	if at.y + 90 > size.y - 40:
		at.y = area.position.y - 96
	_options.position = at.clamp(Vector2(4, 4), size - Vector2(190, 120))
	_options.show()


## Shows the previewed levels on the room (tables, decor, stove, fridge).
func _apply_preview() -> void:
	room.setup_tables(int(seats_upgrade.value_at(int(_preview[seats_upgrade]))))
	room.decor_level = int(decor_upgrade.value_at(int(_preview[decor_upgrade])))
	room.kitchen_level = int(_preview[kitchen_upgrade])
	room.fridge_level = int(_preview[fridge_upgrade])
	var cost := total_cost()
	_confirm_button.text = "Xác nhận" if cost == 0 else "Xác nhận (-%dk)" % cost
	_confirm_button.disabled = cost > GameState.money
	if cost > GameState.money:
		_confirm_button.text = "Thiếu tiền (%dk)" % cost


func _on_cancel() -> void:
	for upgrade: UpgradeData in _preview:
		_preview[upgrade] = GameState.get_upgrade_level(upgrade.id)
	_apply_preview()
	hide()
	finished.emit(false)


func _on_confirm() -> void:
	var cost := total_cost()
	if not GameState.spend_money(cost):
		return
	for upgrade: UpgradeData in _preview:
		GameState.upgrade_levels[upgrade.id] = int(_preview[upgrade])
	hide()
	finished.emit(true)


func _draw() -> void:
	var pulse := 0.6 + 0.4 * sin(_time * 4.0)
	var color := Color(outline_color, pulse)
	var font := ThemeDB.fallback_font
	var areas := _areas()
	var names: Array[String] = ["Bàn ghế", "Trang trí", "Bếp", "Thùng đá"]
	for i in areas.size():
		draw_rect(areas[i], color, false, 2.0)
		draw_string(font, areas[i].position + Vector2(3, 10), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)


func _build() -> void:
	_title = Label.new()
	_title.text = "SỬA QUÁN — bấm vào đồ có viền xanh"
	_title.position = Vector2(8, 4)
	_title.add_theme_font_size_override("font_size", 10)
	_title.add_theme_color_override("font_color", outline_color)
	add_child(_title)
	_options = PanelContainer.new()
	_options_box = VBoxContainer.new()
	_options.add_child(_options_box)
	add_child(_options)
	var bar := HBoxContainer.new()
	bar.position = Vector2(400, 326)
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)
	var cancel := Button.new()
	cancel.text = "Hủy"
	cancel.custom_minimum_size = Vector2(60, 26)
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(_on_cancel)
	bar.add_child(cancel)
	_confirm_button = Button.new()
	_confirm_button.custom_minimum_size = Vector2(150, 26)
	_confirm_button.focus_mode = Control.FOCUS_NONE
	_confirm_button.pressed.connect(_on_confirm)
	bar.add_child(_confirm_button)
