class_name StreetLife3D
extends RefCounted
## The far side of the road and the street's small life (village map): a row
## of tube houses with a few small shops (invented names only), parked
## motorbikes, stacked stools, puddles, power poles with sagging wires, and
## planter trees along the west pavement.

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")
const FRONT_Z := 18.1
## House index -> shop sign (invented names; never real places or brands).
const SHOPS := {1: "TẠP HOÁ BA LƯỢM", 3: "SỬA XE ÚT ĐÈN", 6: "CẮT TÓC ANH HAI", 9: "CÀ PHÊ GIÓ BẤC",
	12: "NƯỚC MẮM BÀ TƯ", 15: "TIỆM MAY CÔ BẢY"}


static func build(host: Node3D) -> void:
	var day := BoxBatch3D.new()
	var night := BoxBatch3D.new()
	var props := BoxBatch3D.new()
	var spans := spans_x(StreetFacades3D.BEND_X.x - 1.0, StreetFacades3D.JUNCTION_X, 2)
	for i in spans.size():
		var span: Vector3 = spans[i]
		var shop := SHOPS.has(i)
		TubeHouse3D.build(host, day, night, Vector3(span.x, 0, FRONT_Z), Vector3(span.y, span.z, StreetFacades3D.DEPTH), PI, i + 2, shop)
		if shop:
			_sign(host, str(SHOPS[i]), Vector3(span.x, 3.0, FRONT_Z - 0.12), span.y)
			_stools(host, Vector3(span.x + span.y * 0.3, 0, FRONT_Z - 0.6))
		if i % 4 == 2:
			VillageProps3D.place(host, _bike_id(), Vector3(span.x - 1.0, 0, FRONT_Z - 0.9), Vector3(0.7, 1.1, 1.8), PI * 0.5 + 0.2, props)
	B().solid_block(host, Vector3(-26.0, 3.0, FRONT_Z + 1.0), Vector3(100.0, 6.0, 2.0))
	_puddles(props)
	_poles(host, props)
	# West pavement: planter trees and a parked bike by the curb.
	for x: float in [-31.0, -43.0]:
		VillageProps3D.place(host, "planter_tree_street", Vector3(x, 0, L.CURB_PROP_Z), Vector3(2.4, 4.2, 2.4), 0.0, props)
		B().solid_block(host, Vector3(x, 0.4, L.CURB_PROP_Z), Vector3(1.0, 0.8, 1.0))
	VillageProps3D.place(host, _bike_id(), Vector3(-36.5, 0, 7.0), Vector3(0.7, 1.1, 1.8), PI * 0.5 - 0.15, props)
	B().solid_block(host, Vector3(-36.5, 0.5, 7.0), Vector3(1.8, 1.0, 0.7))
	day.commit(host, "OppositeRow")
	night.commit(host, "OppositeRowGlow", false).add_to_group(StreetFacades3D.GLOW)
	props.commit(host, "StreetLife")


static func B() -> GDScript:
	return preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")


## The Cub when delivered, else the guests' motorbike, else the stand-in.
static func _bike_id() -> String:
	if VillageProps3D.kind("motorbike_cub") != "":
		return "motorbike_cub"
	return "motorbike" if VillageProps3D.kind("motorbike") != "" else "motorbike_cub"


## House spans from x0 down to x1: Vector3(centre x, width, height).
static func spans_x(x0: float, x1: float, seed_: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var x := x0
	var i := seed_
	while x > x1 + 1.0:
		var w := minf(4.2 + float((i * 5) % 4) * 0.8, x - x1)
		out.append(Vector3(x - w * 0.5, w, 4.6 + float((i * 7) % 5) * 1.2))
		x -= w
		i += 1
	return out


static func _sign(host: Node3D, words: String, at: Vector3, width: float) -> void:
	var board := B().box(host, at, Vector3(minf(width * 0.85, 4.2), 0.55, 0.06), "6a2f2a") as MeshInstance3D
	board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var text := B().label(host, words, at + Vector3(0, 0, -0.04), 30, "e9d9a8") as Label3D
	text.rotation.y = PI
	text.pixel_size = 0.0045


## Plastic stools stacked by a shop front.
static func _stools(host: Node3D, at: Vector3) -> void:
	var scene := load("res://assets/models/ready/stool/stool.glb") as PackedScene
	for i in 3:
		var stool := VillageProps3D.fit_scene(host, scene, at + Vector3(0, 0.16 * float(i), 0), Vector3(0.45, 0.45, 0.45), 0.2 * float(i))
		stool.name = "StackedStool_%d" % i


## Dark puddles on the road and pavement (rain earlier in the day).
static func _puddles(b: BoxBatch3D) -> void:
	var water := BoxBatch3D.color("161c22")
	var spots := [Vector3(-12.0, 0, 15.2), Vector3(5.0, 0, 9.6), Vector3(-34.0, 0, 12.0), Vector3(14.0, 0, 16.0), Vector3(-52.0, 0, 10.5)]
	for i in spots.size():
		var p: Vector3 = spots[i]
		b.box(water, p + Vector3(0, -0.085, 0), Vector3(1.6 + 0.5 * float(i % 2), 0.02, 0.9 + 0.3 * float(i % 3)), 0.5 * float(i))


## Power poles along the far pavement with wires sagging between them.
static func _poles(host: Node3D, b: BoxBatch3D) -> void:
	var xs: Array[float] = [-62.0, -44.0, -26.0, -8.0, 10.0]
	var top := 6.4
	for x in xs:
		ConceptModel3D.spawn(host, "power_pole", Vector3(x, 0, FRONT_Z - 1.4), 6.8)
	for i in xs.size() - 1:
		for dz: float in [-0.3, 0.3]:
			wire(b, Vector3(xs[i], top, FRONT_Z - 1.4 + dz), Vector3(xs[i + 1], top, FRONT_Z - 1.4 + dz), 0.8)
	# Across the road to the shop row.
	wire(b, Vector3(-8.0, top, FRONT_Z - 1.4), Vector3(-6.0, 6.0, L.BACK_Z - 0.1), 1.0)
	wire(b, Vector3(10.0, top, FRONT_Z - 1.4), Vector3(12.0, 5.6, L.BACK_Z - 0.1), 1.0)


## A wire from a to b sagging `sag` metres, in three straight pieces.
static func wire(b: BoxBatch3D, a: Vector3, c: Vector3, sag: float) -> void:
	var black := BoxBatch3D.color("141414")
	var points: Array[Vector3] = [a, a.lerp(c, 0.33) - Vector3(0, sag * 0.85, 0), a.lerp(c, 0.66) - Vector3(0, sag * 0.85, 0), c]
	for i in 3:
		var p: Vector3 = points[i]
		var q: Vector3 = points[i + 1]
		var dir := q - p
		var basis := Basis.looking_at(dir.normalized(), Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.RIGHT)
		b.add_box(black, Transform3D(basis, (p + q) * 0.5), Vector3(0.03, 0.03, dir.length()))
