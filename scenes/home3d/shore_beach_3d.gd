class_name ShoreBeach3D
extends RefCounted
## Sloped beaches into the bay (WaterfrontBuilder3D local space). The
## waterfront's: flat dry sand from about DRY_Z (an uneven edge lying just
## over the village ground) to TOP_Z (the old hard shore line), then a slope
## of uneven width down under the water and a steeper skirt beyond, so the
## water plane cuts it along a wavy waterline. headland() gives a block of
## land the same slope on its two sea sides, round its corner. One mesh, wet
## darker sand near the water (vertex colours on sand_packed), one trimesh
## collider. height_at() is the waterfront's surface: VillageScene3D keeps
## Rin's feet on it.

const DRY_Z := 5.0
const TOP_Z := 2.0
## Slope width (metres seaward) before the wobble, and the height it loses.
const WIDTH := 4.6
const DROP := 1.0
## Past the slope: a steeper skirt `x` metres long down to `y`.
const SKIRT := Vector2(3.0, -2.4)
## East of the waterfront the land sits a little lower (VillageBackdrop3D).
const LOW_TOP := -0.08
const ROWS := 8
const STEP := 1.0
const FAN_STEPS := 6
## Vertex colours: dry, wet (at the waterline), under water.
const DRY := Color(0.86, 0.82, 0.74)
const WET := Color(0.5, 0.45, 0.4)
const SUNK := Color(0.4, 0.42, 0.42)

static var _material: StandardMaterial3D
var _st := SurfaceTool.new()


func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


## The waterfront's beach from x `x0` to `x1`; east of `low_from` its top is LOW_TOP.
func waterfront(x0: float, x1: float, low_from: float = INF) -> void:
	var cols: Array = []
	var x := x0
	while true:
		var band := DRY_Z - TOP_Z + 0.6 + 0.6 * sin(x * 0.53 + 0.7) * sin(x * 0.19)
		cols.append(_column(Vector3(x, _top(x, low_from), TOP_Z), Vector3.FORWARD, slope_width(x), band))
		if x >= x1:
			break
		x = minf(x + STEP, x1)
	_join(cols)


## A block of land (x / z rect, top at `top`) whose east (+X) and north (-Z)
## sides face the sea: a slope along each, a fan round the corner between.
func headland(land: Rect2, top: float) -> void:
	var corner := Vector3(land.end.x, top, land.position.y)
	var east: Array = []
	var z := land.end.y
	while z > corner.z:
		east.append(_column(Vector3(corner.x, top, z), Vector3.RIGHT, _width_at(corner.x, z), 0.0))
		z -= STEP
	east.append(_column(corner, Vector3.RIGHT, _width_at(corner.x, corner.z), 0.0))
	_join(east)
	var fan: Array = []
	for i in FAN_STEPS + 1:
		var dir := Vector3.RIGHT.rotated(Vector3.UP, PI * 0.5 * float(i) / float(FAN_STEPS))
		fan.append(_column(corner, dir, _width_at(corner.x, corner.z), 0.0))
	_join(fan)
	var north: Array = []
	var x := corner.x
	while x > land.position.x:
		north.append(_column(Vector3(x, top, corner.z), Vector3.FORWARD, _width_at(x, corner.z), 0.0))
		x -= STEP
	north.append(_column(Vector3(land.position.x, top, corner.z), Vector3.FORWARD, _width_at(land.position.x, corner.z), 0.0))
	_join(north)


## Adds the mesh ("Beach") and its collider ("BeachGround") to `host`.
func commit(host: Node3D) -> MeshInstance3D:
	_st.index()
	_st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "Beach"
	mesh.mesh = _st.commit()
	mesh.material_override = material()
	host.add_child(mesh)
	var body := StaticBody3D.new()
	body.name = "BeachGround"
	host.add_child(body)
	var shape := CollisionShape3D.new()
	shape.shape = mesh.mesh.create_trimesh_shape()
	body.add_child(shape)
	return mesh


## Waterfront sand height at local (x, z).
static func height_at(x: float, z: float, low_from: float = INF) -> float:
	var top := _top(x, low_from)
	return top if z >= TOP_Z else _profile(TOP_Z - z, slope_width(x), top)


## Where the waterfront's slope reaches `y` at x (local z), e.g. the waterline.
static func z_at_height(x: float, y: float, low_from: float = INF) -> float:
	var t := pow(clampf((_top(x, low_from) - y) / DROP, 0.0, 1.0), 1.0 / 1.3)
	return TOP_Z - t * slope_width(x)


## Slope width at coast position s: an uneven, repeatable wobble (no random state).
static func slope_width(s: float) -> float:
	return WIDTH + 0.45 * sin(s * 0.37) + 0.3 * sin(s * 0.91 + 1.3) + 0.15 * sin(s * 2.3 + 0.4)


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = HorrorMaterials.tiled("sand_packed", 2.5).duplicate() as StandardMaterial3D
		_material.vertex_color_use_as_albedo = true
	return _material


## Height `d` metres seaward of the coast.
static func _profile(d: float, width: float, top: float) -> float:
	var t := d / width
	if t <= 1.0:
		return top - DROP * pow(t, 1.3)
	return lerpf(top - DROP, SKIRT.y, clampf((d - width) / SKIRT.x, 0.0, 1.0))


## Same wobble along every coast (it meets the waterfront's at its west end).
static func _width_at(x: float, z: float) -> float:
	return slope_width(x - z + TOP_Z)


static func _top(x: float, low_from: float) -> float:
	return lerpf(0.0, LOW_TOP, clampf(x - low_from, 0.0, 1.0))


## One cross-section: optional dry band inland (`band` metres, a hair above
## the ground it lies on), slope rows, skirt end.
static func _column(coast: Vector3, sea: Vector3, width: float, band: float) -> Array[Vector3]:
	var rows: Array[Vector3] = []
	if band > 0.0:
		rows.append(coast - sea * band + Vector3(0, 0.015, 0))
	for i in ROWS + 1:
		var d := width * float(i) / float(ROWS)
		var p := coast + sea * d
		p.y = _profile(d, width, coast.y)
		rows.append(p)
	var end := coast + sea * (width + SKIRT.x)
	end.y = SKIRT.y
	rows.append(end)
	return rows


## Quads between neighbouring columns, every triangle facing up.
func _join(cols: Array) -> void:
	for c in cols.size() - 1:
		var a: Array[Vector3] = cols[c]
		var b: Array[Vector3] = cols[c + 1]
		for r in a.size() - 1:
			_tri(a[r], a[r + 1], b[r])
			_tri(b[r], a[r + 1], b[r + 1])


func _tri(p: Vector3, q: Vector3, r: Vector3) -> void:
	var n := (q - p).cross(r - p)
	if n.length_squared() < 0.000001:
		return  # the fan's apex
	if n.y > 0.0:  # Godot's front faces wind clockwise
		var swap := q
		q = r
		r = swap
	for v: Vector3 in [p, q, r]:
		_st.set_color(_colour(v.y))
		_st.add_vertex(v)


static func _colour(y: float) -> Color:
	var water := WaterfrontBuilder3D.WATER_Y
	var wet := smoothstep(water + 0.3, water + 0.05, y)
	var sunk := smoothstep(water - 0.05, water - 0.5, y)
	return DRY.lerp(WET, wet).lerp(SUNK, sunk)
