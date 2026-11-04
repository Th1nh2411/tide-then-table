class_name ThungCharm3D
extends Node3D
## Anh Út's "bùa trừ ma da" (PLAN §10 "Ma da + chú Bảy"): a green cord tied
## round the rim of Rin's thúng. Story only. He gives it on mùng 10 (FLAG, a
## loop flag, so a reset to mùng 9 takes it away). Shown on the pier thúng
## and at sea once the flag is set; the bodies under the raft wear the same
## cord. Tiny procedural boxes, graded by StylePass like the rest.
## Local frame: origin on the rim top, +X pointing out of the hull.

const FLAG := "ut_charm"
const GREEN := "3d7f4c"
const KNOT := "2c6139"
const W := 0.022

## False: always shown (the endings).
var follow := true


static func tie(parent: Node3D, at: Vector3, out_yaw: float, follow_flag: bool = true) -> ThungCharm3D:
	var charm := ThungCharm3D.new()
	charm.name = "ThungCharm"
	charm.follow = follow_flag
	parent.add_child(charm)
	charm.position = at
	charm.rotation.y = out_yaw
	return charm


static func given() -> bool:
	return GameState.has_flag(FLAG)


func _ready() -> void:
	# The wrap over the rim (outside, top, inside), the knot, two loose tails.
	_box(Vector3(0.03, -0.05, 0), Vector3(W, 0.11, W * 1.6))
	_box(Vector3(0.0, 0.006, 0), Vector3(0.075, W, W * 1.6))
	_box(Vector3(-0.03, -0.04, 0), Vector3(W, 0.09, W * 1.6))
	_box(Vector3(0.05, -0.1, 0), Vector3(0.04, 0.035, 0.04), KNOT)
	var tail := _box(Vector3(0.07, -0.19, 0.02), Vector3(W, 0.16, W))
	tail.rotation.z = 0.25
	var tail2 := _box(Vector3(0.06, -0.17, -0.025), Vector3(W, 0.12, W))
	tail2.rotation.z = 0.12
	tail2.rotation.x = 0.3
	visible = given() or not follow


func _process(_delta: float) -> void:
	if follow:
		visible = given()


func _box(pos: Vector3, size: Vector3, hex: String = GREEN) -> MeshInstance3D:
	return OmenProps3D.box(self, pos, size, hex)
