class_name VillageLaneBuilder3D
extends RefCounted
## Lane between restaurant and waterfront. Inferred village props replace the
## temporary boxes; ground, wall boundaries, wires and gameplay colliders stay separate.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const L = preload("res://scenes/village3d/village_layout_3d.gd")
const NORTH_Z := 0.8
const SOUTH_Z := 6.2


static func build(host: Node3D) -> void:
	var lane := Node3D.new()
	lane.name = "Lane"
	host.add_child(lane)
	var length := L.LANE_END_X - L.EXIT_X
	var mid_x := (L.LANE_END_X + L.EXIT_X) * 0.5
	B.box(lane, Vector3(mid_x, -0.1, L.LANE_Z), Vector3(length, 0.2, SOUTH_Z - NORTH_Z + 0.4), "5a4a38").material_override = HorrorMaterials.tiled("lane_dirt", 2.0)
	var ground := HorrorMaterials.tiled("ground_village", 2.0)
	B.box(lane, Vector3(mid_x, -0.12, -3.6), Vector3(length, 0.2, 8.8), "4a4136").material_override = ground
	B.box(lane, Vector3(40.5, -0.12, 11.25), Vector3(13.0, 0.2, 10.1), "4a4136").material_override = ground
	var brick := HorrorMaterials.tiled("brick_wall_old", 1.6)
	# North side: a lime-washed house, a brick wall, then the fence with the sea beyond.
	_house(lane, Vector3(24.6, 0, -2.6), Vector3(9.0, 3.0, 6.6), 1.0)
	B.box(lane, Vector3(32.0, 1.1, NORTH_Z), Vector3(5.8, 2.2, 0.25), "6b4a3a", true).material_override = brick
	_fence(lane, 35.0, L.LANE_END_X, NORTH_Z)
	_shrine(lane, Vector3(40.5, 0, NORTH_Z + 0.4))
	# South side: brick wall hiding the road, a house, the banana clump, the fence.
	B.box(lane, Vector3(25.0, 1.1, SOUTH_Z), Vector3(10.0, 2.2, 0.25), "6b4a3a", true).material_override = brick
	_house(lane, Vector3(34.0, 0, 9.1), Vector3(8.0, 2.8, 5.8), -1.0)
	_banana(lane, Vector3(39.6, 0, SOUTH_Z - 0.55))
	_fence(lane, 38.0, L.LANE_END_X, SOUTH_Z)
	for x: float in [27.0, 43.0]:
		_pole(lane, Vector3(x, 0, SOUTH_Z - 0.35))
	_wire(lane, Vector3(27.0, 6.6, SOUTH_Z - 0.35), Vector3(43.0, 6.6, SOUTH_Z - 0.35))
	_wire(lane, Vector3(27.0, 6.6, SOUTH_Z - 0.35), Vector3(19.5, 5.0, -7.0))
	_wire(lane, Vector3(43.0, 6.6, SOUTH_Z - 0.35), Vector3(56.0, 4.0, 4.0))
	_street_ends(host)


## A closed house block; `face` = +1 its door faces +Z (the lane), -1 faces -Z.
static func _house(parent: Node3D, at: Vector3, size: Vector3, face: float) -> void:
	var id := "neighbour_house_a" if face > 0 else "neighbour_house_b"
	ConceptModel3D.sized(parent, id, at, size, 0.0 if face > 0 else PI)
	B.solid_block(parent, at + Vector3(0, size.y * 0.5, 0), size)



## Repeat the 3 m fence model, with one continuous collision boundary.
static func _fence(parent: Node3D, from_x: float, to_x: float, z: float) -> void:
	var segments := ceili((to_x - from_x) / 3.0)
	var width := (to_x - from_x) / segments
	for i in range(segments):
		ConceptModel3D.sized(parent, "bamboo_fence", Vector3(from_x + (i + 0.5) * width, 0, z), Vector3(0.15, 1.2, width), PI * 0.5)
	B.solid_block(parent, Vector3((from_x + to_x) * 0.5, 0.7, z), Vector3(to_x - from_x, 1.4, 0.2))



## Miếu nhỏ: complete inferred shrine on its existing collision footprint.
static func _shrine(parent: Node3D, at: Vector3) -> void:
	ConceptModel3D.spawn(parent, "roadside_shrine", at, 1.65)
	B.solid_block(parent, at + Vector3(0, 0.8, 0), Vector3(0.6, 1.6, 0.42))



## Three banana plants; keep collision low around the stems.
static func _banana(parent: Node3D, at: Vector3) -> void:
	ConceptModel3D.spawn(parent, "banana_clump", at, 2.5)
	B.solid_block(parent, at + Vector3(0, 0.8, 0.1), Vector3(1.0, 1.6, 0.6))



## Cột điện: a concrete pole with a crossbar.
static func _pole(parent: Node3D, at: Vector3) -> void:
	ConceptModel3D.spawn(parent, "power_pole", at, 6.8)
	B.solid_block(parent, at + Vector3(0, 3.4, 0), Vector3(0.2, 6.8, 0.2))



## A wire between two points, sagging in the middle (two straight pieces).
static func _wire(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5 - Vector3(0, 0.7, 0)
	for pair: Array in [[a, mid], [mid, b]]:
		var p: Vector3 = pair[0]
		var q: Vector3 = pair[1]
		var piece := B.box(parent, (p + q) * 0.5, Vector3(0.025, 0.025, p.distance_to(q)), "151515")
		piece.look_at_from_position((p + q) * 0.5, q, Vector3.UP if absf((q - p).normalized().y) < 0.99 else Vector3.RIGHT)


## The street's far ends: road on past both ends (bikes ride in from there)
## and a house front closing the west end.
static func _street_ends(host: Node3D) -> void:
	var road_z := RestaurantLayout3D.FRONT_Z + 0.2 + RestaurantLayout3D.ROAD_DEPTH * 0.5
	for x: float in [-27.0, 27.0]:
		B.box(host, Vector3(x, -0.2, road_z), Vector3(14.0, 0.2, RestaurantLayout3D.ROAD_DEPTH), "202e37").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lime := HorrorMaterials.tiled("blue_lime_wall", 2.0, Color(0.75, 0.78, 0.78))
	var west := RestaurantLayout3D.ROOM_X + 0.6
	B.box(host, Vector3(-west, 2.5, 0.25), Vector3(1.0, 5.0, 16.1), "7b8c90").material_override = lime
	B.box(host, Vector3(-west, -0.1, 0.25), Vector3(1.0, 0.2, 16.1), "4a4136")
