class_name StreetFacades3D
extends RefCounted
## House fronts around the restaurant street (street coordinates, x -20..20):
## the shop row behind the pavement (both the restaurant and the village),
## and on the village map the corners at both ends, the west pavement that
## runs on between houses into the fog (WorldEdgeLoop3D), the T-junction at
## its far end and the bend at the east end of the road. Lit windows go in
## nodes of group GLOW (VillageBuilder3D shows them from the shift on).

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")
const GLOW := "village_night_glow"
const DEPTH := 8.0
## [x0, x1, height, style] of the shop row (the sign house is style 3).
const SHOP_ROW := [[-20.0, -13.5, 7.6, 0], [-13.5, -7.0, 6.4, 1], [-7.0, -1.5, 8.8, 2],
	[-1.5, 7.5, 7.2, 3], [7.5, 13.5, 6.6, 4], [13.5, 20.0, 9.2, 5]]
## West pavement beyond the street (WorldEdgeLoop3D's west corridor).
const WEST_Z := Vector2(2.0, 8.3)
const WEST_END_X := -72.0
const JUNCTION_X := -72.0
## The road bends south at the east end, between these x.
const BEND_X := Vector2(21.5, 29.5)


## The row of tube houses behind the pavement (its wall collider stays the builder's).
static func shop_row(host: Node3D) -> void:
	var day := BoxBatch3D.new()
	var night := BoxBatch3D.new()
	var front := L.BACK_Z - 0.05
	for spec: Array in SHOP_ROW:
		var x0: float = spec[0]
		var x1: float = spec[1]
		TubeHouse3D.build(host, day, night, Vector3((x0 + x1) * 0.5, 0, front), Vector3(x1 - x0, spec[2], DEPTH), 0.0, spec[3], false, false)
	day.commit(host, "ShopRow")
	night.commit(host, "ShopRowGlow", false).add_to_group(GLOW)


## Everything else around the street on the village map.
static func build_village(host: Node3D) -> void:
	var day := BoxBatch3D.new()
	var night := BoxBatch3D.new()
	var front := L.BACK_Z - 0.05
	# East corner: a tall block behind the lane's first house.
	TubeHouse3D.build(host, day, night, Vector3(24.75, 0, -5.95), Vector3(9.5, 10.0, 9.9), 0.0, 1)
	# West end: a house facing up the street, then the row along the west pavement.
	TubeHouse3D.build(host, day, night, Vector3(-20.05, 0, (front + WEST_Z.x) * 0.5), Vector3(WEST_Z.x - front, 7.0, DEPTH), PI * 0.5, 4)
	B().solid_block(host, Vector3(-24.05, 3.5, (front + WEST_Z.x) * 0.5), Vector3(DEPTH, 7.0, WEST_Z.x - front))
	_side_windows(day, night, Vector3(-24.0, 0, WEST_Z.x + 0.02))
	_row(host, day, night, -28.05, JUNCTION_X, WEST_Z.x, 0.0, 7)
	B().solid_block(host, Vector3((WEST_END_X - 28.05) * 0.5, 3.0, WEST_Z.x - 1.5), Vector3(-28.05 - WEST_END_X, 6.0, 3.0))
	# The T-junction: houses across the far end of the north-south road.
	_row_z(host, day, night, JUNCTION_X - 8.5, -40.0, 72.0, PI * 0.5, 11)
	# East end: a house closing the road, houses down both sides of the bend.
	_row_z(host, day, night, BEND_X.y + 0.5, 12.2, 66.0, -PI * 0.5, 3)
	_row_z(host, day, night, BEND_X.x - 0.5, 26.5, 66.0, PI * 0.5, 5)
	day.commit(host, "StreetFacades")
	night.commit(host, "StreetFacadesGlow", false).add_to_group(GLOW)
	_pavements(host)


static func B() -> GDScript:
	return preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")


## Houses fronting z = `z` from x0 down to x1 (x1 < x0), facing +Z (yaw 0) or -Z (PI).
static func _row(host: Node3D, day: BoxBatch3D, night: BoxBatch3D, x0: float, x1: float, z: float, yaw: float, seed_: int) -> void:
	var x := x0
	var i := seed_
	while x > x1 + 1.0:
		var w := minf(4.2 + float((i * 5) % 4) * 0.8, x - x1)
		var h := 4.6 + float((i * 7) % 5) * 1.2
		TubeHouse3D.build(host, day, night, Vector3(x - w * 0.5, 0, z), Vector3(w, h, DEPTH), yaw, i, false)
		x -= w
		i += 1


## Houses fronting x = `x` from z0 to z1 (z1 > z0), facing +X (yaw PI/2) or -X (-PI/2).
static func _row_z(host: Node3D, day: BoxBatch3D, night: BoxBatch3D, x: float, z0: float, z1: float, yaw: float, seed_: int) -> void:
	var z := z0
	var i := seed_
	while z < z1 - 1.0:
		var w := minf(4.4 + float((i * 3) % 4) * 0.7, z1 - z)
		var h := 4.4 + float((i * 5) % 5) * 1.1
		TubeHouse3D.build(host, day, night, Vector3(x, 0, z + w * 0.5), Vector3(w, h, DEPTH), yaw, i, false)
		B().solid_block(host, Vector3(x - DEPTH * 0.5 * sin(yaw), h * 0.5, z + w * 0.5), Vector3(DEPTH, h, w))
		z += w
		i += 1


## Two windows and a side door on the west corner house's side to the pavement.
static func _side_windows(day: BoxBatch3D, night: BoxBatch3D, at: Vector3) -> void:
	var dark := BoxBatch3D.color("1d1f22")
	day.box(HorrorMaterials.tiled("door_wood_old", 1.0), at + Vector3(2.0, 1.05, 0), Vector3(1.0, 2.1, 0.05))
	for x: float in [-2.0, 1.0]:
		day.box(dark, at + Vector3(x, 4.7, 0), Vector3(0.9, 1.2, 0.05))
	night.box(BoxBatch3D.color("e8b46a", 1.2), at + Vector3(-2.0, 4.7, 0.02), Vector3(0.8, 1.1, 0.02))


## Pavement, curb and road beyond the street: west to the junction, east to the bend.
static func _pavements(host: Node3D) -> void:
	var tiles := HorrorMaterials.tiled("tiles_cement_floor", 1.0, Color(0.72, 0.72, 0.68))
	var asphalt := BoxBatch3D.color("202e37")
	var road_z := L.FRONT_Z + 0.2 + L.ROAD_DEPTH * 0.5
	var west := -L.ROOM_X
	var cross := JUNCTION_X - 8.0  # far side of the north-south road
	var b := BoxBatch3D.new()
	b.box(tiles, Vector3((west + WEST_END_X) * 0.5, -0.05, (WEST_Z.x + L.FRONT_Z) * 0.5), Vector3(west - WEST_END_X, 0.1, L.FRONT_Z - WEST_Z.x))
	b.box(BoxBatch3D.color("a8a08c"), Vector3((west + WEST_END_X) * 0.5, -0.05, L.FRONT_Z + 0.1), Vector3(west - WEST_END_X, 0.2, 0.3))
	b.box(asphalt, Vector3((west + cross) * 0.5, -0.2, road_z), Vector3(west - cross, 0.2, L.ROAD_DEPTH))
	b.box(asphalt, Vector3(JUNCTION_X - 4.0, -0.2, 16.0), Vector3(8.0, 0.2, 112.0))
	b.box(asphalt, Vector3((L.ROOM_X + BEND_X.y) * 0.5, -0.2, road_z), Vector3(BEND_X.y - L.ROOM_X, 0.2, L.ROAD_DEPTH))
	b.box(asphalt, Vector3((BEND_X.x + BEND_X.y) * 0.5, -0.2, 38.0), Vector3(BEND_X.y - BEND_X.x, 0.2, 60.0))
	var paint := BoxBatch3D.color("8e8c79")
	for x in range(-68, -20, 6):
		b.box(paint, Vector3(float(x), -0.09, road_z), Vector3(2.0, 0.02, 0.15))
	# Opposite pavement along the far side of the road.
	b.box(tiles, Vector3((JUNCTION_X + BEND_X.x) * 0.5, -0.05, road_z + L.ROAD_DEPTH * 0.5 + 0.8), Vector3(BEND_X.x - JUNCTION_X, 0.1, 1.6))
	b.commit(host, "StreetPavements", false)
	# The curb's invisible wall runs on west with the pavement (bikes stay on the road).
	B().solid_block(host, Vector3((west + WEST_END_X) * 0.5, 1.4, L.FRONT_Z), Vector3(west - WEST_END_X, 3.0, 0.15))
	B().solid_block(host, Vector3(WEST_END_X - 0.2, 1.4, (WEST_Z.x + L.FRONT_Z) * 0.5), Vector3(0.3, 3.0, L.FRONT_Z - WEST_Z.x))
