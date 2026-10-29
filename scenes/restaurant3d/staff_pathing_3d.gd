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


## Gameplay movement: accelerate/brake and drive the skinned feet from real travel.
static func move(node: Node3D, tables: Array, target: Vector3, speed: float, delta: float) -> void:
	var goal: Vector3 = node.get_meta("path_goal",Vector3(INF,0,0))
	var path: Array[Vector3] = node.get_meta("path",[] as Array[Vector3])
	if goal.distance_to(target) > .05 or path.is_empty() or (path.size() < 2 and node.position.distance_to(target) > .05):
		path = FloorGrid3D.get_shared(tables).path(node.position,target)
		node.set_meta("path_goal",target)
	follow(node,path,speed,delta)
	node.set_meta("path",path)

static func follow(node: Node3D, path: Array[Vector3], speed: float, delta: float) -> void:
	if delta <= 0.0: return
	var remaining := 0.0
	var previous := node.position
	for i in range(1,path.size()):
		remaining += previous.distance_to(path[i])
		previous = path[i]
	var desired := minf(speed,sqrt(2.0*12.0*remaining))
	if path.size() > 2:
		var a := (path[1]-node.position).normalized()
		var b := (path[2]-path[1]).normalized()
		var near_corner := 1.0-clampf(node.position.distance_to(path[1])/.65,0.0,1.0)
		desired *= lerpf(1.0,lerpf(.45,1.0,maxf(a.dot(b),0.0)),near_corner)
	var velocity: float = node.get_meta("ground_speed",0.0)
	velocity = move_toward(velocity,desired,(10.0 if desired > velocity else 12.0)*delta)
	var before := node.global_position
	var travel := minf(velocity*delta,remaining)
	node.position = advance(node.position,path,travel)
	var displacement := node.global_position-before
	if displacement.length_squared() > 0.000001:
		var local := node.get_parent_node_3d().global_basis.inverse()*displacement
		node.rotation.y = lerp_angle(node.rotation.y,atan2(local.x,local.z),1.0-exp(-14.0*delta))
	node.set_meta("ground_speed",velocity if travel < remaining else 0.0)
	var actor := node as PersonRig3D
	if actor == null: actor = node.get_node_or_null("WalkerActor") as PersonRig3D
	if actor: actor.drive_ground_motion(displacement,delta,false)
