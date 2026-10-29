class_name GroundFootPlant3D
extends RefCounted
## Two-bone support-leg IK after animation. Contact anchors stay in world space.
## The restaurant/story ground is flat at the actor origin; authored swing/toe roll stays intact.
var visual: RinPilotVisual
var skeleton: Skeleton3D
var legs: Array[Dictionary] = []

func _init(owner: RinPilotVisual) -> void:
	visual = owner
	skeleton = visual.skeleton
	for side: String in ["L","R"]:
		var upper := skeleton.find_bone("UpperLeg."+side)
		var lower := skeleton.find_bone("LowerLeg."+side)
		if upper < 0: upper = skeleton.find_bone("Thigh."+side)
		if lower < 0: lower = skeleton.find_bone("Shin."+side)
		var foot := skeleton.find_bone("Foot."+side)
		if upper < 0 or lower < 0 or foot < 0: continue
		var local := visual.to_local(skeleton.to_global(skeleton.get_bone_global_pose(foot).origin))
		legs.append({"upper":upper,"lower":lower,"foot":foot,"name":"Foot."+side,"height":local.y,"planted":false,"anchor":Vector3.ZERO})

func release() -> void:
	for leg in legs: leg["planted"] = false

func apply(clip: String, moving: bool, _delta: float) -> void:
	if not moving:
		release()
		return
	for leg in legs:
		var original := skeleton.get_bone_global_pose(int(leg["foot"]))
		var world := skeleton.to_global(original.origin)
		var local := visual.to_local(world)
		leg["source_height"] = local.y
		var heights := GroundGait3D.foot_heights(visual,clip,leg["name"])
		var lift := maxf(heights.y-heights.x,.001)
		var threshold := heights.x+minf(lift*.2,.04)
		if local.y > threshold:
			leg["planted"] = false
			continue
		if not leg["planted"]:
			leg["planted"] = true
			leg["anchor"] = Vector3(world.x,visual.to_global(Vector3(0,leg["height"],0)).y,world.z)
		var anchor: Vector3 = leg["anchor"]
		# Teleports/dashes/sharp redirections must never stretch a locked leg indefinitely.
		if world.distance_to(anchor) > .24*visual.global_basis.get_scale().x:
			leg["planted"] = false
			continue
		var weight := smoothstep(0.0,1.0,clampf((threshold-local.y)/minf(lift*.1,.02),0.0,1.0))
		_solve(leg,skeleton.to_local(world.lerp(anchor,weight)),original.basis)

func _rotate_global(bone: int, basis: Basis) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	# Bone pose rotations are parent-local, already including the imported rest rotation.
	var pose := parent_basis.inverse()*basis
	skeleton.set_bone_pose_rotation(bone,pose.orthonormalized().get_rotation_quaternion().normalized())
	skeleton.force_update_all_bone_transforms()

func _solve(leg: Dictionary, target: Vector3, foot_basis: Basis) -> void:
	var upper: int = leg["upper"]; var lower: int = leg["lower"]; var foot: int = leg["foot"]
	var hip_pose := skeleton.get_bone_global_pose(upper)
	var knee := skeleton.get_bone_global_pose(lower).origin
	var ankle := skeleton.get_bone_global_pose(foot).origin
	var hip := hip_pose.origin
	var thigh := hip.distance_to(knee)
	var shin := knee.distance_to(ankle)
	var offset := target-hip
	if minf(thigh,shin) < .00001 or offset.length() < .00001: return
	var reach := clampf(offset.length(),absf(thigh-shin)+.000001,(thigh+shin)*.999)
	var direction := offset.normalized()
	var pole := knee-hip-direction*(knee-hip).dot(direction)
	if pole.length_squared() < .0000000001: return
	pole = pole.normalized()
	var along := (thigh*thigh-shin*shin+reach*reach)/(2.0*reach)
	var bend := sqrt(maxf(0.0,thigh*thigh-along*along))
	var desired_knee := hip+direction*along+pole*bend
	var desired_ankle := hip+direction*reach
	var original_shin := ankle-knee
	# Rin/pilot2 has root-level foot controls; batch feet are children of the shin.
	var independent_foot := skeleton.get_bone_parent(foot) != lower
	var rotation := Quaternion((knee-hip).normalized(),(desired_knee-hip).normalized())
	_rotate_global(upper,Basis(rotation)*hip_pose.basis)
	var knee_pose := skeleton.get_bone_global_pose(lower)
	var shin_direction := Basis(rotation)*original_shin if independent_foot else skeleton.get_bone_global_pose(foot).origin-knee_pose.origin
	rotation = Quaternion(shin_direction.normalized(),(desired_ankle-knee_pose.origin).normalized())
	_rotate_global(lower,Basis(rotation)*knee_pose.basis)
	_rotate_global(foot,foot_basis)
	if independent_foot:
		var parent_pose := skeleton.get_bone_global_pose(skeleton.get_bone_parent(foot))
		skeleton.set_bone_pose_position(foot,parent_pose.affine_inverse()*desired_ankle)
		skeleton.force_update_all_bone_transforms()
