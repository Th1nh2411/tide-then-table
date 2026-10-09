class_name StaffCrew
extends Node
## The hired staff at work (StaffRoster on GameState.staff, StaffWorker
## nodes): while the shop serves, each free worker takes the oldest plate on
## the plate table that a waiting table ordered and carries it out, or else
## cleans a dirty table, or walks back to their spot by the plate table.
## Rin and the staff never pick the same plate / table (claims). Wages are
## paid at closing (`pay_wages`); tips get the staff's bonus. The panel
## (StaffPanel) hires / dismisses and posts job ads.

signal message_requested(text: String)

@export var catalog: StaffCatalog
@export var room: StreetRoom
@export var customers: CustomerManager
@export var people_layer: Node2D
## Where idle staff wait (one each).
@export var home_cells: Array[Vector2i] = [Vector2i(14, 8), Vector2i(14, 9)]

var roster: StaffRoster
## Set by the restaurant every frame (the kitchen is open).
var serving: bool = false

var _workers: Array[StaffWorker] = []
var _claimed_plates: Array[DishShelf.Plate] = []
var _claimed_tables: Array[int] = []


func _ready() -> void:
	roster = StaffRoster.new(catalog, GameState.staff)
	roster.changed.connect(_sync_workers)
	if is_unlocked():
		for person in roster.arrivals(GameState.day):
			message_requested.emit("%s tới xin việc! (nút \"Nhân viên\")" % person.display_name)
	_sync_workers()


func is_unlocked() -> bool:
	return GameState.day >= catalog.unlock_day


func start_shift() -> void:
	customers.tip_bonus = roster.tip_bonus()


## Closing: pays everyone hired; returns the total.
func pay_wages() -> int:
	var wages := mini(roster.wages(), GameState.money)
	GameState.add_money(-wages)
	return wages


func _process(_delta: float) -> void:
	for worker in _workers:
		if worker.working:
			continue
		if serving and _take_task(worker):
			continue
		var home := _home(worker)
		if room.grid.to_cell(worker.position) != home and not worker.is_walking():
			worker.walk(room.grid.path(room.grid.to_cell(worker.position), home))


func _take_task(worker: StaffWorker) -> bool:
	var plate := _free_plate()
	if plate:
		_deliver(worker, plate)
		return true
	for seat in room.dining.dirty_seats():
		if seat not in _claimed_tables:
			_clean(worker, seat)
			return true
	return false


## Oldest plate on the plate table that a waiting table ordered, not claimed.
func _free_plate() -> DishShelf.Plate:
	for order in customers.waiting:
		for plate in customers.shelf.plates:
			if plate.dish == order.dish and plate.visit == order.visit and plate not in _claimed_plates:
				return plate
	return null


func _deliver(worker: StaffWorker, plate: DishShelf.Plate) -> void:
	worker.working = true
	_claimed_plates.append(plate)
	var slot := customers.shelf.slots.find(plate)
	await worker.go(room, room.grid.stand_cell(room.pass_cells()[slot], room.grid.to_cell(worker.position)))
	_claimed_plates.erase(plate)
	if not customers.shelf.plates.has(plate):  # Rin took it meanwhile
		worker.working = false
		return
	customers.shelf.remove(plate)
	worker.carried = plate
	customers.in_hands.append(plate)
	for attempt in 3:
		var seat := _seat_for(plate)
		if seat < 0:
			break
		await worker.go(room, room.table_stand_cell(seat, room.grid.to_cell(worker.position)))
		if customers.serve_at(seat, plate):
			worker.carried = null
			break
	if worker.carried:  # nobody wants it any more: back on the plate table
		customers.shelf.add(plate)
		worker.carried = null
	customers.in_hands.erase(plate)
	worker.working = false


func _clean(worker: StaffWorker, seat: int) -> void:
	worker.working = true
	_claimed_tables.append(seat)
	await worker.go(room, room.table_stand_cell(seat, room.grid.to_cell(worker.position)))
	await get_tree().create_timer(worker.data.clean_seconds).timeout
	room.dining.clean(seat)
	_claimed_tables.erase(seat)
	worker.working = false


func _seat_for(plate: DishShelf.Plate) -> int:
	for order in customers.waiting:
		if order.dish == plate.dish and order.visit == plate.visit:
			return order.seat
	return -1


func _home(worker: StaffWorker) -> Vector2i:
	return home_cells[clampi(_workers.find(worker), 0, home_cells.size() - 1)]


## Workers on the pavement = people hired (new ones walk in from the edge).
func _sync_workers() -> void:
	var hired := roster.hired()
	for worker in _workers.duplicate():
		if worker.data not in hired and not worker.working:
			_workers.erase(worker)
			worker.queue_free()
	for person in hired:
		if not _workers.any(func(w: StaffWorker) -> bool: return w.data == person):
			var worker := StaffWorker.new()
			worker.data = person
			_workers.append(worker)
			worker.position = room.grid.to_world(_home(worker))
			people_layer.add_child(worker)
