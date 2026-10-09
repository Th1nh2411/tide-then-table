class_name Customer
extends StreetPerson
## A party of 1-2 at a table on the street restaurant, drinking-snack style
## ("nhậu"): the leader walks to the table (from their parked motorbike or
## along the pavement), reads the menu for a moment, orders one or more
## dishes (TableOrder lines, chosen by the manager), then eats them as they
## come, one plate at a time; when everything is eaten and nothing is still
## coming, `finished_eating` (the manager may order one more round, or they
## pay and walk off). Patience only drains while lines are pending and
## there's nothing on the table; each plate brought cheers them up a bit.
## Runs out = leaves angry (pays for what was eaten). The second guest
## (`leader` set) only walks, sits on the spare stool and eats along.
## Special kinds: a regular coming for their fish order (more patient, gold
## bubble) and a well-off customer (gold shirt + tie, pays more).
## ServiceMarkers draws the order bubbles above the leader.

signal ordered(customer: Customer)
signal patience_ran_out(customer: Customer)
signal finished_eating(customer: Customer)

enum State { WALKING_IN, READING, DINING, LEAVING }

## Seconds from full patience to leaving (only while waiting with nothing to eat).
@export var patience_seconds: float = 45.0
## Reading the menu before ordering (random in range).
@export var read_seconds: Vector2 = Vector2(1.5, 3.0)
## Seconds per plate (random in range).
@export var eat_seconds: Vector2 = Vector2(4.0, 6.0)
## Patience back for every plate brought.
@export var serve_patience_boost: float = 0.3

## Set for a regular eating their order (the FishOrders visit); {} otherwise.
var visit: Dictionary = {}
var regular_name: String = ""
## Well-off customer (decor upgrade): pays more, less patient.
var rich: bool = false
## Table index.
var seat: int = -1
## 1.0 = full patience, 0.0 = leaving.
var patience: float = 1.0
## Lines still coming (also in CustomerManager.waiting).
var orders: Array[TableOrder] = []
## The plate being eaten now; plates brought but not started; plates done.
var plate: DishShelf.Plate
var queued: Array[DishShelf.Plate] = []
var eaten: Array[DishShelf.Plate] = []
## Extra rounds this party may still order.
var more_rounds: int = 0
var state: State = State.WALKING_IN
## Their motorbike (null = came on foot).
var bike: CustomerBikes.Bike
## The second guest (on the leader), or the leader (on the second guest).
var companion: Customer
var leader: Customer

var _timer: float = 0.0


func _ready() -> void:
	body_color = Color.from_hsv(randf(), 0.5, 0.85)
	if rich:
		body_color = Color(0.95, 0.8, 0.3)
		tie = true
	elif regular_name:
		body_color = Color(0.3, 0.5, 0.45)
		label = regular_name


## Walks to the stool; the leader starts reading on arrival.
func go_to_seat(points: Array[Vector2]) -> void:
	await walk_and_wait(points)
	if state == State.WALKING_IN:
		facing = Vector2i.DOWN  # the stool is behind the table
		if leader:
			state = State.DINING
		else:
			state = State.READING
			_timer = randf_range(read_seconds.x, read_seconds.y)


func add_order(order: TableOrder) -> void:
	orders.append(order)


## A plate arrives at the table (its line is done).
func serve(order: TableOrder, p_plate: DishShelf.Plate) -> void:
	orders.erase(order)
	patience = minf(patience + serve_patience_boost, 1.0)
	queued.append(p_plate)
	if plate == null:
		_next_plate()


## Eating (or about to): plates on the table.
func is_eating() -> bool:
	return plate != null


func is_seated() -> bool:
	return state == State.READING or state == State.DINING


## Walks off along `points` (await it).
func leave(points: Array[Vector2]) -> void:
	state = State.LEAVING
	await walk_and_wait(points)


func _next_plate() -> void:
	plate = queued.pop_front() if not queued.is_empty() else null
	if plate:
		_timer = randf_range(eat_seconds.x, eat_seconds.y)


func _process(delta: float) -> void:
	super(delta)
	if leader:
		return
	match state:
		State.READING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.DINING
				ordered.emit(self)
		State.DINING:
			if plate:
				_timer -= delta
				if _timer <= 0.0:
					eaten.append(plate)
					_next_plate()
					if plate == null and orders.is_empty():
						finished_eating.emit(self)
			elif not orders.is_empty():
				patience = maxf(patience - delta / patience_seconds, 0.0)
				if patience <= 0.0:
					patience_ran_out.emit(self)


func _draw() -> void:
	super()
	var eater := leader if leader else self
	if state == State.DINING and eater.is_eating():  # chopsticks going up and down
		var lift := absf(sin((eater._timer + (0.4 if leader else 0.0)) * 6.0)) * 3.0
		draw_line(Vector2(5, -14 - lift), Vector2(9, -8 - lift), Color(0.6, 0.45, 0.3), 1.0)
