class_name Waiter
extends StreetPerson
## Bảo, the waiter, walking the street restaurant grid (A*). Waits beside the
## plate table; CustomerManager hands out jobs: carry a plate (walk to its
## pass slot, pick it up, take it to the table) or clean a dirty table.
## Rin can talk to Bảo while idle (child Talker; "!" when there's news).

signal picked_up(customer: Customer, plate: DishShelf.Plate)
signal delivered(customer: Customer, plate: DishShelf.Plate)
signal cleaned(seat: int)

const HIRED_FLAG: String = "bao_joined"

@export var display_name: String = "Bảo"
@export var clean_seconds: float = 1.2
## Where Bảo waits (pavement side of the plate table).
@export var home_cell: Vector2i = Vector2i(8, 8)

@export var room: StreetRoom

var _busy: bool = false


func _ready() -> void:
	body_color = Color(0.85, 0.5, 0.2)
	apron = true
	label = display_name
	speed = 80.0


## Bảo works here from day 2 (joins in the cutscene after day 1's shift).
static func is_hired() -> bool:
	return GameState.has_flag(HIRED_FLAG) or GameState.day > 1


func is_idle() -> bool:
	return not _busy


func can_talk() -> bool:
	return is_hired() and is_idle()


func go_home() -> void:
	position = room.grid.to_world(home_cell)


func deliver(customer: Customer, plate: DishShelf.Plate) -> void:
	_busy = true
	var slot := room.shelf.slots.find(plate)
	if slot >= 0:
		await _go_next_to(room.pass_cells()[slot], Vector2i(2, 0))
	if slot < 0 or room.shelf.plate_at(slot) != plate:
		_finish()  # Rin took it meanwhile
		return
	carried = plate
	picked_up.emit(customer, plate)
	if is_instance_valid(customer) and customer.seat >= 0:
		await _go_next_to(room.tables[customer.seat]["table"], Vector2i(-1, -1))
	carried = null
	delivered.emit(customer, plate)
	_finish()


func clean(seat: int) -> void:
	_busy = true
	await _go_next_to(room.tables[seat]["table"], Vector2i(-1, -1))
	await get_tree().create_timer(clean_seconds).timeout
	cleaned.emit(seat)
	_finish()


func _finish() -> void:
	_busy = false
	walk(room.grid.path(room.grid.to_cell(position), home_cell))


## Walks beside `target` (the free cell nearest target + `side`), faces it.
func _go_next_to(target: Vector2i, side: Vector2i) -> void:
	var stand := room.grid.stand_cell(target, target + side)
	await walk_and_wait(room.grid.path(room.grid.to_cell(position), stand))
	facing = target - stand


func _draw() -> void:
	super()
	var talker := get_node_or_null("Talker") as Talker
	if talker and is_idle() and talker.has_news():
		draw_string(ThemeDB.fallback_font, Vector2(-3, -44), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(1, 0.85, 0.3))
