class_name TdBikes
extends Node2D
## Customers' motorbikes in the top-down prototype: a bike rides in along
## the road, hops the curb into a free parking slot on the pavement edge
## (`parked`), waits there while its rider eats, then backs out and rides
## off screen (`gone`). Drawn under the people (sits before them in the tree).

signal parked(bike: Bike)

class Bike:
	extends RefCounted
	var color: Color
	var helmet: Color
	var pos: Vector2
	var parking: Vector2i
	var rider: bool = true
	var leaving: bool = false
	var facing: float = 1.0
	var waypoints: Array[Vector2] = []

@export var room: TdRoom
@export var speed: float = 90.0
## Parking row (pavement cells next to the curb) and slot spacing.
@export var parking_row: int = 10
@export var parking_x: Vector2i = Vector2i(9, 36)
## Road lanes (rows): rightward traffic keeps to the far lane (drive on the right).
@export var lane_rows: Vector2i = Vector2i(17, 14)
@export var slot_step: int = 3
@export var colors: Array[Color] = [Color(0.9, 0.3, 0.25), Color(0.25, 0.4, 0.9), Color(0.95, 0.95, 0.95),
	Color(0.2, 0.2, 0.22), Color(0.95, 0.75, 0.2)]
@export var helmets: Array[Color] = [Color(0.95, 0.8, 0.3), Color(0.85, 0.2, 0.2), Color(0.3, 0.6, 0.9),
	Color(0.95, 0.95, 0.95)]

var bikes: Array[Bike] = []


func free_slots() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(parking_x.x, parking_x.y + 1, slot_step):
		var cell := Vector2i(x, parking_row)
		if room.grid.kind(cell) == "." and not bikes.any(func(b: Bike) -> bool: return b.parking == cell):
			result.append(cell)
	return result


## A new bike rides in to a free slot; null when the parking is full.
func arrive() -> Bike:
	var slots := free_slots()
	if slots.is_empty():
		return null
	var bike := Bike.new()
	bike.parking = slots.pick_random()
	bike.color = colors.pick_random()
	bike.helmet = helmets.pick_random()
	var from_left := randf() < 0.5
	bike.facing = 1.0 if from_left else -1.0
	var lane := _lane_y(from_left)
	var slot := room.grid.to_world(bike.parking)
	bike.pos = Vector2(-30.0 if from_left else _width() + 30.0, lane)
	bike.waypoints = [Vector2(slot.x, lane), slot]
	bikes.append(bike)
	return bike


## The rider got back on: back out to the road and ride off.
func depart(bike: Bike) -> void:
	var to_right := randf() < 0.5
	var lane := _lane_y(to_right)
	bike.rider = true
	bike.leaving = true
	bike.facing = 1.0 if to_right else -1.0
	bike.waypoints = [Vector2(bike.pos.x, lane), Vector2(_width() + 30.0 if to_right else -30.0, lane)]


func _lane_y(rightward: bool) -> float:
	return room.grid.cell_rect(Vector2i(0, lane_rows.x if rightward else lane_rows.y)).get_center().y


func _width() -> float:
	return room.grid.size.x * room.cell_size


func _process(delta: float) -> void:
	queue_redraw()
	for bike in bikes.duplicate():
		if bike.waypoints.is_empty():
			continue
		var step: Vector2 = bike.waypoints[0] - bike.pos
		if step.length() <= speed * delta:
			bike.pos = bike.waypoints[0]
			bike.waypoints.remove_at(0)
			if bike.waypoints.is_empty():
				if bike.leaving:
					bikes.erase(bike)
				else:
					bike.rider = false
					parked.emit(bike)
		else:
			bike.pos += step.normalized() * speed * delta


func _draw() -> void:
	for bike in bikes:
		if bike.waypoints.is_empty():
			_draw_parked(bike)
		else:
			_draw_riding(bike)


## Parked nose towards the road (ready to ride off), seen from above.
func _draw_parked(bike: Bike) -> void:
	var p := bike.pos
	draw_rect(Rect2(p + Vector2(-3, -9), Vector2(6, 15)), bike.color)
	draw_rect(Rect2(p + Vector2(-2, -6), Vector2(4, 6)), Color(0.15, 0.12, 0.1))  # seat
	draw_rect(Rect2(p + Vector2(-6, 4), Vector2(12, 2)), Color(0.3, 0.3, 0.32))  # handlebar
	draw_circle(p + Vector2(0, 7), 1.5, Color(1, 1, 0.7))  # headlight
	draw_rect(Rect2(p + Vector2(-2, 6), Vector2(4, 3)), Color(0.1, 0.1, 0.1))  # front tyre
	draw_rect(Rect2(p + Vector2(-2, -12), Vector2(4, 3)), Color(0.1, 0.1, 0.1))  # back tyre


## Side view while riding, with the rider.
func _draw_riding(bike: Bike) -> void:
	var p := bike.pos
	var f := bike.facing
	draw_rect(Rect2(p + Vector2(-9, -3), Vector2(18, 6)), bike.color)
	draw_circle(p + Vector2(-7, 3), 2.5, Color(0.1, 0.1, 0.1))
	draw_circle(p + Vector2(7, 3), 2.5, Color(0.1, 0.1, 0.1))
	draw_circle(p + Vector2(9 * f, -1), 1.8, Color(1, 1, 0.7))  # headlight
	if bike.rider:
		draw_rect(Rect2(p + Vector2(-3, -10), Vector2(6, 7)), Color(0.4, 0.4, 0.5))
		draw_circle(p + Vector2(0, -12), 3.5, bike.helmet)
