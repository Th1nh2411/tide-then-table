class_name UncannyHeadLook3D
extends SkeletonModifier3D
## Turns the neck + head towards a target after the animation, past what a
## shoulder allows (up to max_deg either side: the "keeps facing you" stare).
## Also jitters the head for glitch_face. Child of the Skeleton3D; fade it
## with `influence`. Humanoid-profile bone names (PSX rigs): Neck, Head.

## World point to face (set every frame by UncannyActor3D).
var target := Vector3.ZERO
var has_target := false
## Body forward in world space (the rig's +Z).
var body_forward := Vector3.BACK
var max_deg := 150.0
var max_pitch_deg := 35.0
## Share of the turn taken by the neck (the head takes the rest).
var neck_share := 0.4
## Head jitter amount in radians (glitch_face), 0 = still.
var jitter := 0.0
var _neck := -1
var _head := -1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_find_bones()


func _find_bones() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	_neck = skeleton.find_bone("Neck")
	_head = skeleton.find_bone("Head")


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _head < 0:
		_find_bones()
		if _head < 0:
			return
	var to_skel := skeleton.global_transform.affine_inverse()
	var head_pose := skeleton.get_bone_global_pose(_head)
	var up := (to_skel.basis * Vector3.UP).normalized()
	var yaw := 0.0
	var pitch := 0.0
	if has_target:
		var forward := (to_skel.basis * body_forward)
		forward = (forward - up * forward.dot(up)).normalized()
		var to := to_skel * target - head_pose.origin
		var flat := (to - up * to.dot(up))
		if flat.length() > 0.001 and forward.length() > 0.001:
			yaw = forward.signed_angle_to(flat.normalized(), up)
			yaw = clampf(yaw, -deg_to_rad(max_deg), deg_to_rad(max_deg))
			pitch = clampf(atan2(to.dot(up), flat.length()), -deg_to_rad(max_pitch_deg), deg_to_rad(max_pitch_deg))
	if jitter > 0.0:
		yaw += _rng.randf_range(-jitter, jitter)
		pitch += _rng.randf_range(-jitter, jitter) * 0.6
	if is_zero_approx(yaw) and is_zero_approx(pitch):
		return
	# Turn around the skeleton's up, then nod around the new facing's side.
	var looked := forward_after(up, yaw, to_skel)
	var side := up.cross(looked).normalized()
	var share := neck_share if _neck >= 0 else 0.0
	if _neck >= 0:
		_rotate_bone(skeleton, _neck, up, yaw * share, side, -pitch * share)
	_rotate_bone(skeleton, _head, up, yaw * (1.0 - share), side, -pitch * (1.0 - share))


func forward_after(up: Vector3, yaw: float, to_skel: Transform3D) -> Vector3:
	var forward := (to_skel.basis * body_forward)
	forward = (forward - up * forward.dot(up)).normalized()
	return forward.rotated(up, yaw)


func _rotate_bone(skeleton: Skeleton3D, bone: int, up: Vector3, yaw: float, side: Vector3, pitch: float) -> void:
	var pose := skeleton.get_bone_global_pose(bone)
	var turn := Basis(up, yaw)
	if side.length_squared() > 0.0001:
		turn = Basis(side, pitch) * turn
	pose.basis = turn * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
