class_name VillageBackdrop3D
extends RefCounted
## What surrounds the walkable village (world coordinates): one big ground
## under everything (land everywhere but the bay), the bay's water out to the
## horizon, rows of houses and roofs behind every street, palms and trees,
## and the headland north of the lane. Far things are cheap batched boxes;
## the fog does the rest. Coastline: land west of x = 20, the headland to
## z = HEADLAND_Z for x 20..47, the shore at z = -2.5 east of that.

const B = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const GROUND_TOP := -0.15
const SHORE_Z := -2.5
const HEADLAND_Z := -9.0
const HEADLAND_X := Vector2(20.0, 47.0)
## [centre x, centre z, width, depth, rows, seed]: blocks of back houses.
const BACK_BLOCKS := [
	[-30.0, -26.0, 90.0, 18.0, 2, 1],   # behind the shop row
	[-45.0, -60.0, 70.0, 30.0, 2, 4],   # further north, towards the coast road
	[-29.0, 36.0, 82.0, 16.0, 2, 7],    # behind the far side of the road
	[46.0, 22.0, 12.0, 10.0, 1, 10],    # south of the lane, behind the banana clump
	[64.0, 18.0, 34.0, 12.0, 2, 12],    # behind the waterfront houses
	[105.0, 26.0, 50.0, 18.0, 2, 15],   # behind the east shore houses
	[56.0, 38.0, 32.0, 14.0, 1, 18],
	[150.0, 14.0, 40.0, 20.0, 2, 21],   # the far end of the bay
]


static func build(host: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Backdrop"
	host.add_child(root)
	_ground(root)
	var b := BoxBatch3D.new()
	for block: Array in BACK_BLOCKS:
		house_block(b, block)
	_trees(root, b)
	b.commit(root, "BackHouses", false)  # far: no shadow passes
	return root


## Land in three slabs around the bay, sand along the shore.
static func _ground(root: Node3D) -> void:
	var earth := HorrorMaterials.tiled("lane_dirt", 4.0, Color(0.62, 0.6, 0.52))
	var sand := HorrorMaterials.tiled("lane_dirt", 3.0, Color(1.05, 0.95, 0.78))
	var b := BoxBatch3D.new()
	var thick := 2.0
	var y := GROUND_TOP - thick * 0.5
	b.box(earth, Vector3(-90.0, y, 0.0), Vector3(220.0, thick, 400.0))
	b.box(earth, Vector3(130.0, y, (SHORE_Z + 200.0) * 0.5), Vector3(220.0, thick, 200.0 - SHORE_Z))
	b.box(earth, Vector3((HEADLAND_X.x + HEADLAND_X.y) * 0.5, y, (HEADLAND_Z + SHORE_Z) * 0.5), Vector3(HEADLAND_X.y - HEADLAND_X.x, thick, SHORE_Z - HEADLAND_Z))
	# Sand along the shores, a little proud of the earth; the bay's shore and
	# the headland's sea sides slope on into the water (ShoreBeach3D).
	b.box(sand, Vector3((HEADLAND_X.x + HEADLAND_X.y) * 0.5, GROUND_TOP + 0.02, HEADLAND_Z + 1.2), Vector3(HEADLAND_X.y - HEADLAND_X.x, 0.1, 2.4))
	b.box(sand, Vector3(18.8, GROUND_TOP + 0.02, -100.0), Vector3(2.4, 0.1, 182.0))
	b.box(sand, Vector3(HEADLAND_X.y - 1.2, GROUND_TOP + 0.02, (HEADLAND_Z + SHORE_Z) * 0.5), Vector3(2.4, 0.1, SHORE_Z - HEADLAND_Z))
	b.commit(root, "Ground", false)
	# One collider under all the land (the walkers have no gravity; tests and
	# the fall safety net read it as "ground here").
	B.solid_block(root, Vector3(-90.0, y, 0.0), Vector3(220.0, thick, 400.0))
	B.solid_block(root, Vector3(130.0, y, (SHORE_Z + 200.0) * 0.5), Vector3(220.0, thick, 200.0 - SHORE_Z))
	B.solid_block(root, Vector3((HEADLAND_X.x + HEADLAND_X.y) * 0.5, y, (HEADLAND_Z + SHORE_Z) * 0.5), Vector3(HEADLAND_X.y - HEADLAND_X.x, thick, SHORE_Z - HEADLAND_Z))


## A block of simple houses: plaster bodies, tin gables or flat roofs.
static func house_block(b: BoxBatch3D, block: Array) -> void:
	var cx: float = block[0]
	var cz: float = block[1]
	var w: float = block[2]
	var d: float = block[3]
	var rows: int = block[4]
	var seed_: int = block[5]
	var tin := HorrorMaterials.tiled("roof_tin_rusty", 1.6)
	for r in rows:
		var z := cz - d * 0.5 + (float(r) + 0.5) * d / float(rows)
		var x := cx - w * 0.5
		var i := seed_ + r * 5
		while x < cx + w * 0.5:
			var hw := 4.0 + float((i * 7) % 5) * 0.9
			var h := 3.4 + float((i * 3) % 6) * 1.3
			var depth := minf(d / float(rows) - 1.0, 9.0)
			var spec: Array = TubeHouse3D.WALLS[i % TubeHouse3D.WALLS.size()]
			var wall := HorrorMaterials.tiled(spec[0], 2.2, (spec[1] as Color).darkened(0.12))
			var at := Vector3(x + hw * 0.5, 0, z + float((i * 13) % 3) - 1.0)
			b.box(wall, at + Vector3(0, h * 0.5 + GROUND_TOP, 0), Vector3(hw - 0.3, h, depth))
			if i % 3 != 1:
				b.gable(tin, at + Vector3(0, h + GROUND_TOP, 0), Vector3(hw + 0.3, 1.2 + float(i % 2) * 0.6, depth + 0.6), 0.0 if i % 2 else PI * 0.5)
			else:
				b.box(tin, at + Vector3(0, h + GROUND_TOP + 0.3, 0), Vector3(hw * 0.6, 0.6, depth * 0.5))
			var dark := BoxBatch3D.color("1d1f22")
			b.box(dark, at + Vector3(0, minf(h - 1.2, 4.6) + GROUND_TOP, -depth * 0.5 - 0.02), Vector3(0.9, 1.1, 0.04))
			b.box(dark, at + Vector3(0, minf(h - 1.2, 4.6) + GROUND_TOP, depth * 0.5 + 0.02), Vector3(0.9, 1.1, 0.04))
			x += hw + float(i % 2) * 1.5
			i += 1


## Palms and bàng trees between and over the back houses, a tree line on the coast.
static func _trees(root: Node3D, b: BoxBatch3D) -> void:
	var palms := [Vector3(-8, 0, -19), Vector3(12, 0, -22), Vector3(-36, 0, -21), Vector3(-58, 0, -24),
		Vector3(5, 0, -35), Vector3(-20, 0, -44), Vector3(16, 0, -12), Vector3(-12, 0, 29), Vector3(-44, 0, 30),
		Vector3(8, 0, 31), Vector3(52, 0, 13), Vector3(78, 0, 13.5), Vector3(90, 0, 15), Vector3(120, 0, 14),
		Vector3(136, 0, 4), Vector3(150, 0, 2), Vector3(175, 0, 6), Vector3(18, 0, -30), Vector3(17, 0, -55),
		Vector3(15, 0, -80), Vector3(46, 0, 24), Vector3(28, 0, 40), Vector3(-66, 0, -40), Vector3(110, 0, 30)]
	for i in palms.size():
		var at: Vector3 = palms[i] + Vector3(0, GROUND_TOP, 0)
		VillageProps3D.place(root, "coconut_palm", at, Vector3(4.0, 9.0 + float(i % 4) * 1.5, 4.0), float(i) * 1.7, b)
	var trees := [Vector3(-26, 0, -34), Vector3(-2, 0, -28), Vector3(-50, 0, -50), Vector3(30, 0, 30),
		Vector3(-30, 0, 46), Vector3(70, 0, 30), Vector3(95, 0, 34), Vector3(8, 0, -60), Vector3(10, 0, -100)]
	for i in trees.size():
		var at: Vector3 = trees[i] + Vector3(0, GROUND_TOP, 0)
		VillageProps3D.place(root, "tree_bang", at, Vector3(6.0, 8.0 + float(i % 3) * 1.5, 6.0), float(i), b)
