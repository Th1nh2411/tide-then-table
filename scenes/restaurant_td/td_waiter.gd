class_name TdWaiter
extends TdPerson
## Bảo in the top-down prototype: walks the grid (A*). Takes the plate the
## oldest waiting order needs from the pass (P), carries it to that table;
## otherwise cleans dirty tables; otherwise waits by the pass.

@export var clean_seconds: float = 1.0

var room: TdRoom
var customers: TdCustomers

var _busy: bool = false


func _process(delta: float) -> void:
	super(delta)
	if not _busy:
		_busy = true
		await _next_job()
		_busy = false


func _next_job() -> void:
	for guest in customers.waiting():
		var pass_cell := _pass_with(guest.dish)
		if pass_cell.x >= 0:
			await _deliver(pass_cell, guest.table)
			return
	for table_cell: Vector2i in room.dirty.keys():
		await _go_next_to(table_cell)
		await get_tree().create_timer(clean_seconds).timeout
		room.dirty.erase(table_cell)
		return
	await get_tree().create_timer(0.3).timeout


func _pass_with(dish: DishData) -> Vector2i:
	for cell in room.grid.cells_of("P"):
		var plate: TdPlate = room.counter_plates.get(cell)
		if plate and plate.dish == dish:
			return cell
	return Vector2i(-1, -1)


func _deliver(pass_cell: Vector2i, table: int) -> void:
	await _go_next_to(pass_cell)
	if not room.counter_plates.has(pass_cell):
		return  # Rin took it meanwhile
	carried = room.counter_plates[pass_cell]
	room.counter_plates.erase(pass_cell)
	await _go_next_to(room.tables[table]["table"])
	if not customers.serve(table, carried):
		# Order gone (guest left): put it back on a free pass cell.
		for cell in room.grid.cells_of("P"):
			if not room.counter_plates.has(cell):
				await _go_next_to(cell)
				room.counter_plates[cell] = carried
				break
	carried = null


## Walks to the free cell beside `target` (pavement side: below / left of
## it, not into the kitchen) and faces it.
func _go_next_to(target: Vector2i) -> void:
	var here := room.grid.to_cell(position)
	var stand := room.grid.stand_cell(target, target + Vector2i(1, 2))
	walk(room.grid.path(here, stand))
	if is_walking():
		await arrived
	facing = target - stand
