class_name RamEpilogueShop3D
extends RefCounted
## The bad ending's set (RamEpilogue3D "drowned"): a year later, night, the
## corner of the restaurant street. Rin's ghost sits where chú Bảy sat, the
## cup in front of him full and cold. A young fisherman walks in from the
## road and sits down at anh Út's table; anh Út pours the ginger tea. The
## drifting thúng with the green cord is out on the water behind the street.
## Built away from the waterfront (ORIGIN), lit by a few weak bulbs.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const ORIGIN := Vector3(-70.0, 0, 0)
## Set-local: Rin's seat (the corner stool), his table, anh Út's table.
const SEAT := Vector3(0, 0, 0)
const TABLE := Vector3(0.95, 0, 0)
const UT_TABLE := Vector3(5.2, 0, 1.4)
const UT_SEAT := UT_TABLE + Vector3(0.95, 0, 0)
const YOUNG_SEAT := UT_TABLE + Vector3(-0.95, 0, 0)
const YOUNG_FROM := Vector3(9.5, 0, 6.0)


## Builds the set under `host`; returns {"eye", "look", "ut", "young", "from", "to"} in world space.
static func build(host: Node3D) -> Dictionary:
	var stage := Node3D.new()
	stage.name = "ShopCorner"
	host.add_child(stage)
	stage.position = ORIGIN
	B.box(stage, Vector3(4.0, -0.1, 2.0), Vector3(22, 0.2, 16), "3a3a36", true).material_override = HorrorMaterials.tiled("tiles_cement_floor", 1.0, Color(0.6, 0.6, 0.56))
	B.box(stage, Vector3(4.0, -0.09, 7.6), Vector3(22, 0.2, 4.0), "26282a", true)
	# Shop fronts behind, a wall on the west.
	B.box(stage, Vector3(4.0, 2.6, -2.6), Vector3(22, 5.2, 0.4), "4a4038").material_override = HorrorMaterials.tiled("brick_wall_old", 1.0, Color(0.55, 0.5, 0.46))
	B.box(stage, Vector3(-1.6, 2.6, 2.0), Vector3(0.4, 5.2, 9.0), "4a4038").material_override = HorrorMaterials.tiled("blue_lime_wall", 1.0, Color(0.5, 0.55, 0.56))
	# The bulbs' wire, strung from the wall to a pole by the road.
	OmenProps3D.box(stage, Vector3(4.0, 3.0, 1.0), Vector3(11.0, 0.02, 0.02), "1e1c1a").rotation.y = -0.2
	OmenProps3D.box(stage, Vector3(9.6, 1.5, 2.2), Vector3(0.12, 3.0, 0.12), "3a3430")
	_table(stage, TABLE, SEAT)
	_table(stage, UT_TABLE, UT_SEAT)
	var stool: Node3D = B.STOOL_PILOT.instantiate()
	stage.add_child(stool)
	stool.position = YOUNG_SEAT
	stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
	# His cup (full, no steam); anh Út's pot and two cups.
	OmenProps3D.box(stage, TABLE + Vector3(-0.2, 0.875, 0.1), Vector3(0.075, 0.07, 0.075), "cfc6ae")
	OmenProps3D.box(stage, TABLE + Vector3(-0.2, 0.911, 0.1), Vector3(0.062, 0.004, 0.062), "5a3c1c")
	OmenProps3D.box(stage, UT_TABLE + Vector3(0.1, 0.92, -0.2), Vector3(0.18, 0.16, 0.18), "6b4a32")
	for dz: float in [0.15, -0.05]:
		OmenProps3D.box(stage, UT_TABLE + Vector3(-0.2, 0.88, dz), Vector3(0.08, 0.08, 0.08), "e8d9b7")
	for at: Vector3 in [TABLE + Vector3(0, 2.5, 0), UT_TABLE + Vector3(0, 2.5, 0), Vector3(9.0, 2.6, 2.0)]:
		OmenProps3D.glow_box(stage, at, Vector3(0.1, 0.12, 0.1), "e8c890", 1.4)
		OmenProps3D.box(stage, at + Vector3(0, 0.4, 0), Vector3(0.015, 0.7, 0.015), "1e1c1a")
		OmenProps3D.light(stage, at - Vector3(0, 0.15, 0), "e8c890", 0.7, 5.5)
	B.box(stage, Vector3(4.0, -0.45, 20.0), Vector3(40, 0.1, 20), "0e171a")
	# Out past the road, the empty thúng drifting with the green cord.
	var drift := ThungHull3D.place(stage, -0.24, "DriftThung")
	drift.position += Vector3(6.0, 0, 13.0)
	var rim := ThungHull3D.rim_point(drift, Vector2(-1.16, -0.2)) - drift.position
	ThungCharm3D.tie(stage, drift.position + rim, atan2(-rim.z, rim.x), false).scale = Vector3.ONE * 2.0
	OmenProps3D.light(stage, drift.position + Vector3(0, 1.4, 0), "7fa8a0", 0.6, 4.0)
	var ut := PersonRig3D.build(stage, "guest_rich")
	ut.position = UT_SEAT
	ut.rotation.y = -PI * 0.5
	ut.set_seated(true)
	var young := PersonRig3D.build(stage, "guest_3")
	young.position = YOUNG_FROM
	return {
		"eye": stage.to_global(SEAT + Vector3(0, 1.05, 0)),
		"look": stage.to_global(UT_TABLE + Vector3(0, 0.9, 1.4)),
		"ut": ut, "young": young,
		"from": YOUNG_FROM, "to": YOUNG_SEAT + Vector3(0, 0, 0.9),
		"seat": YOUNG_SEAT,
	}


static func _table(stage: Node3D, at: Vector3, seat: Vector3) -> void:
	RestaurantFurniture3D.table(stage, at, RestaurantLayout3D.TABLE_YAW)
	var stool: Node3D = B.STOOL_PILOT.instantiate()
	stage.add_child(stool)
	stool.position = seat
	stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
