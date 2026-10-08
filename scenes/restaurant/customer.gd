class_name Customer
extends StreetPerson
## A customer on the street restaurant: walks to a table (from their parked
## motorbike or along the pavement), reads the menu for a moment, orders,
## waits until the dish arrives (patience), eats for a few seconds, then
## pays and walks off (CustomerManager handles money, the table and the bike).
## Runs out of patience while waiting = leaves angry. Special kinds: a
## regular coming for their fish order (more patient, gold bubble) and a
## well-off customer (gold shirt + tie, pays more). ServiceMarkers draws the
## order bubbles above everyone.

signal ordered(customer: Customer)
signal patience_ran_out(customer: Customer)
signal finished_eating(customer: Customer)

enum State { WALKING_IN, READING, WAITING, EATING, LEAVING }

## Seconds from full patience to leaving (only while WAITING).
@export var patience_seconds: float = 45.0
## Reading the menu before ordering (random in range).
@export var read_seconds: Vector2 = Vector2(1.5, 3.0)
@export var eat_seconds: Vector2 = Vector2(4.0, 6.0)

## Ordered dish (chosen by the manager when the customer orders).
var dish: DishData
## Set for a regular eating their order (the FishOrders visit); {} otherwise.
var visit: Dictionary = {}
var regular_name: String = ""
## Well-off customer (decor upgrade): pays more, less patient.
var rich: bool = false
## Table index.
var seat: int = -1
## 1.0 = full patience, 0.0 = leaving.
var patience: float = 1.0
## The dish being eaten (set when served).
var plate: DishShelf.Plate
var state: State = State.WALKING_IN
## Their motorbike (null = came on foot).
var bike: CustomerBikes.Bike

var _timer: float = 0.0


func _ready() -> void:
	body_color = Color.from_hsv(randf(), 0.5, 0.85)
	if rich:
		body_color = Color(0.95, 0.8, 0.3)
		tie = true
	elif regular_name:
		body_color = Color(0.3, 0.5, 0.45)
		label = regular_name


## Walks to the chair; reading starts on arrival.
func go_to_seat(points: Array[Vector2]) -> void:
	await walk_and_wait(points)
	if state == State.WALKING_IN:
		facing = Vector2i.UP
		state = State.READING
		_timer = randf_range(read_seconds.x, read_seconds.y)


## The dish arrives at the table.
func serve(p_plate: DishShelf.Plate) -> void:
	plate = p_plate
	state = State.EATING
	_timer = randf_range(eat_seconds.x, eat_seconds.y)


func is_waiting() -> bool:
	return state == State.WAITING


## Walks off along `points` (await it).
func leave(points: Array[Vector2]) -> void:
	state = State.LEAVING
	await walk_and_wait(points)


func _process(delta: float) -> void:
	super(delta)
	match state:
		State.READING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.WAITING
				ordered.emit(self)
		State.WAITING:
			patience = maxf(patience - delta / patience_seconds, 0.0)
			if patience <= 0.0:
				patience_ran_out.emit(self)
		State.EATING:
			_timer -= delta
			if _timer <= 0.0:
				finished_eating.emit(self)


func _draw() -> void:
	super()
	if state == State.EATING:  # chopsticks going up and down
		var lift := absf(sin(_timer * 6.0)) * 3.0
		draw_line(Vector2(5, -14 - lift), Vector2(9, -8 - lift), Color(0.6, 0.45, 0.3), 1.0)
