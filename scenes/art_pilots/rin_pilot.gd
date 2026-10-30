class_name RinPilotVisual
extends Node3D
## Actual Hunyuan shape with palette materials and weighted humanoid animation.

var model: Node3D
var skeleton: Skeleton3D
var animation: AnimationPlayer
## Clips that end on their last pose instead of looping.
const ONE_SHOT := ["Cast", "Faint", "CharacterArmature|Death"]

var _motion: String = "Idle"
var _casting: bool = false
var _foot_plant: GroundFootPlant3D
var _idle_hand: Dictionary = {}  # tag -> hand basis in the Idle pose (hanging arm)

func _ready() -> void:
	model = load("res://assets/models/ready/rin/rin_pilot.glb").instantiate()
	add_child(model)
	WorldPresentation3D.cast_shadows(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	# Pilot2 keeps its native animation names and motion; aliases retain the actor API.
	for clip: String in ["Idle", "Walk"]:
		var native := "CharacterArmature|" + clip
		if not animation.has_animation(clip) and animation.has_animation(native):
			animation.get_animation_library("").add_animation(clip, animation.get_animation(native).duplicate())
	for clip: String in animation.get_animation_list():
		animation.get_animation(clip).loop_mode = Animation.LOOP_NONE if clip in ONE_SHOT else Animation.LOOP_LINEAR
	animation.play("Idle")
	animation.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	_foot_plant = GroundFootPlant3D.new(self)
	for tag: String in ["L", "R"]:
		_idle_hand[tag] = (global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(_hand_bone(tag))).basis.orthonormalized()

func set_motion(clip: String, speed: float = 1.0) -> void:
	if not animation:
		return
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	if _foot_plant: _foot_plant.release()
	_motion = clip
	if not _casting:
		if animation.current_animation != clip or not animation.is_playing():
			animation.play(clip, 0.12)
		animation.speed_scale = maxf(0.2, speed)

## Advance walking by actual ground distance, not input or an unrelated wall clock.
func drive_ground_motion(distance: float, delta: float, carrying: bool) -> void:
	if not animation or _casting or delta <= 0.0: return
	if _foot_plant == null: _foot_plant = GroundFootPlant3D.new(self)
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation.speed_scale = 1.0
	var moving := distance / delta > 0.04
	var clip := "Carry" if carrying else "Idle"
	var native_speed := 1.0
	if moving:
		clip = "Walk"
		if carrying:
			clip = "CarryWalk" if not self is BatchCharacterVisual and animation.has_animation("CarryWalk") else GroundGait3D.carry_walk(animation)
		elif not self is BatchCharacterVisual and distance/delta > 2.25 and animation.has_animation("CharacterArmature|Run"):
			clip = "CharacterArmature|Run"
		native_speed = GroundGait3D.speed(self,clip)
	var old_clip := animation.current_animation
	var phase := animation.current_animation_position / maxf(animation.get_animation(old_clip).length,.001) if not old_clip.is_empty() else 0.0
	if old_clip != clip or not animation.is_playing():
		animation.play(clip,.12)
		if moving and (old_clip in ["Walk","CarryWalk","GroundCarryWalk","CharacterArmature|Run"]):
			animation.seek(phase*animation.get_animation(clip).length,false)
	_motion = clip
	animation.advance(distance/native_speed if moving else delta)
	skeleton.force_update_all_bone_transforms()
	_foot_plant.apply(clip,moving,delta)

func sample_motion(clip: String, seconds: float) -> void:
	animation.play(clip)
	animation.seek(seconds, true)
	animation.pause()
	skeleton.force_update_all_bone_transforms()

func hand_position(tag: String) -> Vector3:
	var index := _hand_bone(tag)
	var transform := skeleton.get_bone_global_pose(index)
	return to_local(skeleton.to_global(transform.origin))

func hand_basis(tag: String) -> Basis:
	var index := _hand_bone(tag)
	var basis := (global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(index)).basis.orthonormalized()
	if skeleton.find_bone("Wrist." + tag) < 0:
		return basis
	# Rotation since the Idle pose (the node rest pose is a T-pose, not usable as reference).
	var ref: Basis = _idle_hand.get(tag, hand_rest_basis(tag))
	return basis * ref.inverse()

func hand_rest_basis(tag: String) -> Basis:
	return (global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_rest(_hand_bone(tag))).basis.orthonormalized()

func _hand_bone(tag: String) -> int:
	var index := skeleton.find_bone("Hand." + tag)
	return index if index >= 0 else skeleton.find_bone("Wrist." + tag)

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
