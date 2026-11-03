class_name VillageNature3D
extends RefCounted
## Low-poly stand-in plants for the village (VillageStandins3D hands them a
## Put): leaning coconut palms, bàng trees, the street's planter trees,
## bamboo clumps, a vegetable patch, stones and seaweed at the waterline.

static func build(p: VillageStandins3D.Put, id: String) -> void:
	match id:
		"coconut_palm":
			_palm(p)
		"tree_bang":
			_tree(p, false)
		"planter_tree_street":
			_tree(p, true)
		"bamboo_clump":
			_bamboo(p)
		"vegetable_patch":
			_patch(p)
		"seaweed_stones":
			_stones(p)


## Curved trunk in four leaning pieces, a crown of drooping fronds, nuts.
static func _palm(p: VillageStandins3D.Put) -> void:
	var h := p.size.y
	var bark := BoxBatch3D.color("5a4c3e")
	var lean := 0.22
	var top := Vector3.ZERO
	for i in 4:
		var piece := h * 0.25
		var bend := lean * (0.4 + 0.25 * float(i))
		var mid := top + Vector3(0, cos(bend), -sin(bend)) * piece * 0.5
		p.box(bark, mid, Vector3(0.26 - 0.03 * float(i), piece * 1.05, 0.26 - 0.03 * float(i)), 0.0, -bend)
		top += Vector3(0, cos(bend), -sin(bend)) * piece
	var frond := BoxBatch3D.color("3e5236")
	var dry := BoxBatch3D.color("6b6440")
	for i in 9:
		var a := TAU * float(i) / 9.0 + 0.3
		var length := h * (0.28 + 0.05 * float(i % 3))
		var out := Vector3(sin(a), 0, cos(a))
		var droop := 0.35 + 0.25 * float(i % 2)
		var centre := top + out * length * 0.45 - Vector3(0, length * 0.2 * droop, 0)
		p.box(dry if i % 4 == 0 else frond, centre, Vector3(length * 0.32, 0.05, length), a, droop)
	for i in 3:
		var a := TAU * float(i) / 3.0
		p.box(BoxBatch3D.color("4a4a2a"), top + Vector3(sin(a) * 0.2, -0.2, cos(a) * 0.2), Vector3(0.22, 0.24, 0.22))


## Bàng tree (or the street planter tree): trunk, branch, stacked flat crowns.
static func _tree(p: VillageStandins3D.Put, planter: bool) -> void:
	var h := p.size.y
	var w := p.size.x
	if planter:
		var brick := HorrorMaterials.tiled("brick_wall_old", 1.0, Color(0.7, 0.66, 0.6))
		p.box(brick, Vector3(0, 0.22, 0), Vector3(1.0, 0.44, 1.0))
		p.box(BoxBatch3D.color("3b3128"), Vector3(0, 0.45, 0), Vector3(0.84, 0.03, 0.84))
	var bark := BoxBatch3D.color("4e4034")
	p.box(bark, Vector3(0, h * 0.3, 0), Vector3(0.24, h * 0.6, 0.24), 0.0, 0.0, 0.05)
	p.box(bark, Vector3(0.35, h * 0.55, 0), Vector3(0.12, h * 0.3, 0.12), 0.0, 0.0, -0.6)
	# Crown: lumpy clusters of leaves around and over the branch ends.
	var leaf: Array[String] = ["3a4a34", "33452f", "44533a", "2f4030"]
	for i in 9:
		var a := TAU * float(i) / 7.0 + 0.4
		var ring := 0.0 if i >= 7 else w * 0.3
		var y := h * (0.68 + 0.08 * float(i % 3)) + (h * 0.12 if i >= 7 else 0.0)
		var lump := w * (0.42 + 0.08 * float(i % 3))
		p.box(BoxBatch3D.color(leaf[i % 4]), Vector3(sin(a) * ring, y, cos(a) * ring), Vector3(lump, lump * 0.62, lump * 0.9), a * 1.3, 0.15 * float(i % 2))


## Clump of leaning bamboo culms with leafy tops: a soft, real edge.
static func _bamboo(p: VillageStandins3D.Put) -> void:
	var h := p.size.y
	var culm := BoxBatch3D.color("6e7a44")
	var leaf := BoxBatch3D.color("4a5a34")
	for i in 11:
		var a := TAU * float(i) * 0.39
		var r := p.size.x * 0.35 * (0.3 + 0.7 * float(i % 4) / 3.0)
		var base := Vector3(sin(a) * r, 0, cos(a) * r)
		var lean := 0.12 + 0.05 * float(i % 3)
		var height := h * (0.75 + 0.25 * float((i * 7) % 4) / 3.0)
		p.box(culm, base + Vector3(sin(a), 0, cos(a)) * height * 0.5 * sin(lean) + Vector3(0, height * 0.5, 0), Vector3(0.09, height, 0.09), a, lean)
		var tip := base + Vector3(sin(a), 0, cos(a)) * height * sin(lean) + Vector3(0, height * 0.92, 0)
		p.box(leaf, tip, Vector3(p.size.x * 0.35, height * 0.18, p.size.x * 0.3), a)
	p.box(leaf, Vector3(0, h * 0.6, 0), Vector3(p.size.x * 0.8, h * 0.3, p.size.z * 0.8))


## Raised rows of greens with a low bamboo edge.
static func _patch(p: VillageStandins3D.Put) -> void:
	var s := p.size
	var soil := BoxBatch3D.color("3e3226")
	var green: Array[String] = ["4b5e36", "56683c", "3f5531"]
	var rows := maxi(int(s.z / 0.9), 2)
	for i in rows:
		var z := (float(i) + 0.5) / float(rows) * s.z - s.z * 0.5
		p.box(soil, Vector3(0, 0.08, z), Vector3(s.x, 0.16, 0.6))
		for j in int(s.x / 0.45):
			var x := (float(j) + 0.5) * 0.45 - s.x * 0.5
			p.box(BoxBatch3D.color(green[(i + j) % 3]), Vector3(x, 0.24, z), Vector3(0.3, 0.18 + 0.06 * float((i + j) % 2), 0.3), 0.4 * float(j))


## Stones and dark seaweed along the waterline.
static func _stones(p: VillageStandins3D.Put) -> void:
	var s := p.size
	for i in 14:
		var u := (float(i) + 0.5) / 14.0 - 0.5
		var v := sin(float(i) * 2.3) * 0.4
		var hex := "5c5a52" if i % 3 else "2f3a2c"
		var piece := Vector3(0.35 + 0.25 * float(i % 3), 0.18 + 0.1 * float(i % 2), 0.3 + 0.2 * float((i + 1) % 3))
		if i % 3 == 0:
			piece = Vector3(0.6, 0.04, 0.35)  # seaweed mat
		p.box(BoxBatch3D.color(hex), Vector3(u * s.x, piece.y * 0.4, v * s.z), piece, float(i) * 0.7)
