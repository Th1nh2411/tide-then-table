class_name StaffPathing3D
extends RefCounted
## Walks a node along an A* path (cached in node meta) instead of a straight line.


## Advance `node` toward `target` by `distance` metres, around furniture.
static func step(node: Node3D, tables: Array, target: Vector3, distance: float) -> void:
	var grid := FloorGrid3D.get_shared(tables)
	var goal: Vector3 = node.get_meta("path_goal", Vector3(INF, 0, 0))
	var path: Array[Vector3] = node.get_meta("path", [] as Array[Vector3])
	if goal.distance_to(target) > 0.05 or path.size() < 2:
		path = grid.path(node.position, target)
		node.set_meta("path_goal", target)
	node.position = advance(node.position, path, distance)
	node.set_meta("path", path)


## Consume `distance` along `path` (drops passed points in place); returns the new position.
static func advance(pos: Vector3, path: Array[Vector3], distance: float) -> Vector3:
	var remaining := distance
	while path.size() > 1 and remaining > 0.0:
		var next: Vector3 = path[1]
		var gap := pos.distance_to(next)
		if gap <= remaining:
			remaining -= gap
			pos = next
			path.remove_at(0)
		else:
			pos = pos.move_toward(next, remaining)
			remaining = 0.0
	if path.size() > 0:
		path[0] = pos
	return pos
