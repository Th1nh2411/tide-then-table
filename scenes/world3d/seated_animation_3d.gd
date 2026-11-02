class_name SeatedAnimation3D
extends RefCounted
## Runtime chair clips calibrated to each batch skeleton and the actual stool height.
## Source GLBs and native motion clips are never rewritten.
static var _cache: Dictionary = {}

static func prepare(visual: RinPilotVisual, seat_height: float) -> bool:
	var player := visual.animation
	if player.has_animation("SitDown") and player.has_animation("SitIdle") and player.has_animation("StandUp"): return true
	var sk := visual.skeleton
	if visual.bone("Thigh.L") < 0 or not player.has_animation("Idle"): return false
	# PSX models share one Idle clip but not their bone lengths: key by model too.
	var key := str(player.get_animation("Idle").get_instance_id())+":"+visual.model.scene_file_path+":"+str(seat_height)
	if not _cache.has(key):
		var previous := player.assigned_animation
		var time := player.current_animation_position if not previous.is_empty() else 0.0
		var playing := player.is_playing()
		player.play("Idle")
		player.seek(0,true)
		sk.force_update_all_bone_transforms()
		var idle: Array[Transform3D] = []
		for bone in sk.get_bone_count(): idle.append(sk.get_bone_pose(bone))
		var target := idle.duplicate()
		var hips := sk.find_bone("Hips")
		var hip := visual.to_local(sk.to_global(sk.get_bone_global_pose(hips).origin))
		var desired_hip := seat_height+.065*(hip.y/.92)
		var global_hip := sk.get_bone_global_pose(hips)
		var desired := visual.to_global(Vector3(hip.x,desired_hip,hip.z))
		global_hip.origin = sk.to_local(desired)
		var parent := sk.get_bone_parent(hips)
		target[hips].origin = sk.get_bone_global_pose(parent).affine_inverse()*global_hip.origin if parent >= 0 else global_hip.origin
		for side_: String in ["L","R"]:
			var thigh := visual.bone("Thigh."+side_)
			var shin := visual.bone("Shin."+side_)
			var foot := visual.bone("Foot."+side_)
			var angle := _fit_leg(visual,sk,[hips,thigh,shin,foot],idle,target[hips].origin)
			target[thigh].basis = idle[thigh].basis*_pitch(sk,thigh,-angle)
			target[shin].basis = idle[shin].basis*_pitch(sk,shin,angle)
			for part: String in ["UpperArm.","Forearm."]:
				var arm := visual.bone(part+side_)
				if arm >= 0: target[arm].basis = idle[arm].basis*_pitch(sk,arm,-.35 if part=="UpperArm." else -1.15)
		var clips: Dictionary = {}
		var root := player.get_node(player.root_node)
		var path := str(root.get_path_to(sk))
		clips["SitDown"] = _clip(path,sk,idle,target,.75,[0.0,.15,.55,.75],[0.0,.12,.88,1.0],false)
		clips["StandUp"] = _clip(path,sk,idle,target,.65,[0.0,.15,.5,.65],[1.0,.85,.08,0.0],false)
		clips["SitIdle"] = _clip(path,sk,idle,target,2.4,[0.0,1.2,2.4],[1.0,1.0,1.0],true)
		_cache[key] = clips
		if not previous.is_empty():
			player.play(previous)
			player.seek(time,true)
			if not playing: player.pause()
	for name_: String in ["SitDown","SitIdle","StandUp"]:
		if not player.has_animation(name_): player.get_animation_library("").add_animation(name_,_cache[key][name_])
	return true

## Knee bend that puts the seated foot back at its standing height (bisection:
## more bend lifts the foot). bones = [hips, thigh, shin, foot]; idle pose kept.
static func _fit_leg(visual: RinPilotVisual, sk: Skeleton3D, bones: Array, idle: Array[Transform3D], hips_at: Vector3) -> float:
	var hips: int = bones[0]; var thigh: int = bones[1]; var shin: int = bones[2]; var foot: int = bones[3]
	var ground := visual.to_local(sk.to_global(sk.get_bone_global_pose(foot).origin)).y
	var thigh_pitch := _pitch(sk,thigh,1.0)
	var shin_pitch := _pitch(sk,shin,1.0)
	var lo := 0.0
	var hi := 1.75
	for step in 16:
		var mid := (lo+hi)*.5
		sk.set_bone_pose_position(hips,hips_at)
		sk.set_bone_pose_rotation(thigh,(idle[thigh].basis*Basis(thigh_pitch.get_rotation_quaternion().get_axis(),-mid)).get_rotation_quaternion())
		sk.set_bone_pose_rotation(shin,(idle[shin].basis*Basis(shin_pitch.get_rotation_quaternion().get_axis(),mid)).get_rotation_quaternion())
		sk.force_update_all_bone_transforms()
		if visual.to_local(sk.to_global(sk.get_bone_global_pose(foot).origin)).y > ground: hi = mid
		else: lo = mid
	for bone: int in [hips,thigh,shin]:
		sk.set_bone_pose_position(bone,idle[bone].origin)
		sk.set_bone_pose_rotation(bone,idle[bone].basis.get_rotation_quaternion())
	sk.force_update_all_bone_transforms()
	return (lo+hi)*.5

## Rotation about the body's side axis (X), in the bone's own (idle) frame,
## so retargeted rigs whose bone axes differ bend the same way.
static func _pitch(sk: Skeleton3D, bone: int, angle: float) -> Basis:
	var axis := sk.get_bone_global_pose(bone).basis.orthonormalized().inverse()*Vector3.RIGHT
	return Basis(axis.normalized(),angle)

static func _clip(path: String, sk: Skeleton3D, idle: Array[Transform3D], target: Array[Transform3D], length_: float, times: Array, weights: Array, breathing: bool) -> Animation:
	var clip := Animation.new()
	clip.length = length_
	clip.loop_mode = Animation.LOOP_LINEAR if breathing else Animation.LOOP_NONE
	for bone in sk.get_bone_count():
		var node_path := NodePath(path+":"+sk.get_bone_name(bone))
		for type_: int in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:
			var track := clip.add_track(type_)
			clip.track_set_path(track,node_path)
			for i in times.size():
				var pose: Transform3D = idle[bone].interpolate_with(target[bone],float(weights[i]))
				if breathing and sk.get_bone_name(bone)=="Chest" and i==1: pose.basis *= Basis(Vector3.RIGHT,.012)
				# The mixer scales position tracks by motion_scale (retargeted rigs).
				var value: Variant = pose.origin/sk.motion_scale if type_==Animation.TYPE_POSITION_3D else pose.basis.get_rotation_quaternion() if type_==Animation.TYPE_ROTATION_3D else pose.basis.get_scale()
				clip.track_insert_key(track,float(times[i]),value)
	return clip
