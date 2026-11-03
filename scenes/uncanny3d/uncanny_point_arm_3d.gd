class_name UncannyPointArm3D
extends SkeletonModifier3D
## Raises the right arm straight towards a world direction (ông Tư pointing
## at the raft). Child of the Skeleton3D; humanoid-profile bone names.

var direction := Vector3.FORWARD
var _upper := -1
var _lower := -1
var _hand := -1


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _upper < 0:
		_upper = skeleton.find_bone("RightUpperArm")
		_lower = skeleton.find_bone("RightLowerArm")
		_hand = skeleton.find_bone("RightHand")
		if _upper < 0 or _lower < 0 or _hand < 0:
			return
	var want := (skeleton.global_transform.basis.inverse() * direction).normalized()
	_align(skeleton, _upper, _lower, want)
	_align(skeleton, _lower, _hand, want)


## Rotates `bone` so its child sits along `want` (skeleton space).
func _align(skeleton: Skeleton3D, bone: int, child: int, want: Vector3) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	var now := (skeleton.get_bone_global_pose(child).origin - pose.origin)
	if now.length() < 0.0001:
		return
	var turn := Quaternion(now.normalized(), want)
	pose.basis = Basis(turn) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
