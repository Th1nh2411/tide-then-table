class_name KitchenStation
extends Control
## The kitchen inside the restaurant (Dave the Diver / Overcooked style, no
## pop-up screens). Rin walks into the kitchen corner (x <= zone_right):
##   1-9 / click  cook dish N of the numbered menu board on the kitchen wall
##                (compact CookingOverlay above the stove)
##   E at shelf   pick up the plate Rin stands in front of (marked)
##   E at bin     throw away the carried plate
## Also draws the order ticket rail along the top. Plates go on the shelf
## (CustomerManager.shelf); snacks are instant. Only works while serving.

signal message_requested(text: String)

@export var cooking: CookingOverlay
@export var customers: CustomerManager
@export var menu: DishCatalog
@export var rin: RinWalker
@export var shelf_display: ShelfDisplay
## Rin's x at or below this = in the kitchen.
@export var zone_right: float = 162.0
## Standing near the bin throws the carried plate away.
@export var bin_x: float = 30.0
@export var spot_reach: float = 14.0
## Menu board on the kitchen wall: one numbered row per dish.
@export var board_origin: Vector2 = Vector2(34, 56)
@export var row_size: Vector2 = Vector2(124, 11)
@export var rail_origin: Vector2 = Vector2(8, 26)
@export var ticket_size: Vector2 = Vector2(56, 16)
@export var max_tickets: int = 8

## Plate on the shelf in front of Rin (null = none), marked with an arrow.
var shelf_pick: DishShelf.Plate

var _plan: MenuPlan
## Board rows: {"label", "count", "dish", "kind": "menu"|"regular"|"snack", "visit"?}.
## Menu dishes stay listed at 0 so the numbers don't shift.
var _trays: Array[Dictionary] = []
var _cooking_tray: Dictionary = {}
var _cooking_items: Array[InventoryItem] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	cooking.finished.connect(_on_cooking_finished)


func setup(plan: MenuPlan) -> void:
	_plan = plan


func is_open() -> bool:
	return rin.kitchen_open and _plan != null


func is_rin_inside() -> bool:
	return rin.position_x() <= zone_right


func is_at_bin() -> bool:
	return absf(rin.position_x() - bin_x) <= spot_reach * 2.0


func row_rect(i: int) -> Rect2:
	return Rect2(board_origin + Vector2(0, i * row_size.y), row_size - Vector2(0, 1))


func ticket_rect(i: int) -> Rect2:
	return Rect2(rail_origin + Vector2(i * (ticket_size.x + 3), 0), ticket_size)


func _take(plate: DishShelf.Plate) -> void:
	rin.carried = plate
	customers.shelf.remove(plate)
	shelf_pick = null


## E in the kitchen (RinWalker forwards it): bin or shelf by position.
func act() -> void:
	if cooking.is_running():
		return
	if rin.carried:
		if is_at_bin():
			rin.carried = null
		elif customers.shelf.add(rin.carried):
			rin.carried = null
		else:
			message_requested.emit("Kệ đầy")
		return
	if shelf_pick:
		_take(shelf_pick)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not rin.active or not is_rin_inside() or cooking.is_running():
		return
	var index := -1
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		index = key.physical_keycode - KEY_1
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		for i in _trays.size():
			if row_rect(i).has_point(click.position):
				index = i
	if index >= 0 and index < mini(_trays.size(), 9):
		get_viewport().set_input_as_handled()
		_cook(_trays[index])


func _process(_delta: float) -> void:
	_build_trays()
	var index := shelf_display.plate_index_at(rin.position_x())
	shelf_pick = customers.shelf.plates[index] if index >= 0 and is_rin_inside() else null
	queue_redraw()


# --- Cooking ---------------------------------------------------------------

func _cook(tray: Dictionary) -> void:
	if cooking.is_running():
		return
	if customers.shelf.is_full():
		message_requested.emit("Kệ đầy! Bưng bớt ra hoặc vứt món thừa.")
		return
	var dish: DishData = tray["dish"]
	var items: Array[InventoryItem] = []
	match tray["kind"]:
		"menu":
			if _plan.get_portion_count(dish) <= 0:
				message_requested.emit("Hết %s" % dish.display_name)
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


func _build_trays() -> void:
	_trays.clear()
	if _plan == null:
		return
	for dish in _plan.get_dishes():
		_trays.append({"label": dish.display_name, "count": _plan.get_portion_count(dish), "dish": dish, "kind": "menu"})
	for dish in menu.dishes:
		if dish.always_available:
			_trays.append({"label": dish.display_name, "count": -1, "dish": dish, "kind": "snack"})
	# Regulars last: they come and go during the shift.
	for visit in customers.regular_visits:
		if not visit.get("cooked", false):
			_trays.append({"label": "%s (%s)" % [visit["dish"].display_name, visit["order"]["who"]],
				"count": 1, "dish": visit["dish"], "kind": "regular", "visit": visit})


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	if not is_open():
		return
	var font := ThemeDB.fallback_font
	_draw_tickets(font)
	# Numbered menu board (dim while Rin is out of the kitchen).
	var inside := is_rin_inside()
	for i in mini(_trays.size(), 9):
		var tray := _trays[i]
		var rect := row_rect(i)
		var count: int = tray["count"]
		var empty := count == 0
		var ink := Color(1, 0.95, 0.85, 1.0 if inside and not empty else 0.45)
		draw_rect(rect, Color(0.1, 0.12, 0.1, 0.75))
		if tray["kind"] == "regular":
			draw_rect(rect, Color(1.0, 0.8, 0.3, 0.9), false, 1.0)
		# Number keycap, dish color chip, name, portions left.
		draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(8, 8)), Color(1, 1, 1, ink.a))
		draw_string(font, rect.position + Vector2(2.5, 8), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.1, 0.1, 0.1))
		draw_rect(Rect2(rect.position + Vector2(11, 3), Vector2(4, 4)), Color((tray["dish"] as DishData).color, ink.a))
		draw_string(font, rect.position + Vector2(18, 8), tray["label"], HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 36, 7, ink)
		if count >= 0:  # snacks never run out: no number
			draw_string(font, rect.position + Vector2(rect.size.x - 16, 8), "x%d" % count,
				HORIZONTAL_ALIGNMENT_RIGHT, 14, 7, ink)


func _draw_tickets(font: Font) -> void:
	for i in mini(customers.waiting.size(), max_tickets):
		var customer := customers.waiting[i]
		var rect := ticket_rect(i)
		var ready := customers.shelf.find_for(customer.dish, customer.visit) != null
		draw_rect(rect, Color(1.0, 0.97, 0.88))
		draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(6, 6)), customer.dish.color)
		draw_string(font, rect.position + Vector2(10, 8), "B%d" % (customer.seat + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.2, 0.15, 0.1))
		draw_rect(Rect2(rect.position + Vector2(2, ticket_size.y - 4), Vector2((ticket_size.x - 4) * customer.patience, 2)),
			Color(1, 0.3, 0.3).lerp(Color(0.3, 0.8, 0.4), customer.patience))
		if ready:
			draw_rect(rect, Color(0.3, 0.9, 0.4), false, 2.0)
		if customer.regular_name:
			draw_rect(rect, Color(1.0, 0.8, 0.3), false, 1.0)
