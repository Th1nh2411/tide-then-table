class_name WalkInGuests3D
extends RefCounted
## Guests who come on foot (CustomerTraffic3D): the street ends they appear
## from and the walk along the pavement / road edge up to the street, where
## FloorGrid3D's A* takes over. They leave the way they came.

## Share of parties that walk instead of riding (also when parking is full).
const SHARE := 0.4
## A little brisker than a guest strolling to the table.
const SPEED := 1.25
## A couple walks side by side, this far apart (across the way they walk).
const PAIR_GAP := 0.55
## Ways in, from out of sight to the street's edge (x -20..20, FloorGrid3D):
## the west pavement out of the fog (WorldEdgeLoop3D), up the east road bend
## (its west edge, behind the opposite row) and up the lane from the waterfront.
const ENTRANCES: Array[Array] = [
	[Vector3(-27.0, 0, 4.4), Vector3(-19.6, 0, 4.4)],
	[Vector3(22.3, 0, 21.0), Vector3(22.3, 0, 9.0), Vector3(19.6, 0, 7.5)],
	[Vector3(31.0, 0, 3.2), Vector3(19.6, 0, 3.2)],
]
## Pick weights of ENTRANCES (west is the main one).
const WEIGHTS: Array[float] = [0.45, 0.25, 0.3]


static func pick_entrance(roll: float) -> int:
	var acc := 0.0
	for i in WEIGHTS.size():
		acc += WEIGHTS[i]
		if roll < acc:
			return i
	return WEIGHTS.size() - 1


## Waypoints of entrance `which` for person `index` (the partner one step aside).
static func outside(which: int, index: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for p: Vector3 in ENTRANCES[which]:
		points.append(p)
	if index == 1:
		for i in points.size():
			var dir := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
			points[i] += Vector3(-dir.z, 0, dir.x) * PAIR_GAP
	return points


## Street end -> table approach (outside waypoints, then A*).
static func route_in(which: int, index: int, grid: FloorGrid3D, to: Vector3) -> Array[Vector3]:
	var route := outside(which, index)
	var inside := grid.path(route[route.size() - 1], to)
	for i in range(1, inside.size()):
		route.append(inside[i])
	return route


## `from` -> back out the same street end (A* first when in the street).
static func route_out(which: int, index: int, grid: FloorGrid3D, from: Vector3) -> Array[Vector3]:
	var points := outside(which, index)
	if not in_street(from):
		return _turn_back(points, from)
	points.reverse()
	var route := grid.path(from, points[0])
	for i in range(1, points.size()):
		route.append(points[i])
	return route


## Inside the restaurant street's walkable grid (FloorGrid3D).
static func in_street(p: Vector3) -> bool:
	return absf(p.x) <= 19.7 and p.z <= 8.0


## Still on the way in: back along the waypoints already passed.
static func _turn_back(points: Array[Vector3], from: Vector3) -> Array[Vector3]:
	var best := 0
	var best_d := INF
	for i in points.size() - 1:
		var d := from.distance_to(Geometry3D.get_closest_point_to_segment(from, points[i], points[i + 1]))
		if d < best_d:
			best_d = d
			best = i
	var route: Array[Vector3] = [from]
	for i in range(best, -1, -1):
		route.append(points[i])
	return route
