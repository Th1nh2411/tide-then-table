class_name VillageGateAlley3D
extends Node3D
## The dead-end alley off the lane (PLAN §10 "Ngõ cụt có cổng sắt"): ~10 m
## south from the middle of the lane between two walls, ending on an iron
## gate chained shut, fog behind the bars. On the last days (open_days,
## mùng 13-14) the chain hangs loose and one leaf stands ajar; LOOP_DEPTH
## metres into the fog Rin comes back out of the fog in front of the same
## gate, walking towards it (WorldEdgeLoop3D turns him round the corridor's
## middle, so the view never jumps). Rằm: shut again.

const NODE_NAME := "GateAlley"
## Inner faces of the two walls (x), the lane's south edge and the gate (z).
const X := Vector2(38.0, 40.4)
const MOUTH_Z := 6.2
const GATE_Z := 16.2
## How far the walled fog corridor runs on behind the gate.
const CORRIDOR := 32.0
const PILLAR := 0.5
## Pillar centres this far in from the walls.
const PILLAR_IN := 0.15
const LEAF_HEIGHT := 2.0

## GameState.day values the gate stands ajar (1 = mùng 9: 13-14 = 5-6).
@export var open_days: Array[int] = [5, 6]
@export var loop_depth := 20.0
## How far the loose leaf swings into the fog (degrees).
@export var ajar_deg := 75.0

var is_open := false
var leaf: Node3D
var _shut: Node3D


static func build(parent: Node3D) -> VillageGateAlley3D:
	var gate := VillageGateAlley3D.new()
	gate.name = NODE_NAME
	parent.add_child(gate)
	gate.set_open(GameState.day in gate.open_days)
	return gate


func _init() -> void:
	var brick := HorrorMaterials.tiled("brick_wall_old", 1.6)
	var damp := HorrorMaterials.tiled("brick_wall_old", 1.6, Color(0.72, 0.74, 0.72))
	var cap := HorrorMaterials.tiled("wall_plaster_old", 1.2, Color(0.66, 0.64, 0.58))
	var b := BoxBatch3D.new()
	# West: the house's side wall stands on the first metres, then brick.
	_wall(b, brick, cap, X.x - 0.125, 12.0, GATE_Z, 2.3)
	_wall(b, brick, cap, X.y + 0.125, MOUTH_Z, GATE_Z, 2.2)
	# Behind the gate the walls run on, damp and a little lower, into the fog.
	_wall(b, damp, cap, X.x - 0.125, GATE_Z, GATE_Z + CORRIDOR, 2.0)
	_wall(b, damp, cap, X.y + 0.125, GATE_Z, GATE_Z + CORRIDOR, 2.1)
	b.box(HorrorMaterials.tiled("lane_dirt", 2.0, Color(0.8, 0.78, 0.72)), Vector3((X.x + X.y) * 0.5, -0.07, GATE_Z + CORRIDOR * 0.5), Vector3(X.y - X.x, 0.1, CORRIDOR))
	for x: float in [X.x + PILLAR_IN, X.y - PILLAR_IN]:
		b.box(brick, Vector3(x, 1.35, GATE_Z), Vector3(PILLAR, 2.7, PILLAR))
		b.box(cap, Vector3(x, 2.75, GATE_Z), Vector3(PILLAR + 0.1, 0.1, PILLAR + 0.1))
	var inner := _leaf_span()
	var width := (inner.y - inner.x) * 0.5
	var iron := BoxBatch3D.color("2e2320")
	var rust := BoxBatch3D.color("5a3524")
	_leaf_bars(b, iron, rust, inner.x, width, GATE_Z)  # the west leaf never moves
	b.commit(self, "Alley")
	_solid(Vector3(X.x - 0.125, 1.2, (12.0 + GATE_Z + CORRIDOR) * 0.5), Vector3(0.25, 2.4, GATE_Z + CORRIDOR - 12.0))
	_solid(Vector3(X.y + 0.125, 1.2, (MOUTH_Z + GATE_Z + CORRIDOR) * 0.5), Vector3(0.25, 2.4, GATE_Z + CORRIDOR - MOUTH_Z))
	_solid(Vector3((X.x + X.y) * 0.5, 1.2, GATE_Z + CORRIDOR), Vector3(X.y - X.x, 2.4, 0.3))
	for x: float in [X.x + PILLAR_IN, X.y - PILLAR_IN]:
		_solid(Vector3(x, 1.35, GATE_Z), Vector3(PILLAR, 2.7, PILLAR))
	_solid(Vector3(inner.x + width * 0.5, 1.0, GATE_Z), Vector3(width, 2.0, 0.12))
	# The east leaf hangs on its hinge (turned when open).
	leaf = Node3D.new()
	leaf.name = "Leaf"
	add_child(leaf)
	leaf.position = Vector3(inner.y, 0, GATE_Z)
	var lb := BoxBatch3D.new()
	_leaf_bars(lb, iron, rust, -width, width, 0.0)
	lb.commit(leaf, "Bars")
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 2.0, 0.12)
	shape.shape = box
	shape.position = Vector3(-width * 0.5, 1.0, 0)
	body.add_child(shape)
	leaf.add_child(body)


## Shut (chained) or ajar.
func set_open(on: bool) -> void:
	is_open = on
	leaf.rotation.y = deg_to_rad(ajar_deg) if on else 0.0
	if is_instance_valid(_shut):
		_shut.queue_free()
	_shut = GateChain3D.build(self, Vector3(_leaf_span().x + (_leaf_span().y - _leaf_span().x) * 0.5, 0, GATE_Z), on)


## How deep (m) `p` is in the fog behind the gate; -1 when not there (or shut).
func depth_at(p: Vector3) -> float:
	if not is_open or p.x < X.x - 0.3 or p.x > X.y + 0.3 or p.z <= GATE_Z:
		return -1.0
	return p.z - GATE_Z


## Turned half round the corridor's middle at loop_depth: same depth from
## the far side, so he walks back out towards the gate.
func looped(p: Vector3) -> Vector3:
	var centre := Vector3((X.x + X.y) * 0.5, p.y, GATE_Z + loop_depth)
	return Vector3(2.0 * centre.x - p.x, p.y, 2.0 * centre.z - p.z)


## The gap between the pillars (x range) the two leaves fill.
func _leaf_span() -> Vector2:
	return Vector2(X.x + PILLAR_IN + PILLAR * 0.5, X.y - PILLAR_IN - PILLAR * 0.5)


## Brick wall along z at `x` with coping, a pier every 3 m.
func _wall(b: BoxBatch3D, brick: Material, cap: Material, x: float, z0: float, z1: float, h: float) -> void:
	b.box(brick, Vector3(x, h * 0.5, (z0 + z1) * 0.5), Vector3(0.25, h, z1 - z0))
	b.box(cap, Vector3(x, h + 0.05, (z0 + z1) * 0.5), Vector3(0.36, 0.1, z1 - z0))
	var z := z0 + 1.5
	while z < z1 - 0.5:
		b.box(brick, Vector3(x, h * 0.5 + 0.05, z), Vector3(0.38, h + 0.1, 0.34))
		z += 3.0


## One leaf from local x0, `width` wide: rails, bars with spikes, a few rusted.
func _leaf_bars(b: BoxBatch3D, iron: Material, rust: Material, x0: float, width: float, z: float) -> void:
	for y: float in [0.12, 1.0, 1.85]:
		b.box(iron, Vector3(x0 + width * 0.5, y, z), Vector3(width, 0.05, 0.05))
	for x: float in [x0 + 0.03, x0 + width - 0.03]:
		b.box(iron, Vector3(x, LEAF_HEIGHT * 0.5, z), Vector3(0.05, LEAF_HEIGHT, 0.05))
	var bars := int(width / 0.11)
	for i in range(1, bars):
		var x := x0 + width * float(i) / float(bars)
		b.box(rust if i % 3 == 1 else iron, Vector3(x, LEAF_HEIGHT * 0.5 + 0.06, z), Vector3(0.022, LEAF_HEIGHT + 0.12, 0.022))
		b.box(iron, Vector3(x, LEAF_HEIGHT + 0.14, z), Vector3(0.04, 0.06, 0.04), 0.0, PI * 0.25)


func _solid(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.position = at
