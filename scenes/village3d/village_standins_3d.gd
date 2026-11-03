class_name VillageStandins3D
extends RefCounted
## Low-poly stand-ins for village props that have no model yet (VillageProps3D
## uses them when assets/models/ready/<id>/ is missing): boats, the Cub, the
## drying rack, clothesline, tin shed, lamp post, heaps. Trees and plants are
## in VillageNature3D. Everything goes into a BoxBatch3D in local space
## (origin on the ground, turned `yaw`), sized by `size`.

## Builds stand-in `id`; unknown ids get a plain crate.
static func build(batch: BoxBatch3D, id: String, at: Vector3, size: Vector3, yaw: float) -> void:
	var p := Put.new(batch, at, yaw, size)
	match id:
		"coconut_palm", "tree_bang", "planter_tree_street", "bamboo_clump", "vegetable_patch", "seaweed_stones":
			VillageNature3D.build(p, id)
		"boat_pulled_up":
			_boat(p, false)
		"boat_upturned":
			_boat(p, true)
		"thung_boat":
			_thung(p)
		"motorbike_cub":
			_cub(p)
		"fish_drying_rack":
			_rack(p)
		"clothesline":
			_clothesline(p)
		"shed_tin":
			_shed(p)
		"lamp_post_village":
			_lamp_post(p)
		"buoy_pile", "net_heap", "rubbish_heap":
			_heap(p, id)
		_:
			p.box(wood(), Vector3(0, size.y * 0.5, 0), size)


static func wood() -> Material:
	return HorrorMaterials.tiled("floor_wood_planks", 1.2, Color(0.62, 0.55, 0.48))


static func tin() -> Material:
	return HorrorMaterials.tiled("roof_tin_rusty", 1.4)


## Wooden fishing boat (ghe), on its keel or upturned; long axis local Z.
static func _boat(p: Put, upturned: bool) -> void:
	var s := p.size
	var paint := BoxBatch3D.color("3e5a5c")
	var tar := BoxBatch3D.color("2a2422")
	if upturned:
		p.box(tar, Vector3(0, s.y * 0.15, 0), Vector3(s.x * 0.9, s.y * 0.3, s.z * 0.7))
		p.gable(paint, Vector3(0, s.y * 0.3, 0), Vector3(s.z * 0.7, s.y * 0.7, s.x), PI * 0.5)
		for end: float in [-1.0, 1.0]:
			p.box(paint, Vector3(0, s.y * 0.4, end * s.z * 0.42), Vector3(s.x * 0.5, s.y * 0.5, s.z * 0.18), end * 0.0)
		return
	# Hull: keel, a solid painted body, a rim band, pointed raised ends, thwarts, eyes.
	p.box(tar, Vector3(0, s.y * 0.12, 0), Vector3(s.x * 0.35, s.y * 0.24, s.z * 0.7))
	p.box(paint, Vector3(0, s.y * 0.42, 0), Vector3(s.x * 0.85, s.y * 0.5, s.z * 0.6))
	for side: float in [-1.0, 1.0]:
		p.box(BoxBatch3D.color("8a3a2c"), Vector3(side * s.x * 0.44, s.y * 0.69, 0), Vector3(0.1, 0.08, s.z * 0.6))
	for end: float in [-1.0, 1.0]:
		for side: float in [-1.0, 1.0]:
			p.box(paint, Vector3(side * s.x * 0.2, s.y * 0.45, end * s.z * 0.37), Vector3(0.1, s.y * 0.62, s.z * 0.24), side * end * 0.62)
		p.box(paint, Vector3(0, s.y * 0.62, end * s.z * 0.48), Vector3(0.14, s.y * 0.85, 0.14), 0.0, end * 0.35)
	p.box(BoxBatch3D.color("2a2725"), Vector3(0, s.y * 0.68, 0), Vector3(s.x * 0.75, 0.04, s.z * 0.56))
	for z: float in [-0.12, 0.18]:
		p.box(wood(), Vector3(0, s.y * 0.72, s.z * z), Vector3(s.x * 0.9, 0.06, 0.28))
	for side: float in [-1.0, 1.0]:
		p.box(BoxBatch3D.color("d8d0b8"), Vector3(side * s.x * 0.43, s.y * 0.5, -s.z * 0.27), Vector3(0.03, 0.12, 0.2))
		p.box(BoxBatch3D.color("1a1a1a"), Vector3(side * s.x * 0.44, s.y * 0.5, -s.z * 0.27), Vector3(0.03, 0.07, 0.08))


## Round basket boat (thúng chai): a ring of tarred staves and a dark floor.
static func _thung(p: Put) -> void:
	var r := p.size.x * 0.5
	var h := p.size.y
	var tar := BoxBatch3D.color("2b2622")
	var weave := BoxBatch3D.color("5a4a36")
	p.box(tar, Vector3(0, 0.08, 0), Vector3(r * 1.5, 0.12, r * 1.5), PI * 0.25)
	p.box(tar, Vector3(0, 0.08, 0), Vector3(r * 1.5, 0.12, r * 1.5))
	for i in 12:
		var a := TAU * float(i) / 12.0
		p.box(weave if i % 2 else tar, Vector3(sin(a) * r * 0.9, h * 0.5, cos(a) * r * 0.9), Vector3(r * 0.5, h, 0.08), a, 0.0, 0.0, -0.25)
	p.box(wood(), Vector3(0, h * 0.75, 0), Vector3(r * 1.6, 0.06, 0.25))


## Honda Cub-like moped, long axis local Z.
static func _cub(p: Put) -> void:
	var s := p.size
	var dark := BoxBatch3D.color("1c1c1e")
	var body := BoxBatch3D.color("6b2a2a")
	var cream := BoxBatch3D.color("b9b19a")
	for end: float in [-1.0, 1.0]:
		p.box(dark, Vector3(0, 0.3, end * s.z * 0.35), Vector3(0.1, 0.6, 0.6))
	p.box(body, Vector3(0, 0.55, 0.1), Vector3(0.3, 0.35, s.z * 0.45))
	p.box(cream, Vector3(0, 0.75, -s.z * 0.28), Vector3(0.38, 0.65, 0.12), 0.0, -0.2)
	p.box(dark, Vector3(0, 0.82, 0.25), Vector3(0.28, 0.12, 0.65))
	p.box(body, Vector3(0, 1.0, -s.z * 0.33), Vector3(0.62, 0.06, 0.08))
	p.box(cream, Vector3(0, 1.0, -s.z * 0.4), Vector3(0.16, 0.14, 0.1))
	p.box(dark, Vector3(0, 0.62, s.z * 0.35), Vector3(0.32, 0.06, 0.38))


## Bamboo rack with a slatted tray of drying fish.
static func _rack(p: Put) -> void:
	var s := p.size
	var bamboo := BoxBatch3D.color("8a7a4e")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			p.box(bamboo, Vector3(x * s.x * 0.45, s.y * 0.5, z * s.z * 0.42), Vector3(0.06, s.y, 0.06))
	p.box(BoxBatch3D.color("6d6247"), Vector3(0, s.y * 0.92, 0), Vector3(s.x * 0.95, 0.04, s.z * 0.9))
	var fish := BoxBatch3D.color("a9a59a")
	for i in 14:
		var u := (float(i % 7) + 0.5) / 7.0 - 0.5
		var v := 0.25 if i < 7 else -0.25
		p.box(fish, Vector3(u * s.x * 0.85, s.y * 0.95, v * s.z), Vector3(0.12, 0.03, 0.3), 0.15 * float(i % 3))


## Two posts, a sagging line and a few washed clothes.
static func _clothesline(p: Put) -> void:
	var s := p.size
	var post := BoxBatch3D.color("5d4a36")
	for x: float in [-1.0, 1.0]:
		p.box(post, Vector3(x * s.x * 0.5, s.y * 0.5, 0), Vector3(0.08, s.y, 0.08))
	p.box(BoxBatch3D.color("202020"), Vector3(0, s.y * 0.95, 0), Vector3(s.x, 0.02, 0.02))
	var cloth: Array[String] = ["7a6a58", "4d5f6e", "8a8478", "6e4a44", "5b6b52"]
	for i in cloth.size():
		var x := (float(i) + 0.5) / float(cloth.size()) - 0.5
		p.box(BoxBatch3D.color(cloth[i]), Vector3(x * s.x * 0.9, s.y * 0.95 - 0.35 - 0.1 * float(i % 2), 0), Vector3(0.45, 0.7 + 0.2 * float(i % 2), 0.03))


## Open tin shed: posts, a sloping roof, a back wall, a few crates inside.
static func _shed(p: Put) -> void:
	var s := p.size
	var post := BoxBatch3D.color("4a3c30")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			p.box(post, Vector3(x * s.x * 0.47, (s.y - 0.3 * z) * 0.5, z * s.z * 0.45), Vector3(0.1, s.y - 0.3 * z, 0.1))
	p.box(tin(), Vector3(0, s.y - 0.15, 0), Vector3(s.x + 0.4, 0.05, s.z + 0.5), 0.0, -0.12)
	p.box(tin(), Vector3(0, s.y * 0.45, s.z * 0.47), Vector3(s.x, s.y * 0.9, 0.04))
	p.box(wood(), Vector3(-s.x * 0.25, 0.3, s.z * 0.2), Vector3(0.7, 0.6, 0.6))
	p.box(wood(), Vector3(s.x * 0.2, 0.25, s.z * 0.25), Vector3(0.6, 0.5, 0.5), 0.3)


## Village lamp post: concrete pole, an arm, a tin shade (the bulb is the lighting's).
static func _lamp_post(p: Put) -> void:
	var h := p.size.y
	var concrete := BoxBatch3D.color("6f6d66")
	p.box(concrete, Vector3(0, h * 0.5, 0), Vector3(0.16, h, 0.16))
	p.box(concrete, Vector3(0, 0.3, 0), Vector3(0.26, 0.6, 0.26))
	p.box(BoxBatch3D.color("3a3a38"), Vector3(0, h - 0.15, -0.35), Vector3(0.05, 0.05, 0.75))
	p.box(BoxBatch3D.color("4b4f4a"), Vector3(0, h - 0.2, -0.7), Vector3(0.34, 0.08, 0.34))


## Low heaps: buoys (orange / white floats), nets (dark green), rubbish.
static func _heap(p: Put, id: String) -> void:
	var s := p.size
	var colors: Array[String] = ["b8622a", "cfc8b4", "8a3a24"]
	if id == "net_heap":
		colors = ["2f4a44", "3b5a50", "26403d"]
	elif id == "rubbish_heap":
		colors = ["2a2a2a", "4a4038", "5d6a70", "6b5a3a"]
	for i in 9:
		var a := TAU * float(i) * 0.37
		var r := 0.15 + 0.3 * float(i % 3) / 2.0
		var piece := Vector3(s.x * 0.35, s.y * 0.5, s.z * 0.35) * (1.0 - 0.15 * float(i % 3))
		p.box(BoxBatch3D.color(colors[i % colors.size()]), Vector3(sin(a) * r * s.x, piece.y * 0.5 + 0.15 * float(i % 2) * s.y, cos(a) * r * s.z), piece, a)


## Places local boxes into a batch around one origin and yaw.
class Put:
	var batch: BoxBatch3D
	var at: Vector3
	var yaw: float
	var size: Vector3

	func _init(b: BoxBatch3D, origin: Vector3, turn: float, extent: Vector3) -> void:
		batch = b
		at = origin
		yaw = turn
		size = extent

	## Local box: extra `turn` (Y), `tilt` (X) and `roll` (Z) after the yaw.
	func box(material: Material, local: Vector3, extent: Vector3, turn: float = 0.0, tilt: float = 0.0, roll: float = 0.0, lean: float = 0.0) -> void:
		var basis := Basis(Vector3.UP, yaw + turn) * Basis(Vector3.RIGHT, tilt + lean) * Basis(Vector3.BACK, roll)
		batch.add_box(material, Transform3D(basis, at + local.rotated(Vector3.UP, yaw)), extent)

	func gable(material: Material, local: Vector3, extent: Vector3, turn: float = 0.0) -> void:
		batch.gable(material, at + local.rotated(Vector3.UP, yaw), extent, yaw + turn)
