class_name TdKitchen
extends Node
## Kitchen rules for the top-down prototype:
## - near the food cart (room.kitchen_area), 1-9 (or click a board row) picks
##   a dish: Rin walks behind the cart's stove, facing the road, then the
##   CookingOverlay minigame starts (she stands still); the dish ends up in
##   her hands
## - E on the plate table (P, one plate per cell): put down / pick up
## - E on the bin: throw the plate away
## - E on a table: serve the plate, or clean it when dirty
## Prototype stock: `portions` of the first `menu_size` dishes + snacks.

signal message_requested(text: String)

@export var room: TdRoom
@export var chef: TdChef
@export var customers: TdCustomers
@export var cooking: CookingOverlay
@export var menu: DishCatalog
@export var menu_size: int = 4
@export var portions: int = 6
@export var clean_seconds: float = 0.5

## Menu board rows (numbers never shift) and portions left (-1 = endless).
var board: Array[DishData] = []
var counts: Dictionary = {}


func _ready() -> void:
	for dish in menu.dishes:
		if not dish.always_available and board.size() < menu_size:
			board.append(dish)
			counts[dish] = portions
	for dish in menu.dishes:
		if dish.always_available:
			board.append(dish)
			counts[dish] = -1
	chef.interacted.connect(_on_interacted)
	cooking.finished.connect(_on_cooking_finished)


## Rin is near the cart (the menu board lights up, dish keys work).
func can_cook() -> bool:
	return chef.active and room.kitchen_area.has_point(room.grid.to_cell(chef.position))


## Where Rin stands to use the stove: behind the cart, facing the road.
func stove_spot() -> Vector2i:
	return room.grid.cells_of("S")[0] + Vector2i.UP


## A dish a new customer can order (portions left, else a snack).
func pick_order() -> DishData:
	var options: Array[DishData] = []
	for dish in board:
		if int(counts[dish]) != 0:
			options.append(dish)
	return options.pick_random()


func cook(index: int) -> void:
	if index < 0 or index >= board.size() or cooking.is_running() or not can_cook():
		return
	if chef.carried:
		message_requested.emit("Tay đang cầm món")
		return
	var dish := board[index]
	if int(counts[dish]) == 0:
		message_requested.emit("Hết %s" % dish.display_name)
		return
	if int(counts[dish]) > 0:
		counts[dish] = int(counts[dish]) - 1
	if dish.instant_serve:
		chef.carried = TdPlate.new(dish)
		return
	chef.active = false
	chef.walk(room.grid.path(room.grid.to_cell(chef.position), stove_spot()))
	if chef.has_path():
		await chef.arrived
	chef.facing = Vector2i.DOWN
	cooking.start(dish)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and chef.active:
		var index := key.physical_keycode - KEY_1
		if index >= 0 and index < mini(board.size(), 9):
			get_viewport().set_input_as_handled()
			cook(index)


func _on_cooking_finished(dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	chef.carried = TdPlate.new(dish, multiplier)
	chef.active = true


func _on_interacted(cell: Vector2i) -> void:
	var kind := room.grid.kind(cell)
	if room.is_counter(cell):
		if chef.carried and not room.counter_plates.has(cell):
			room.counter_plates[cell] = chef.carried
			chef.carried = null
		elif not chef.carried and room.counter_plates.has(cell):
			chef.carried = room.counter_plates[cell]
			room.counter_plates.erase(cell)
	elif kind == "B":
		chef.carried = null
	elif kind in ["T", "h"]:
		var table := room.table_index(cell)
		if chef.carried:
			if customers.serve(table, chef.carried):
				chef.carried = null
		elif room.dirty.has(room.tables[table]["table"]):
			chef.active = false
			await get_tree().create_timer(clean_seconds).timeout
			room.dirty.erase(room.tables[table]["table"])
			chef.active = true
