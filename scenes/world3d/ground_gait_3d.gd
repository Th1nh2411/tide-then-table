class_name GroundGait3D
extends RefCounted
## Runtime gait data shared by identical character instances. Never edits source clips.
static var _speeds: Dictionary = {}
static var _carry_walks: Dictionary = {}
static var _heights: Dictionary = {}

static func carry_walk(player: AnimationPlayer) -> String:
	if not player.has_animation("Carry") or not player.has_animation("Walk"):
		return "Walk"
	var name_ := "GroundCarryWalk"
	if player.has_animation(name_): return name_
	var walk := player.get_animation("Walk")
	var carry := player.get_animation("Carry")
	var key := str(walk.get_instance_id()) + ":" + str(carry.get_instance_id())
	if not _carry_walks.has(key):
		var combined := walk.duplicate(true) as Animation
		for track in range(combined.get_track_count()-1,-1,-1):
			if _arm_track(combined.track_get_path(track)): combined.remove_track(track)
		for track in carry.get_track_count():
			if not _arm_track(carry.track_get_path(track)): continue
			carry.copy_track(track,combined)
			var added := combined.get_track_count()-1
			for frame in combined.track_get_key_count(added):
				combined.track_set_key_time(added,frame,combined.track_get_key_time(added,frame)*walk.length/maxf(carry.length,.001))
		combined.loop_mode = Animation.LOOP_LINEAR
		_carry_walks[key] = combined
	player.get_animation_library("").add_animation(name_,_carry_walks[key])
	return name_

static func _arm_track(path: NodePath) -> bool:
	if path.get_subname_count() == 0: return false
	var bone := String(path.get_subname(0))
	# Humanoid-profile rigs (PSX NPCs): LeftShoulder / LeftUpperArm / LeftLowerArm / LeftHand.
	if (bone.begins_with("Left") or bone.begins_with("Right")) and not ("Leg" in bone or "Foot" in bone or "Toes" in bone):
		return true
	return bone.begins_with("Clavicle.") or bone.begins_with("Shoulder.") or bone.begins_with("UpperArm.") or bone.begins_with("Forearm.") or bone.begins_with("LowerArm.") or bone.begins_with("Hand.") or bone.begins_with("Wrist.") or bone.begins_with("Fingers.") or bone.begins_with("Thumb.")

## Ground speed of the backward-moving support foot, measured in the visual's metres.
static func speed(visual: RinPilotVisual, clip: String) -> float:
	var animation := visual.animation.get_animation(clip)
	var key := _key(visual,animation)
	if _speeds.has(key): return _speeds[key]
	var player := visual.animation
	var previous := player.assigned_animation
	var time := player.current_animation_position if not previous.is_empty() else 0.0
	var playing := player.is_playing()
	var samples := 48
	var velocities: Array[float] = []
	var extent := 0.0
	var heights: Dictionary = {}
	for foot: String in ["Foot.L","Foot.R"]:
		var bone := visual.bone(foot)
		if bone < 0: continue
		var points: Array[Vector3] = []
		var low := Vector3(INF,INF,INF)
		var high := -low
		for i in samples+1:
			player.play(clip)
			player.seek(animation.length*float(i)/float(samples),true)
			visual.skeleton.force_update_all_bone_transforms()
			var p := visual.to_local(visual.skeleton.to_global(visual.skeleton.get_bone_global_pose(bone).origin))
			points.append(p)
			low = low.min(p); high = high.max(p)
		heights[foot] = Vector2(low.y,high.y)
		extent = maxf(extent,high.z-low.z)
		var contact_height := low.y + minf((high.y-low.y)*.2,.04)
		for i in samples:
			var a := points[i]; var b := points[i+1]
			var backward := (a.z-b.z)*float(samples)/animation.length
			if maxf(a.y,b.y) <= contact_height and backward > .05:
				velocities.append(backward)
	var result := extent*2.0/maxf(animation.length,.001)
	if not velocities.is_empty():
		velocities.sort()
		result = velocities[velocities.size()/2]
	result = clampf(result,.35,5.0)
	_speeds[key] = result
	_heights[key] = heights
	if not previous.is_empty():
		player.play(previous)
		player.seek(time,true)
		if not playing: player.pause()
	return result

static func foot_heights(visual: RinPilotVisual, clip: String, foot: String) -> Vector2:
	speed(visual,clip)
	return _heights.get(_key(visual,visual.animation.get_animation(clip)),{}).get(foot,Vector2.ZERO)

## Clips are shared between PSX models of different sizes: measure per model.
static func _key(visual: RinPilotVisual, animation: Animation) -> String:
	return str(animation.get_instance_id()) + ":" + visual.model.scene_file_path
