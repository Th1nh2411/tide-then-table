class_name SeatedAnimation3D
extends RefCounted
## Runtime chair clips calibrated to each batch skeleton and the actual stool height.
## Source GLBs and native motion clips are never rewritten.
static var _cache: Dictionary = {}

static func prepare(visual: RinPilotVisual, seat_height: float) -> bool:
	var player := visual.animation
	if player.has_animation("SitDown") and player.has_animation("SitIdle") and player.has_animation("StandUp"): return true
	var sk := visual.skeleton
	if sk.find_bone("Thigh.L") < 0 or not player.has_animation("Idle"): return false
	var key := str(player.get_animation("Idle").get_instance_id())+":"+str(seat_height)
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
			var thigh := sk.find_bone("Thigh."+side_)
			var shin := sk.find_bone("Shin."+side_)
			var foot := sk.find_bone("Foot."+side_)
			var a := visual.to_local(sk.to_global(sk.get_bone_global_pose(thigh).origin))
			var b := visual.to_local(sk.to_global(sk.get_bone_global_pose(shin).origin))
			var c := visual.to_local(sk.to_global(sk.get_bone_global_pose(foot).origin))
			var angle := acos(clampf((desired_hip-(b.distance_to(c)+c.y))/maxf(a.distance_to(b),.001),-.3,.8))
			target[thigh].basis = idle[thigh].basis*Basis(Vector3.RIGHT,-angle)
			target[shin].basis = idle[shin].basis*Basis(Vector3.RIGHT,angle)
			for part: String in ["UpperArm.","Forearm."]:
				var arm := sk.find_bone(part+side_)
				if arm >= 0: target[arm].basis = idle[arm].basis*Basis(Vector3.RIGHT,-.35 if part=="UpperArm." else -1.15)
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
				var value: Variant = pose.origin if type_==Animation.TYPE_POSITION_3D else pose.basis.get_rotation_quaternion() if type_==Animation.TYPE_ROTATION_3D else pose.basis.get_scale()
				clip.track_insert_key(track,float(times[i]),value)
	return clip
