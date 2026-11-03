class_name UncannyPoseHold3D
extends SkeletonModifier3D
## Holds the skeleton's pose after the animation (and the head look):
## FREEZE keeps one pose (no breathing, the smile held too long); CHOPPY
## re-takes the pose only `fps` times a second, so a 60 fps world shows a
## person moving at 6-8 fps. OFF lets everything through.

enum Mode { OFF, FREEZE, CHOPPY }

var mode := Mode.OFF
var fps := 7.0
var _held: Array[Transform3D] = []
var _since := 0.0
var _last_ms := 0


func freeze() -> void:
	mode = Mode.FREEZE
	_held.clear()


func choppy(frames_per_second: float) -> void:
	mode = Mode.CHOPPY
	fps = maxf(frames_per_second, 1.0)
	_held.clear()
	_since = 0.0


func release() -> void:
	mode = Mode.OFF
	_held.clear()


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null or mode == Mode.OFF:
		return
	var now := Time.get_ticks_msec()
	var delta := clampf(float(now - _last_ms) / 1000.0, 0.0, 0.1) if _last_ms > 0 else 0.0
	_last_ms = now
	if _held.size() != skeleton.get_bone_count():
		_capture(skeleton)
		return
	if mode == Mode.CHOPPY:
		_since += delta
		if _since >= 1.0 / fps:
			_since = fmod(_since, 1.0 / fps)
			_capture(skeleton)
			return
	for bone in _held.size():
		skeleton.set_bone_pose(bone, _held[bone])


func _capture(skeleton: Skeleton3D) -> void:
	_held.clear()
	for bone in skeleton.get_bone_count():
		_held.append(skeleton.get_bone_pose(bone))
