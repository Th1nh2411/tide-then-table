class_name KitchenStation
extends Node
## Rin's kitchen on the street restaurant (no pop-up screens):
##   1-9 / click a menu chip   near the cart (room.kitchen_area): Rin walks
##                             behind the stove, faces the road, then the
##                             compact CookingOverlay minigame starts; the
##                             cooked dish ends up in her hands
##   E on the plate table      put the plate on that cell / pick that one up
##   E on the bin              throw the carried plate away
##   E on a table              serve the carried plate, or clean it if dirty
## Menu rows (`trays()`): today's dishes (numbers never shift, 0 = sold out),
## always-available dishes (count = produce bought at the stall; none left =
## Rin must go and buy more), then regulars' reserved fish. Only while serving.

signal message_requested(text: String)

@export var cooking: CookingOverlay
@export var customers: CustomerManager
@export var menu: DishCatalog
@export var rin: RinChef
@export var room: StreetRoom
@export var stall: MarketStall
@export var clean_seconds: float = 0.5

## Walking to the stove, cooking or cleaning: Rin can't move.
var busy: bool = false

var _plan: MenuPlan
var _cooking_tray: Dictionary = {}
var _cooking_items: Array[InventoryItem] = []


func _ready() -> void:
	cooking.finished.connect(_on_cooking_finished)


func setup(plan: MenuPlan) -> void:
	_plan = plan


func is_open() -> bool:
	return rin.kitchen_open and _plan != null


func is_rin_near() -> bool:
	return room.kitchen_area.has_point(rin.cell())


## The menu chips light up and dish keys work.
func can_cook() -> bool:
	return is_open() and is_rin_near() and not busy and not cooking.is_running()


## Where Rin stands to cook: behind the stove, facing the road.
func stove_spot() -> Vector2i:
	return room.stove_cell() + Vector2i.UP


## Menu rows: {"label", "count" (-1 = endless), "dish", "kind", "visit"?}.
func trays() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if _plan == null:
		return rows
	for dish in _plan.get_dishes():
		rows.append({"label": dish.display_name, "count": _plan.get_portion_count(dish), "dish": dish, "kind": "menu"})
	for dish in menu.dishes:
		if dish.always_available:
			rows.append({"label": dish.display_name, "count": stall.stock.count(dish), "dish": dish, "kind": "side"})
	for visit in customers.regular_visits:
		if not visit.get("cooked", false):
			rows.append({"label": "%s (%s)" % [visit["dish"].display_name, visit["order"]["who"]],
				"count": 1, "dish": visit["dish"], "kind": "regular", "visit": visit})
	return rows


func cook(index: int) -> void:
	var rows := trays()
	if not can_cook() or index < 0 or index >= rows.size():
		return
	if rin.carried:
		message_requested.emit("Tay đang cầm món")
		return
	var tray := rows[index]
	var dish: DishData = tray["dish"]
	var items: Array[InventoryItem] = []
	match tray["kind"]:
		"menu":
			if _plan.get_portion_count(dish) <= 0:
				message_requested.emit("Hết %s" % dish.display_name)
				return
			items = _plan.take_portion(dish)
		"side":
			if not stall.stock.take(dish):
				message_requested.emit("Hết nguyên liệu %s: sang sạp %s mua" % [dish.display_name, stall.seller_name])
				return
		"regular":
			var visit: Dictionary = tray["visit"]
			visit["cooked"] = true
			items.append(visit["item"])
	busy = true
	_cooking_tray = tray
	_cooking_items = items
	await rin.walk_and_wait(room.grid.path(rin.cell(), stove_spot()))
	rin.facing = Vector2i.DOWN
	cooking.start(dish)


func _on_cooking_finished(dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	if _cooking_tray.is_empty():
		return
	var visit: Dictionary = _cooking_tray.get("visit", {})
	rin.carried = DishShelf.Plate.new(dish, _cooking_items, multiplier, visit)
	_cooking_tray = {}
	_cooking_items = []
	busy = false


## E on `cell` while serving; false = nothing to do there.
func interact(cell: Vector2i) -> bool:
	if not is_open() or busy:
		return false
	var slot := room.pass_slot(cell)
	if slot >= 0:
		var plate := customers.shelf.plate_at(slot)
		if rin.carried and plate == null:
			customers.shelf.add(rin.carried, slot)
			rin.carried = null
			return true
		if not rin.carried and plate:
			customers.shelf.remove(plate)
			rin.carried = plate
			return true
		return false
	if room.grid.kind(cell) == "B" and rin.carried:
		rin.carried = null
		return true
	var seat := room.table_index(cell)
	if seat < 0:
		return false
	if rin.carried:
		if customers.serve_at(seat, rin.carried):
			rin.carried = null
		else:
			message_requested.emit("Bàn %d không gọi món này" % (seat + 1))
		return true
	if room.dining.states[seat] == DiningTables.State.DIRTY:
		_clean(seat)
		return true
	return false


func _clean(seat: int) -> void:
	busy = true
	await get_tree().create_timer(clean_seconds).timeout
	room.dining.clean(seat)
	busy = false


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and can_cook() and rin.active:
		var index := key.physical_keycode - KEY_1
		if index >= 0 and index < mini(trays().size(), 9):
			get_viewport().set_input_as_handled()
			cook(index)
