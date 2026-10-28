class_name RinPilotVisual
extends Node3D
## Actual Hunyuan shape with palette materials and weighted humanoid animation.

var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
var _motion: String = "Idle"
var _casting: bool = false

func _ready() -> void:
	model = load("res://assets/models/pilots/rin/rin_pilot.glb").instantiate()
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in animation.get_animation_list():
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play("Idle")
	animation.advance(0.0)

func set_motion(clip: String, speed: float = 1.0) -> void:
	if not animation:
		return
	_motion = clip
	if not _casting:
		if animation.current_animation != clip or not animation.is_playing():
			animation.play(clip, 0.12)
		animation.speed_scale = maxf(0.2, speed)

func sample_motion(clip: String, seconds: float) -> void:
	animation.play(clip)
	animation.seek(seconds, true)
	animation.pause()
	skeleton.force_update_all_bone_transforms()

func hand_position(tag: String) -> Vector3:
	var index := skeleton.find_bone("Hand." + tag)
	var transform := skeleton.get_bone_global_pose(index)
	return to_local(skeleton.to_global(transform.origin))

func set_cast_arm(index: int, angle: float) -> void:
	_casting = true
	animation.play("Idle")
	animation.seek(0.0, true)
	animation.pause()
	var tag := "R" if index == 0 else "L"
	var sign_ := -1.0 if index == 0 else 1.0
	var bone_index := skeleton.find_bone("UpperArm." + tag)
	var base := Quaternion(Vector3.BACK, -sign_ * 0.20)
	skeleton.set_bone_pose_rotation(bone_index, Quaternion(Vector3.RIGHT, angle) * base)
	skeleton.force_update_all_bone_transforms()

func clear_cast() -> void:
	if _casting:
		_casting = false
		animation.play(_motion, 0.12)
