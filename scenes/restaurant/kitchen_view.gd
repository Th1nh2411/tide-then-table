class_name KitchenView
extends CanvasLayer
## The kitchen screen Rin opens at the kitchen door (time keeps running, like
## Dave the Diver). Top: waiting orders in arrival order. Left: trays of
## prepared ingredients — one per menu dish (portions from menu planning),
## the snack, and a regular's reserved fish. Click a tray (or 1-9) to cook it
## (cooking minigame; snacks are instant); the plate goes on the shelf.
## Right: the shelf — select a plate to throw it in the bin or to carry it
## out yourself. E / Esc leaves the kitchen. Built in code.

signal closed
## The player took a plate to carry out.
signal carry_requested(plate: DishShelf.Plate)

@export var cooking: CookingOverlay
@export var customers: CustomerManager
@export var menu: DishCatalog
@export var max_tickets: int = 6

var _plan: MenuPlan
## Tray entries: {"label", "dish", "kind": "menu"|"snack"|"regular", "visit"?}.
var _trays: Array[Dictionary] = []
var _selected: DishShelf.Plate
var _cooking_tray: Dictionary = {}
var _cooking_items: Array[InventoryItem] = []
var _signature: String = ""
var _message_token: int = 0

var _tickets_label: Label
var _trays_box: VBoxContainer
var _shelf_box: VBoxContainer
var _trash_button: Button
var _carry_button: Button
var _message_label: Label
var _hint: Label


func _ready() -> void:
	layer = 8
	_build()
	hide()
	cooking.finished.connect(_on_cooking_finished)


func open(plan: MenuPlan) -> void:
	_plan = plan
	_selected = null
	_signature = ""
	_hint.visible = GameState.is_first_day()
	show()


func close() -> void:
	hide()
	closed.emit()


func _process(_delta: float) -> void:
	if not visible:
		return
	_tickets_label.text = _tickets_text()
	_build_trays()
	var signature := _rebuild_signature()
	if signature != _signature:
		_signature = signature
		_refresh_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or cooking.is_running():
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var index := key.physical_keycode - KEY_1
		if index >= 0 and index < _trays.size():
			get_viewport().set_input_as_handled()
			_cook(_trays[index])


# --- Cooking -------------------------------------------------------------

func _cook(tray: Dictionary) -> void:
	if cooking.is_running():
		return
	if customers.shelf.is_full():
		_show_message("Kệ đầy! Chờ Bảo bưng bớt, hoặc vứt món thừa.")
		return
	var dish: DishData = tray["dish"]
	var items: Array[InventoryItem] = []
	match tray["kind"]:
		"menu":
			if _plan.get_portion_count(dish) <= 0:
				return
			items = _plan.take_portion(dish)
		"regular":
			var visit: Dictionary = tray["visit"]
			visit["cooked"] = true
			items.append(visit["item"])
	if dish.instant_serve:
		customers.shelf.add(DishShelf.Plate.new(dish, items, 1.0))
		return
	_cooking_tray = tray
	_cooking_items = items
	cooking.start(dish)


func _on_cooking_finished(dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	if _cooking_tray.is_empty():
		return
	var visit: Dictionary = _cooking_tray.get("visit", {})
	customers.shelf.add(DishShelf.Plate.new(dish, _cooking_items, multiplier, visit))
	_cooking_tray = {}
	_cooking_items = []


# --- Trays / shelf / tickets ---------------------------------------------

func _build_trays() -> void:
	_trays.clear()
	if _plan == null:
		return
	for dish in _plan.get_dishes():
		if _plan.get_portion_count(dish) > 0:
			_trays.append({"label": "%s  x%d" % [dish.display_name, _plan.get_portion_count(dish)],
				"dish": dish, "kind": "menu"})
	for visit in customers.regular_visits:
		if not visit.get("cooked", false):
			var dish: DishData = visit["dish"]
			_trays.append({"label": "%s  (đơn %s)" % [dish.display_name, visit["order"]["who"]],
				"dish": dish, "kind": "regular", "visit": visit})
	for dish in menu.dishes:
		if dish.always_available:
			_trays.append({"label": "%s  (luôn có)" % dish.display_name, "dish": dish, "kind": "snack"})


func _tickets_text() -> String:
	if customers.waiting.is_empty():
		return "ĐƠN ĐANG CHỜ: (chưa có)"
	var parts: PackedStringArray = []
	for i in mini(customers.waiting.size(), max_tickets):
		var customer := customers.waiting[i]
		var on_shelf := customers.shelf.find_for(customer.dish, customer.visit) != null
		parts.append("%d. Bàn %d %s %d%%%s" % [i + 1, customer.seat + 1, customer.dish.display_name,
			roundi(customer.patience * 100), " (có trên kệ)" if on_shelf else ""])
	if customers.waiting.size() > max_tickets:
		parts.append("+%d" % (customers.waiting.size() - max_tickets))
	return "ĐƠN ĐANG CHỜ:  " + "   ".join(parts)


func _rebuild_signature() -> String:
	var parts: PackedStringArray = []
	for tray in _trays:
		parts.append(tray["label"])
	parts.append("|")
	for plate in customers.shelf.plates:
		parts.append(str(plate.get_instance_id()))
	parts.append("|%s" % (_selected.get_instance_id() if _selected else 0))
	return ",".join(parts)


func _refresh_buttons() -> void:
	for child in _trays_box.get_children():
		child.queue_free()
	for i in _trays.size():
		var tray := _trays[i]
		var button := _button("[%d] %s" % [i + 1, tray["label"]])
		button.pressed.connect(_cook.bind(tray))
		_trays_box.add_child(button)
	for child in _shelf_box.get_children():
		child.queue_free()
	if not customers.shelf.plates.has(_selected):
		_selected = null
	for plate in customers.shelf.plates:
		var label := plate.dish.display_name + ("  (đơn %s)" % plate.visit["order"]["who"] if not plate.visit.is_empty() else "")
		var button := _button(("> " if plate == _selected else "") + label)
		button.pressed.connect(func() -> void: _selected = null if _selected == plate else plate)
		_shelf_box.add_child(button)
	for i in customers.shelf.capacity - customers.shelf.plates.size():
		var empty := _button("(trống)")
		empty.disabled = true
		_shelf_box.add_child(empty)
	_trash_button.disabled = _selected == null
	_carry_button.disabled = _selected == null


func _on_trash_pressed() -> void:
	if _selected:
		customers.shelf.remove(_selected)
		_show_message("Đã vứt %s vào sọt rác." % _selected.dish.display_name)
		_selected = null


func _on_carry_pressed() -> void:
	if _selected:
		var plate := _selected
		customers.shelf.remove(plate)
		_selected = null
		close()
		carry_requested.emit(plate)


func _show_message(text: String) -> void:
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	await get_tree().create_timer(2.0).timeout
	if token == _message_token:
		_message_label.text = ""


# --- UI ------------------------------------------------------------------

func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 10
	panel.offset_top = 10
	panel.offset_right = -10
	panel.offset_bottom = -10
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	_tickets_label = _label("", 9, Color(1.0, 0.9, 0.6))
	_tickets_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_tickets_label)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	box.add_child(columns)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_label("BÀN SƠ CHẾ", 10, Color(0.7, 0.9, 1.0)))
	_trays_box = VBoxContainer.new()
	left.add_child(_trays_box)
	columns.add_child(left)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_label("KỆ BẾP", 10, Color(0.7, 0.9, 1.0)))
	_shelf_box = VBoxContainer.new()
	right.add_child(_shelf_box)
	var actions := HBoxContainer.new()
	_trash_button = _button("Vứt vào sọt rác")
	_trash_button.pressed.connect(_on_trash_pressed)
	actions.add_child(_trash_button)
	_carry_button = _button("Rin cầm ra bưng")
	_carry_button.pressed.connect(_on_carry_pressed)
	actions.add_child(_carry_button)
	right.add_child(actions)
	columns.add_child(right)

	_message_label = _label("", 9, Color(1.0, 0.6, 0.5))
	box.add_child(_message_label)
	_hint = _label("Phím số / click khay để nấu · chọn món trên kệ rồi vứt hoặc cầm ra · E / Esc: ra khỏi bếp",
		8, Color(0.6, 0.65, 0.7))
	box.add_child(_hint)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	return button
