class_name WaterfrontLife3D
extends RefCounted
## A 1990s fishing village's waterfront (in the "Waterfront" node's local
## space, see WaterfrontBuilder3D): boats pulled up on the sand, net heaps, a
## fish-drying rack, a clothesline, water jars and potted plants by the
## houses, a parked Cub, leaning palms, stones and seaweed at the waterline,
## baskets, buoys, a rubbish heap; out on the water moored boats, floats and
## stakes. The path lane -> house -> pier stays clear (horror_models_test).

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const W = preload("res://scenes/home3d/waterfront_builder_3d.gd")


static func build(front: Node3D) -> void:
	var b := BoxBatch3D.new()
	# Boats pulled up on the sand, bows to the sea.
	_prop(front, b, "boat_pulled_up", Vector3(-3.5, 0, 3.4), Vector3(1.6, 0.9, 4.6), 0.35)
	_prop(front, b, "boat_pulled_up", Vector3(13.2, 0, 3.6), Vector3(1.5, 0.85, 4.2), -0.25)
	_prop(front, b, "thung_boat", Vector3(1.8, 0, 3.0), Vector3(1.8, 0.6, 1.8), 0.0)
	_prop(front, b, "net_heap", Vector3(-0.6, 0, 5.0), Vector3(1.6, 0.5, 1.2), 0.4)
	_prop(front, b, "net_heap", Vector3(10.2, 0, 5.4), Vector3(1.4, 0.45, 1.1), 1.2)
	_prop(front, b, "fish_drying_rack", Vector3(-7.4, 0, 5.0), Vector3(2.6, 0.95, 1.3), 0.05)
	_prop(front, b, "clothesline", Vector3(2.6, 0, 10.4), Vector3(3.2, 1.9, 0.3), 0.0, false)
	_prop(front, b, "buoy_pile", Vector3(14.6, 0, 6.4), Vector3(1.4, 0.7, 1.2), 0.0)
	_prop(front, b, "rubbish_heap", Vector3(-15.6, 0, 12.6), Vector3(1.5, 0.6, 1.2), 0.3)
	_prop(front, b, StreetLife3D._bike_id(), Vector3(11.6, 0, 9.0), Vector3(0.7, 1.1, 1.8), 1.3)
	for at: Vector3 in [Vector3(-6.0, 0, 10.0), Vector3(4.4, 0, 9.4)]:
		ConceptModel3D.spawn(front, "water_jar", at, 0.75)
		B.solid_block(front, at + Vector3(0, 0.35, 0), Vector3(0.6, 0.7, 0.6))
	for at: Vector3 in [Vector3(-4.2, 0, 9.7), Vector3(0.9, 0, 9.9), Vector3(-10.4, 0, 9.9)]:
		VillageProps3D.place(front, "plant_pot", at, Vector3(0.6, 0.8, 0.6))
	for at: Vector3 in [Vector3(4.9, 0, 3.1), Vector3(7.7, 0, 3.4), Vector3(8.3, 0, 3.0)]:
		ConceptModel3D.spawn(front, "fish_basket", at, 0.45)
	# Leaning palms on the sand (no collider for the thin trunks out of reach).
	for spec: Array in [[Vector3(-15.2, 0, 4.2), 9.5, 2.4], [Vector3(15.6, 0, 8.2), 8.0, 4.0], [Vector3(-9.6, 0, 2.6), 7.5, 0.9]]:
		VillageProps3D.place(front, "coconut_palm", spec[0], Vector3(4.0, spec[1], 4.0), spec[2], b)
		B.solid_block(front, (spec[0] as Vector3) + Vector3(0, 1.0, 0), Vector3(0.4, 2.0, 0.4))
	# Stones and seaweed along the waterline, both sides of the pier.
	_prop(front, b, "seaweed_stones", Vector3(-6.0, -0.05, 2.0), Vector3(16.0, 0.4, 1.2), 0.0, false)
	_prop(front, b, "seaweed_stones", Vector3(12.0, -0.05, 2.0), Vector3(9.0, 0.4, 1.2), 0.0, false)
	_water(front, b)
	b.commit(front, "WaterfrontLife")


## A prop with a box collider over its footprint (`solid` false: walk-through / out of reach).
static func _prop(front: Node3D, b: BoxBatch3D, id: String, at: Vector3, size: Vector3, yaw: float, solid: bool = true) -> void:
	VillageProps3D.place(front, id, at, size, yaw, b)
	if solid:
		var body := StaticBody3D.new()
		front.add_child(body)
		body.position = at + Vector3(0, size.y * 0.5, 0)
		body.rotation.y = yaw
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)


## Moored boats, floats and bamboo stakes off the shore.
static func _water(front: Node3D, b: BoxBatch3D) -> void:
	var y := W.WATER_Y - 0.25
	VillageProps3D.place(front, "boat_pulled_up", Vector3(-2.0, y, -6.5), Vector3(1.8, 1.0, 5.0), 1.2, b)
	VillageProps3D.place(front, "boat_pulled_up", Vector3(14.0, y, -9.0), Vector3(1.8, 1.0, 5.2), -0.4, b)
	VillageProps3D.place(front, "boat_pulled_up", Vector3(21.0, y, -3.5), Vector3(1.6, 0.9, 4.4), 0.2, b)
	VillageProps3D.place(front, "thung_boat", Vector3(10.5, y + 0.1, -5.5), Vector3(1.8, 0.6, 1.8), 0.0, b)
	var float_mat := BoxBatch3D.color("b8622a")
	var white := BoxBatch3D.color("cfc8b4")
	var stake := BoxBatch3D.color("4a3a2c")
	var floats := [Vector3(-8, 0, -9), Vector3(-5, 0, -12), Vector3(2, 0, -14), Vector3(11, 0, -13), Vector3(18, 0, -11), Vector3(-12, 0, -15)]
	for i in floats.size():
		b.box(float_mat if i % 2 else white, (floats[i] as Vector3) + Vector3(0, W.WATER_Y + 0.05, 0), Vector3(0.35, 0.3, 0.35), float(i))
	for i in 9:
		var at := Vector3(-14.0 + float(i) * 1.1, 0, -2.0 - float(i % 3) * 0.6)
		b.box(stake, at + Vector3(0, -0.1, 0), Vector3(0.09, 1.4 + 0.3 * float(i % 2), 0.09), 0.0, 0.08 * float(i % 3 - 1))
	for i in 6:
		var at := Vector3(16.0 + float(i) * 1.3, 0, -1.5 - float(i % 2))
		b.box(stake, at + Vector3(0, -0.1, 0), Vector3(0.09, 1.5, 0.09))
