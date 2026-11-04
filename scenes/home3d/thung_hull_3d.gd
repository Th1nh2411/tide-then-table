class_name ThungHull3D
extends RefCounted
## Ông Tư's thúng hull (sea boat, pier, rằm epilogue): the real model
## (assets/models/ready/thung_boat via ConceptModel3D) or, when it is missing,
## the old plain bowl (boat_pilot.tscn). Visual only; the boat controller,
## colliders and Rin stay with the caller. The root's origin is the hull's
## bottom, centred; `place()` puts the inner floor at a given height.

const ID := "thung_boat"
const PILOT := "res://scenes/art_pilots/boat_pilot.tscn"
## Model fitted to this diameter (m), then a little flatter: ~0.55 m from floor to rim,
## so the rim stays below Rin's view out to sea.
const DIAMETER := 2.3
const Y_SQUASH := 0.8
## thung_boat_reduced.glb: its woven floor sits this fraction of its height above its bottom
## (raycast on the mesh: bottom -0.37, floor -0.25, rim 0.37).
const FLOOR_FRACTION := 0.16
## The old bowl at y-scale 0.75: floor, rim and rim radius above / from its origin.
const PILOT_FLOOR := 0.06
const PILOT_RIM := 0.42
const PILOT_RADIUS := 1.17


static func real() -> bool:
	return VillageProps3D.kind(ID) == "concept"


## The hull under `parent`, its inner floor at `floor_y` (parent space).
static func place(parent: Node3D, floor_y: float, name_: String = "ThungHull") -> Node3D:
	var root: Node3D
	if real():
		root = Node3D.new()
		parent.add_child(root)
		ConceptModel3D.fit(root, ID, Vector3.ZERO, Vector3(DIAMETER, 4.0, DIAMETER)).scale.y = Y_SQUASH
	else:
		root = (load(PILOT) as PackedScene).instantiate() as Node3D
		parent.add_child(root)
		root.scale = Vector3(1, 0.75, 1)
	root.name = name_
	root.position.y = floor_y - floor_height()
	return root


## Height of the model fitted to DIAMETER.
static func _height() -> float:
	var dims: Array = ConceptModel3D.geometry(ID)["size"]
	return float(dims[1]) * DIAMETER / maxf(float(dims[0]), float(dims[2])) * Y_SQUASH


static func floor_height() -> float:
	return _height() * FLOOR_FRACTION if real() else PILOT_FLOOR


static func rim_height() -> float:
	return _height() if real() else PILOT_RIM


static func rim_radius() -> float:
	return DIAMETER * 0.5 - 0.1 if real() else PILOT_RADIUS


## A point on top of the rim in direction `toward` (x, z) from the hull's centre, parent space.
static func rim_point(hull: Node3D, toward: Vector2) -> Vector3:
	var d := toward.normalized() * rim_radius()
	return hull.position + Vector3(d.x, rim_height(), d.y)
