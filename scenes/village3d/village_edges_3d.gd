class_name VillageEdges3D
extends RefCounted
## The edges of the walkable village (world coordinates), each one stopped by
## something real: bamboo fences and banana clumps behind the waterfront,
## houses along the shore path east (WorldEdgeLoop3D's east corridor), boats
## and stones on its sea side; the water's edge and the pier keep plain
## colliders (the sea is the reason). The headland north of the lane gets its
## vegetable patch, tin shed and upturned boat.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const L = preload("res://scenes/village3d/village_layout_3d.gd")
const WALL_H := 3.0
## East shore path (WorldEdgeLoop3D): z range and where its houses stop.
const EAST_Z := Vector2(1.0, 7.3)
const EAST_END_X := 130.0


static func build(host: Node3D) -> void:
	var gx := L.GROUND_X
	var gz := L.GROUND_Z
	var b := BoxBatch3D.new()
	var day := BoxBatch3D.new()
	var night := BoxBatch3D.new()
	# West of the waterfront, either side of the lane's mouth: fences.
	_fence_z(host, gx.x, gz.x, VillageLaneBuilder3D.NORTH_Z)
	_fence_z(host, gx.x, VillageLaneBuilder3D.SOUTH_Z, gz.y)
	# South: fences in the gaps between the houses, banana clumps, then the back houses.
	for span: Vector2 in [Vector2(47.0, 53.2), Vector2(57.8, 59.0), Vector2(64.0, 69.2), Vector2(73.8, 81.0)]:
		_fence_x(host, gz.y, span.x, span.y)
	for at: Vector3 in [Vector3(49.5, 0, 10.6), Vector3(66.5, 0, 10.8), Vector3(78.5, 0, 10.6)]:
		ConceptModel3D.spawn(host, "banana_clump", at, 2.6)
	_wall_x(host, gz.y, gx.x, gx.y)
	# Shore: down the beach to just above the waterline (open only where the
	# pier starts); the pier's sides and end.
	var stop := L.BEACH_STOP_Z
	_wall_x(host, gz.x, gx.x, L.BEACH_WEST_X)
	_wall_z(host, L.BEACH_WEST_X, stop, gz.x)
	_wall_x(host, stop, L.BEACH_WEST_X, L.PIER_X.x)
	_wall_x(host, stop, L.PIER_X.y, gx.y)
	_wall_x(host, gz.x, gx.y, EAST_END_X)
	_wall_z(host, L.PIER_X.x, L.PIER_END_Z, gz.x)
	_wall_z(host, L.PIER_X.y, L.PIER_END_Z, gz.x)
	_wall_x(host, L.PIER_END_Z, L.PIER_X.x, L.PIER_X.y)
	# East: the shore path between the houses and the boats on the sand.
	_wall_x(host, EAST_Z.x, gx.y, EAST_END_X)
	_wall_x(host, EAST_Z.y, gx.y, EAST_END_X)
	_wall_z(host, EAST_END_X - 20.0, EAST_Z.x, EAST_Z.y)
	_fence_z(host, gx.y, EAST_Z.y, gz.y)
	_wall_z(host, gx.y, stop, EAST_Z.x)
	var x := gx.y + 0.5
	var i := 4
	while x < EAST_END_X:
		var w := minf(4.4 + float((i * 3) % 4) * 0.8, EAST_END_X - x)
		TubeHouse3D.build(host, day, night, Vector3(x + w * 0.5, 0, EAST_Z.y + 0.3), Vector3(w, 3.6 + float(i % 3) * 1.4, 7.0), PI, i)
		x += w + 0.2
		i += 1
	var boats := [Vector3(84.0, 0, -0.4), Vector3(92.5, 0, -0.8), Vector3(103.0, 0, -0.2), Vector3(116.0, 0, -0.6)]
	for j in boats.size():
		VillageProps3D.place(host, "boat_upturned" if j % 2 else "boat_pulled_up", boats[j], Vector3(1.6, 0.9, 4.4), PI * 0.5 + 0.2 * float(j % 3), b)
	VillageProps3D.place(host, "net_heap", Vector3(88.0, 0, 0.3), Vector3(1.5, 0.5, 1.2), 0.0, b)
	VillageProps3D.place(host, "buoy_pile", Vector3(98.0, 0, 0.4), Vector3(1.3, 0.6, 1.0), 0.0, b)
	VillageProps3D.place(host, "seaweed_stones", Vector3(100.0, -0.1, -2.0), Vector3(40.0, 0.4, 1.0), 0.0, b)
	VillageProps3D.place(host, "boat_upturned", Vector3(82.6, 0, -1.2), Vector3(1.5, 0.8, 4.0), 0.1, b)
	_headland(host, b)
	day.commit(host, "EdgeHouses")
	night.commit(host, "EdgeHousesGlow", false).add_to_group(StreetFacades3D.GLOW)
	b.commit(host, "EdgeProps")


## North of the lane: vegetables, a tin shed, an upturned boat, bananas.
static func _headland(host: Node3D, b: BoxBatch3D) -> void:
	VillageProps3D.place(host, "vegetable_patch", Vector3(40.0, -0.02, -3.0), Vector3(6.0, 0.4, 3.6), 0.0, b)
	VillageProps3D.place(host, "shed_tin", Vector3(32.5, -0.02, -4.6), Vector3(3.6, 2.4, 2.6), 0.0, b)
	VillageProps3D.place(host, "boat_upturned", Vector3(43.8, -0.02, -6.6), Vector3(1.6, 0.9, 4.6), 1.4, b)
	VillageProps3D.place(host, "bamboo_clump", Vector3(24.0, -0.02, -8.0), Vector3(4.0, 8.0, 4.0), 0.0, b)
	ConceptModel3D.spawn(host, "banana_clump", Vector3(36.5, -0.02, -7.2), 2.8)
	VillageProps3D.place(host, "coconut_palm", Vector3(45.6, -0.15, -7.8), Vector3(4.0, 10.0, 4.0), 2.6, b)


## Bamboo fence along z from z0 to z1 at x (model repeated, one collider).
static func _fence_z(host: Node3D, x: float, z0: float, z1: float) -> void:
	var n := maxi(ceili((z1 - z0) / 3.0), 1)
	var w := (z1 - z0) / float(n)
	for k in n:
		ConceptModel3D.sized(host, "bamboo_fence", Vector3(x, 0, z0 + (float(k) + 0.5) * w), Vector3(0.15, 1.3, w))
	_wall_z(host, x, z0, z1)


## Bamboo fence along x from x0 to x1 at z.
static func _fence_x(host: Node3D, z: float, x0: float, x1: float) -> void:
	var n := maxi(ceili((x1 - x0) / 3.0), 1)
	var w := (x1 - x0) / float(n)
	for k in n:
		ConceptModel3D.sized(host, "bamboo_fence", Vector3(x0 + (float(k) + 0.5) * w, 0, z), Vector3(0.15, 1.3, w), PI * 0.5)


## Collider along z at `x`, from z0 to z1.
static func _wall_z(host: Node3D, x: float, z0: float, z1: float) -> void:
	B.solid_block(host, Vector3(x, WALL_H * 0.5, (z0 + z1) * 0.5), Vector3(0.15, WALL_H, absf(z1 - z0)))


## Collider along x at `z`, from x0 to x1.
static func _wall_x(host: Node3D, z: float, x0: float, x1: float) -> void:
	B.solid_block(host, Vector3((x0 + x1) * 0.5, WALL_H * 0.5, z), Vector3(absf(x1 - x0), WALL_H, 0.15))
