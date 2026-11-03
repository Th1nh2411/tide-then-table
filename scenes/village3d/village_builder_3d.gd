class_name VillageBuilder3D
extends RefCounted
## Adds the rest of Xóm Đèn around the restaurant street (VillageScene3D):
## the lane (VillageLaneBuilder3D), the waterfront (WaterfrontBuilder3D pieces
## + WaterfrontLife3D in a "Waterfront" node at VillageLayout3D.WATERFRONT),
## the bay out to the islands, Rin's house (VillageHouse3D), the land and
## houses all around (VillageBackdrop3D, StreetFacades3D, StreetLife3D), the
## real edges (VillageEdges3D), the fog loop at both ends (WorldEdgeLoop3D)
## and the fall safety net (FallSafety3D).

const L = preload("res://scenes/village3d/village_layout_3d.gd")
## The bay: size and world centre x of the water plane (it runs on under the land).
const BAY_SIZE := Vector2(620.0, 330.0)
const BAY_CENTRE_X := 230.0
## Island strips on the bay's horizon, world space: [centre, yaw, width].
const ISLANDS := [
	[Vector3(60, 0, -175), 0.0, 220.0],
	[Vector3(250, 0, -150), -0.5, 200.0],
	[Vector3(-90, 0, -190), 0.35, 140.0],
]


static func build(host: VillageScene3D) -> void:
	var front := Node3D.new()
	front.name = "Waterfront"
	host.add_child(front)
	front.position = L.WATERFRONT
	host.waterfront = front
	WaterfrontBuilder3D.build_ground(front)
	WaterfrontBuilder3D.build_scenery(front)
	for bulb: Vector3 in WaterfrontBuilder3D.lamp_posts(front):
		host.lighting.add_lamp(front, bulb, false)
	WaterfrontBuilder3D.water(front, BAY_SIZE, BAY_CENTRE_X - L.WATERFRONT.x, L.WATERFRONT.z)
	host.lighting.add_islands(SeaBackdrop3D.build_islands(host, ISLANDS))
	WaterfrontLife3D.build(front)
	VillageHouse3D.build(host)
	VillageLaneBuilder3D.build(host)
	VillageBackdrop3D.build(host)
	StreetFacades3D.build_village(host)
	StreetLife3D.build(host)
	VillageEdges3D.build(host)
	for glow: Node in host.get_tree().get_nodes_in_group(StreetFacades3D.GLOW):
		host.lighting.show_in(glow as Node3D, [VillageLighting3D.Phase.SHIFT, VillageLighting3D.Phase.NIGHT])
	WorldEdgeLoop3D.attach(host)
	FallSafety3D.attach(host, host.player)


## The dock omens once it is evening (the night's choice is read from them).
static func build_dock_omens(host: VillageScene3D) -> DockOmens3D:
	return WaterfrontBuilder3D.build_omens(host.waterfront)
