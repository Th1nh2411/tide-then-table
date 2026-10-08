class_name TdCustomers
extends Node2D
## Customers in the top-down prototype: most ride in on a motorbike
## (TdBikes: road -> parking slot by the curb), the rest walk in along the
## pavement; then to a free table, read the menu, order, wait (patience),
## eat, pay + tip, walk back to their bike (or off the pavement) and leave the
## table dirty. Draws their order bubbles above everyone (z_index).

signal paid(amount: int)

enum State { RIDE_IN, WALK_IN, THINK, WAIT, EAT, LEAVE }

class Guest:
	extends RefCounted
	var person: TdPerson
	var table: int = -1
	var dish: DishData
	var state: State = State.WALK_IN
	var timer: float = 0.0
	var patience: float = 1.0
	var bill: int = 0
	var bike: TdBikes.Bike

@export var room: TdRoom
@export var people_layer: Node2D
@export var kitchen: TdKitchen
@export var bikes: TdBikes
## Share of customers who come on foot instead of by motorbike.
@export var walk_in_chance: float = 0.2
@export var spawn_seconds: Vector2 = Vector2(5.0, 9.0)
@export var think_seconds: float = 2.0
@export var eat_seconds: float = 5.0
@export var patience_seconds: float = 45.0
@export var shirt_colors: Array[Color] = [Color(0.6, 0.3, 0.6), Color(0.3, 0.6, 0.4),
	Color(0.8, 0.6, 0.2), Color(0.4, 0.4, 0.7), Color(0.7, 0.35, 0.3)]

var guests: Array[Guest] = []
var running: bool = true

var _spawn_left: float = 1.0


func _ready() -> void:
	z_index = 10
	bikes.parked.connect(_on_bike_parked)


## Waiting orders in arrival order.
func waiting() -> Array[Guest]:
	var result: Array[Guest] = []
	for guest in guests:
		if guest.state == State.WAIT:
			result.append(guest)
	return result


func guest_at(table: int) -> Guest:
	for guest in guests:
		if guest.table == table and guest.state != State.LEAVE:
			return guest
	return null


## A plate brought to `table`: served if that guest is waiting for this dish.
func serve(table: int, plate: TdPlate) -> bool:
	var guest := guest_at(table)
	if guest == null or guest.state != State.WAIT or guest.dish != plate.dish:
		return false
	guest.state = State.EAT
	guest.timer = eat_seconds
	var price := roundi(plate.dish.base_price * plate.multiplier)
	guest.bill = price + roundi(price * 0.25 * guest.patience)
	return true


func _process(delta: float) -> void:
	queue_redraw()
	if running:
		_spawn_left -= delta
		if _spawn_left <= 0.0:
			_spawn_left = randf_range(spawn_seconds.x, spawn_seconds.y)
			_spawn()
	for guest in guests.duplicate():
		_update(guest, delta)


func _spawn() -> void:
	var free: Array[int] = []
	for i in room.tables.size():
		if guest_at(i) == null and not room.dirty.has(room.tables[i]["table"]):
			free.append(i)
	if free.is_empty():
		return
	var guest := Guest.new()
	guest.table = free.pick_random()
	guests.append(guest)
	if randf() >= walk_in_chance:
		guest.bike = bikes.arrive()
	if guest.bike:
		guest.state = State.RIDE_IN
	else:
		_walk_in(guest, room.grid.cells_of("D").pick_random())


func _walk_in(guest: Guest, from: Vector2i) -> void:
	guest.person = TdPerson.new()
	guest.person.body_color = shirt_colors.pick_random()
	guest.person.position = room.grid.to_world(from)
	people_layer.add_child(guest.person)
	guest.person.walk(room.grid.path(from, room.tables[guest.table]["chair"]))
	guest.state = State.WALK_IN


func _on_bike_parked(bike: TdBikes.Bike) -> void:
	for guest in guests:
		if guest.bike == bike:
			_walk_in(guest, bike.parking)


func _update(guest: Guest, delta: float) -> void:
	match guest.state:
		State.WALK_IN:
			if not guest.person.is_walking():
				guest.person.facing = Vector2i.UP
				guest.state = State.THINK
				guest.timer = think_seconds
		State.THINK:
			guest.timer -= delta
			if guest.timer <= 0.0:
				guest.dish = kitchen.pick_order()
				guest.state = State.WAIT
		State.WAIT:
			guest.patience -= delta / patience_seconds
			if guest.patience <= 0.0:
				_leave(guest, false)
		State.EAT:
			guest.timer -= delta
			if guest.timer <= 0.0:
				paid.emit(guest.bill)
				_leave(guest, true)
		State.LEAVE:
			if not guest.person.is_walking():
				guest.person.queue_free()
				guests.erase(guest)
				if guest.bike:
					bikes.depart(guest.bike)


func _leave(guest: Guest, ate: bool) -> void:
	if ate:
		room.dirty[room.tables[guest.table]["table"]] = true
	guest.state = State.LEAVE
	var exit: Vector2i = guest.bike.parking if guest.bike else room.grid.cells_of("D").pick_random()
	guest.person.walk(room.grid.path(room.grid.to_cell(guest.person.position), exit))


func _draw() -> void:
	for guest in guests:
		if guest.person == null:
			continue  # still riding in
		var head := guest.person.position + Vector2(0, -40)
		match guest.state:
			State.THINK:
				_bubble(head)
				draw_string(ThemeDB.fallback_font, head + Vector2(-5, 3), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
					Color(0.2, 0.2, 0.2))
			State.WAIT:
				_bubble(head)
				TdPlate.new(guest.dish).draw_at(self, head)
				draw_rect(Rect2(head + Vector2(-8, 7), Vector2(16 * guest.patience, 2)),
					Color(1, 0.3, 0.3).lerp(Color(0.3, 0.8, 0.4), guest.patience))
			State.EAT:
				draw_circle(guest.person.position + Vector2(0, -36), 2.0, Color(1, 1, 1, 0.6))


func _bubble(at: Vector2) -> void:
	draw_rect(Rect2(at - Vector2(10, 8), Vector2(20, 18)), Color(1, 1, 1, 0.95))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-3, 10), at + Vector2(3, 10), at + Vector2(0, 14)]),
		Color(1, 1, 1, 0.95))
