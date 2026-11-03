class_name SeaShore3D
extends RefCounted
## Xóm Đèn seen from the night sea: the land strip behind the dock as packed
## sand, a row of tube houses facing the water with lit windows, rows of roofs
## behind, leaning palms and a few lamp posts whose bulbs glow. Scenery only:
## the land's collider stays SeaWorldBuilder3D's.

const FRONT_GAP := 2.5  # sand between the waterline and the house fronts


static func build(sea: Node3D, shore_z: float, width: float) -> void:
	var b := BoxBatch3D.new()
	var night := BoxBatch3D.new()
	var sand := HorrorMaterials.tiled("lane_dirt", 3.0, Color(0.9, 0.84, 0.7))
	b.box(sand, Vector3(0, -0.1, shore_z + 40.0), Vector3(width + 120.0, 0.62, 80.0))
	var front := shore_z + FRONT_GAP + 3.5
	var x := -width * 0.5 - 30.0
	var i := 0
	var dock_x: float = SeaLayout3D.to_world(SeaLayout3D.DOCK_PX).x
	while x < width * 0.5 + 30.0:
		var w := 4.2 + float((i * 5) % 4) * 0.8
		if absf(x + w * 0.5 - dock_x) > 9.0:  # the dock's own lane stays open
			TubeHouse3D.build(sea, b, night, Vector3(x + w * 0.5, 0.2, front), Vector3(w, 3.8 + float((i * 7) % 4) * 1.3, 8.0), PI, i)
		x += w + float(i % 3) * 0.6
		i += 1
	for block: Array in [[-20.0, front + 16.0, width + 40.0, 14.0, 2, 3], [10.0, front + 30.0, width, 12.0, 1, 9]]:
		VillageBackdrop3D.house_block(b, block)
	for k in 9:
		var at := Vector3(-70.0 + float(k) * 17.0 + float(k % 2) * 4.0, 0.2, shore_z + FRONT_GAP - 0.4 + float(k % 3) * 0.6)
		VillageProps3D.place(sea, "coconut_palm", at, Vector3(4.0, 8.0 + float(k % 3) * 1.5, 4.0), float(k) * 2.1 + PI, b)
	for k in 5:
		var post := Vector3(-48.0 + float(k) * 24.0, 0.2, shore_z + FRONT_GAP + 0.8)
		VillageProps3D.place(sea, "lamp_post_village", post, Vector3(0.5, 3.4, 1.0), 0.0, b)
		night.box(BoxBatch3D.color("ffd39b", 2.5), post + Vector3(0, 3.06, -0.7), Vector3(0.12, 0.14, 0.12))
		if k % 2 == 0:
			SeaWorldBuilder3D.glow(sea, post + Vector3(0, 2.9, -0.8), "ffc27a", 0.9, 7.0, false)
	b.commit(sea, "ShoreVillage")
	night.commit(sea, "ShoreVillageGlow", false)
