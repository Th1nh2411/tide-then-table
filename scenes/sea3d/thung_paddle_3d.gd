class_name ThungPaddle3D
extends RefCounted
## The thúng's paddle in Rin's hands: a slim round shaft with a grip knob and
## a thin tapered blade (rounded primitives, no boxes: from the first-person
## eye it passes close in front of the view). `pose` lays it through both
## hands at the "Row" clip's stroke phase. Local -Y runs from the top hand
## down to the blade; BLADE is the blade's middle (thung_rowing_test).

const LENGTH := 1.9
const BLADE := Vector3(0, -1.72, 0)
const WOOD := "6b4630"
const BLADE_WOOD := "7f5638"


## Builds the paddle under `rider` (its parent is named "Paddle":
## FirstPersonView3D keeps it in view while it hides Rin's body).
static func build(rider: Node3D) -> Node3D:
	var paddle := Node3D.new()
	paddle.name = "Paddle"
	rider.add_child(paddle)
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.016
	shaft.bottom_radius = 0.018
	shaft.height = LENGTH - 0.3
	shaft.radial_segments = 6
	shaft.rings = 1
	_part(paddle, shaft, Vector3(0, -0.72, 0), Vector3.ONE, WOOD)
	var knob := SphereMesh.new()
	knob.radius = 0.02
	knob.height = 0.04
	knob.radial_segments = 6
	knob.rings = 3
	_part(paddle, knob, Vector3(0, 0.09, 0), Vector3.ONE, WOOD)
	# Blade: a tapered cylinder pressed flat (wide at the tip, narrow at the neck).
	var blade := CylinderMesh.new()
	blade.top_radius = 0.035
	blade.bottom_radius = 0.085
	blade.height = 0.46
	blade.radial_segments = 8
	blade.rings = 1
	_part(paddle, blade, BLADE, Vector3(1.0, 1.0, 0.14), BLADE_WOOD)
	WorldPresentation3D.cast_shadows(paddle)
	return paddle


static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, scale_: Vector3, hex: String) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = SeaWorldBuilder3D.mat(hex)
	parent.add_child(node)
	node.position = pos
	node.scale = scale_


## Poses Rin's "Row" clip at the stroke phase and lays the paddle through his hands.
static func pose(sea: SeaScene3D) -> void:
	if sea.paddle == null or sea.rin_figure.is_empty():
		return
	var rider := sea.rin_figure[0] as RinPilotVisual
	if rider == null or not rider.animation or not rider.animation.has_animation("Row"):
		return
	rider.sample_motion("Row", sea.row.phase * rider.animation.get_animation("Row").length)
	var top := rider.hand_position("L")
	var down := (rider.hand_position("R") - top).normalized()
	var side := down.cross(Vector3.UP).normalized() if absf(down.y) < 0.99 else Vector3.RIGHT
	sea.paddle.transform = Transform3D(Basis(side, -down, side.cross(-down)), top)
