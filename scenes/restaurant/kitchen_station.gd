class_name KitchenStation
extends Node
## Rin's side of the kitchen on the street restaurant (no pop-up screens, no
## dish buttons). Bảo (ChefBao) cooks everything else by himself; Rin grills
## and pours, always for the oldest ticket still missing its plate:
##   E on the charcoal grill   the oldest waiting grilled dish: Rin steps
##                             behind the grill, faces the road, the compact
##                             CookingOverlay minigame starts and the dish ends
##                             up in his hands
##   E on the beer tap         a beer tower for the oldest table that ordered
##                             one (needs beer from the grocery): the pour
##                             minigame (BeerPourGame) runs in the same
##                             overlay, the tower ends up in his hands;
##                             spilling wastes `spill_litres`
##   E on the plate table      put the plate on that cell / pick that one up
##   E on the bin              throw the carried plate away
##   E on a table              serve the carried plate, or clean it if dirty
## `menu_rows()` (for the LED board, "who" = "rin" / "bao"): today's dishes
## (0 = sold out), always-available dishes (servings left from the grocery
## goods), then regulars' reserved fish not cooked yet. Only while serving.

signal message_requested(text: String)

@export var cooking: CookingOverlay
@export var customers: CustomerManager
@export var menu: DishCatalog
@export var rin: RinChef
@export var room: StreetRoom
@export var stall: MarketStall
@export var clean_seconds: float = 0.5
## Beer lost each time a tower runs over.
@export var spill_litres: int = 1

## Walking to the grill, grilling, pouring or cleaning: Rin can't move.
var busy: bool = false

var _plan: MenuPlan
var _cooking_visit: Dictionary = {}
var _cooking_items: Array[InventoryItem] = []


func _ready() -> void:
	cooking.finished.connect(_on_cooking_finished)
	cooking.spilled.connect(_on_spilled)


func setup(plan: MenuPlan) -> void:
	_plan = plan


func is_open() -> bool:
	return rin.kitchen_open and _plan != null


func is_rin_near() -> bool:
	return room.kitchen_area.has_point(rin.cell())


## Where Rin stands to grill: behind the charcoal grill, facing the road.
func grill_spot() -> Vector2i:
	return room.grill_cell() + Vector2i.UP


## Every menu row: {"label", "count", "dish", "kind", "who", "visit"?}.
func menu_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if _plan == null:
		return rows
	for dish in _plan.get_dishes():
		rows.append(_row(dish.display_name, _plan.get_portion_count(dish), dish, "menu"))
	for dish in menu.dishes:
		if dish.on_menu_today():
			rows.append(_row(dish.display_name, stall.stock.portions(dish), dish, "side"))
	for visit in customers.regular_visits:
		if not visit.get("cooked", false):
			var row := _row("%s (%s)" % [visit["dish"].display_name, visit["order"]["who"]], 1, visit["dish"], "regular")
			row["visit"] = visit
			rows.append(row)
	return rows


func _row(label: String, count: int, dish: DishData, kind: String) -> Dictionary:
	return {"label": label, "count": count, "dish": dish, "kind": kind, "who": "bao" if ChefBao.cooks(dish) else "rin"}


## The oldest waiting line whose grilled dish (or drink) has no plate yet;
## null if none.
func next_order(drinks: bool) -> TableOrder:
	for order in customers.waiting:
		var dish := order.dish
		if ChefBao.cooks(dish) or dish.instant_serve != drinks:
			continue
		if not order.visit.is_empty():
			if not order.visit.get("cooked", false):
				return order
		elif _needs_more(dish):
			return order
	return null


## More lines wait for `dish` than plates exist (plate table, staff and Rin's hands).
func _needs_more(dish: DishData) -> bool:
	var waiting := customers.waiting.filter(func(o: TableOrder) -> bool: return o.dish == dish and o.visit.is_empty()).size()
	var plates := customers.plates_ready(dish)
	if rin.carried and rin.carried.dish == dish and rin.carried.visit.is_empty():
		plates += 1
	return waiting > plates


## E on the grill: grill the oldest waiting grilled dish.
func grill() -> void:
	var order := next_order(false)
	if order == null:
		message_requested.emit("Chưa bàn nào chờ món nướng")
		return
	var dish := order.dish
	var items: Array[InventoryItem] = []
	if not order.visit.is_empty():
		order.visit["cooked"] = true
		items.append(order.visit["item"])
	elif _plan.get_portion_count(dish) > 0:
		items = _plan.take_portion(dish)
	else:
		message_requested.emit("Hết %s" % dish.display_name)
		return
	busy = true
	_cooking_visit = order.visit
	_cooking_items = items
	await rin.walk_and_wait(room.grid.path(rin.cell(), grill_spot()))
	rin.facing = Vector2i.DOWN
	cooking.start(dish)


## E on the beer tap: pour a tower for the oldest table that ordered one.
func pour() -> void:
	var order := next_order(true)
	if order == null:
		message_requested.emit("Chưa bàn nào gọi bia")
		return
	if not stall.stock.take(order.dish):
		if stall.bag.count(order.dish) > 0:
			message_requested.emit("Bia còn trong túi: cất vào tủ lạnh trước")
		else:
			message_requested.emit("Hết bia: sang tạp hoá %s mua bình mới" % stall.seller_name)
		return
	busy = true
	_cooking_visit = {}
	_cooking_items = []
	cooking.start(order.dish)


func _on_spilled(dish: DishData) -> void:
	var lost := stall.stock.spill(dish, spill_litres)
	if lost > 0:
		message_requested.emit("Tràn! Mất %d %s bia" % [lost, dish.unit_name])


func _on_cooking_finished(dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	if not busy:
		return
	rin.carried = DishShelf.Plate.new(dish, _cooking_items, multiplier, _cooking_visit)
	_cooking_visit = {}
	_cooking_items = []
	busy = false


## Whether E on `cell` does something right now (for the "E" key marker).
func can_act(cell: Vector2i) -> bool:
	if not is_open() or busy:
		return false
	match room.grid.kind(cell):
		"N":
			return rin.carried == null and next_order(false) != null
		"U":
			return rin.carried == null and next_order(true) != null
	return false


## E on `cell` while serving; false = nothing to do there.
func interact(cell: Vector2i) -> bool:
	if not is_open() or busy or cooking.is_running():
		return false
	match room.grid.kind(cell):
		"N", "U":
			if rin.carried:
				message_requested.emit("Tay đang cầm món")
			elif room.grid.kind(cell) == "N":
				grill()
			else:
				pour()
			return true
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
