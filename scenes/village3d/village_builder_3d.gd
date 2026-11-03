class_name VillageBuilder3D
extends RefCounted
## Adds the rest of Xóm Đèn around the restaurant street (VillageScene3D):
## the lane (VillageLaneBuilder3D), the waterfront (WaterfrontBuilder3D pieces
## in a "Waterfront" node at VillageLayout3D.WATERFRONT), the sea off it,
## Rin's house (VillageHouse3D) and invisible walls at the edges of the
## walkable ground (shore, pier sides, the far ends).

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const L = preload("res://scenes/village3d/village_layout_3d.gd")
const WALL_H := 3.0


static func build(host: VillageScene3D) -> void:
	var front := Node3D.new()
	front.name = "Waterfront"
	host.add_child(front)
	front.position = L.WATERFRONT
	host.waterfront = front
	WaterfrontBuilder3D.build_ground(front)
	WaterfrontBuilder3D.build_scenery(front)
	for bulb: Vector3 in WaterfrontBuilder3D.lamp_posts(front):
		host.lighting.add_lamp(front, bulb)
	# The sea starts east of the street's back so it never runs under the shops.
	WaterfrontBuilder3D.water(front, Vector2(120, 110), 26.0, L.WATERFRONT.z)
	SeaBackdrop3D.build_islands(front)
	for child in front.get_children():
		if String(child.name).contains("DistantIslands") and (child as Node3D).position.x < 0.0:
			child.queue_free()  # the western strip would stand over the street
	VillageHouse3D.build(host)
	VillageLaneBuilder3D.build(host)
	_bounds(host)


## The dock omens once it is evening (the night's choice is read from them).
static func build_dock_omens(host: VillageScene3D) -> DockOmens3D:
	return WaterfrontBuilder3D.build_omens(host.waterfront)


static func _bounds(host: Node3D) -> void:
	var gx := L.GROUND_X
	var gz := L.GROUND_Z
	var lane_n := VillageLaneBuilder3D.NORTH_Z
	var lane_s := VillageLaneBuilder3D.SOUTH_Z
	# West side of the waterfront, either side of the lane's mouth.
	_wall_z(host, gx.x, gz.x, lane_n)
	_wall_z(host, gx.x, lane_s, gz.y)
	_wall_z(host, gx.y, gz.x, gz.y)
	_wall_x(host, gz.y, gx.x, gx.y)
	# Shore, open only where the pier starts; then the pier's sides and end.
	_wall_x(host, gz.x, gx.x, L.PIER_X.x)
	_wall_x(host, gz.x, L.PIER_X.y, gx.y)
	_wall_z(host, L.PIER_X.x, L.PIER_END_Z, gz.x)
	_wall_z(host, L.PIER_X.y, L.PIER_END_Z, gz.x)
	_wall_x(host, L.PIER_END_Z, L.PIER_X.x, L.PIER_X.y)


## Wall along z at `x`, from z0 to z1.
static func _wall_z(host: Node3D, x: float, z0: float, z1: float) -> void:
	B.solid_block(host, Vector3(x, WALL_H * 0.5, (z0 + z1) * 0.5), Vector3(0.15, WALL_H, absf(z1 - z0)))


## Wall along x at `z`, from x0 to x1.
static func _wall_x(host: Node3D, z: float, x0: float, x1: float) -> void:
	B.solid_block(host, Vector3((x0 + x1) * 0.5, WALL_H * 0.5, z), Vector3(absf(x1 - x0), WALL_H, 0.15))
