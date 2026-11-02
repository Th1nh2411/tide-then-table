extends SceneTree
## Writes the humanoid BoneMaps used by the PSX pack import (run once with
## --headless --script). Mixamo pack rig and the batch clip source rig.

const DIR := "res://assets/models/psx_chars/"
const SIDES := {"Left": "L", "Right": "R"}


func _init() -> void:
	var mixamo := {"Hips": "Hips", "Spine": "Spine", "Chest": "Spine1",
		"UpperChest": "Spine2", "Neck": "Neck", "Head": "Head"}
	var batch := {"Root": "Root", "Hips": "Hips", "Spine": "Spine",
		"Chest": "Chest", "Neck": "Neck", "Head": "Head"}
	for side: String in SIDES:
		var t: String = SIDES[side]
		mixamo[side + "Shoulder"] = side + "Shoulder"
		mixamo[side + "UpperArm"] = side + "Arm"
		mixamo[side + "LowerArm"] = side + "ForeArm"
		mixamo[side + "Hand"] = side + "Hand"
		mixamo[side + "UpperLeg"] = side + "UpLeg"
		mixamo[side + "LowerLeg"] = side + "Leg"
		mixamo[side + "Foot"] = side + "Foot"
		mixamo[side + "Toes"] = side + "ToeBase"
		for finger: String in ["Thumb", "Index", "Middle", "Ring", "Little"]:
			var src := "Pinky" if finger == "Little" else finger
			var parts: Array = ["Metacarpal", "Proximal", "Distal"] if finger == "Thumb" else ["Proximal", "Intermediate", "Distal"]
			for i in parts.size():
				mixamo[side + finger + parts[i]] = side + "Hand" + src + str(i + 1)
		batch[side + "Shoulder"] = "Clavicle." + t
		batch[side + "UpperArm"] = "UpperArm." + t
		batch[side + "LowerArm"] = "Forearm." + t
		batch[side + "Hand"] = "Hand." + t
		batch[side + "UpperLeg"] = "Thigh." + t
		batch[side + "LowerLeg"] = "Shin." + t
		batch[side + "Foot"] = "Foot." + t
	_save(mixamo, "mixamorig_", DIR + "mixamo_bone_map.tres")
	_save(batch, "", DIR + "batch_bone_map.tres")
	quit()


func _save(map: Dictionary, prefix: String, path: String) -> void:
	var bone_map := BoneMap.new()
	bone_map.profile = SkeletonProfileHumanoid.new()
	for key: String in map:
		bone_map.set_skeleton_bone_name(StringName(key), StringName(prefix + str(map[key])))
	print(path, " -> ", ResourceSaver.save(bone_map, path))
