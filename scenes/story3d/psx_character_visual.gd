class_name PsxCharacterVisual
extends RinPilotVisual
## NPC body from the PSX character pack (Mixamo rig). Both the pack FBX and the
## clip source (batch rig Idle/Walk/Carry) are humanoid-retargeted on import
## (tools/psx_chars), so the clips play on every model through one library.

const DIR := "res://assets/models/psx_chars/"
const CLIP_SOURCE := DIR + "clip_source.glb"
const ONE_SHOTS := ["Cast", "SitDown", "StandUp"]
const SPINE := ["Spine", "Chest", "UpperChest", "Neck", "Head"]
## The dead (GhostLook3D): drowned figures (GhostCast3D.POOL) and ông Tư.
const GHOSTS := ["drowned_m", "drowned_f", "ong_tu", "ma_da", "ma_da_b", "drowned_old", "corpse"]
## Variant id -> pack model (file name without .fbx). Several ids may share one.
const CAST := {
	"bao": "Character_Male_46", "co_nam": "Character_51_Female",
	"guest_rich": "Character_Male_35", "chu_hai": "Character_Male_49",
	"ong_tam": "Character_Male_49", "ong_tu": "Character_Male_45",
	"guest_1": "Character_Male_34", "guest_2": "Character_29_Female",
	"guest_3": "Character_12", "guest_4": "Character_30_Female",
	"guest_5": "Character_13", "guest_6": "Character_32_Female",
	"guest_7": "Character_Male_50", "guest_8": "Character_54_Female",
	"guest_9": "Character_Male_34", "guest_regular": "Character_Male_50",
	"staff": "Character_13", "vy": "Character_30_Female",
	"vy_sau": "Character_54_Female",
	# Chú Bảy, the dead regular: his model is kept out of the guest pool.
	"chu_bay": "Character_Male_53",
	"drowned_m": "Character_Male_57", "drowned_f": "Character_31_Female",
	# Ghost-only models (never plain): long-haired women (ma da), a thin old
	# man, a long-drowned body.
	"ma_da": "Character_Female_09", "ma_da_b": "Character_47_Female",
	"drowned_old": "Character_32", "corpse": "Character_Killer_06",
}

static var _clips: Array[Animation] = []
static var _clip_names: Array[String] = []
static var _materials: Dictionary = {}

var asset_id: String = "bao"
## False keeps a ghost id in its plain pack look (review scenes).
var ghost_look := true


func _ready() -> void:
	load_variant(asset_id)


func load_variant(id: String) -> void:
	asset_id = id
	if model:
		remove_child(model)
		model.queue_free()
	# Unknown ids may name a pack file directly (review scenes).
	var file := str(CAST.get(id, id if ResourceLoader.exists(DIR + id + ".fbx") else CAST["guest_1"]))
	model = load(DIR + file + ".fbx").instantiate()
	add_child(model)
	WorldPresentation3D.cast_shadows(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_style_materials()
	if id in GHOSTS and ghost_look:
		GhostLook3D.apply(self)
	elif has_meta(StylePass3D.SKIP):
		remove_meta(StylePass3D.SKIP)  # was a ghost variant before
		var drips := get_node_or_null(GhostLook3D.DRIPS)
		if drips:
			drips.queue_free()
	# Own library per model (runtime seat clips are calibrated per skeleton).
	var library := AnimationLibrary.new()
	_load_clips()
	for i in _clips.size():
		library.add_animation(_clip_names[i], _clips[i])
	animation.stop()
	for lib: StringName in animation.get_animation_library_list():
		animation.remove_animation_library(lib)
	animation.add_animation_library("", library)
	_motion = "Idle"
	animation.play(_motion)
	animation.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	_foot_plant = GroundFootPlant3D.new(self)


## The texture of the body (ghost materials reuse it).
func body_texture() -> Texture2D:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var material := mesh.get_active_material(0) as BaseMaterial3D
		if material and material.albedo_texture:
			return material.albedo_texture
	return null


## One nearest-filtered material per source material (shared by every
## instance); StylePass3D grades it like the world.
func _style_materials() -> void:
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():
			var source := mesh.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var key := "%s:%s:%d" % [model.scene_file_path, mesh.name, surface]
			if not _materials.has(key):
				var material := source.duplicate() as BaseMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				material.roughness = 0.9
				_materials[key] = material
			mesh.set_surface_override_material(surface, _materials[key])


static func _load_clips() -> void:
	if not _clips.is_empty():
		return
	var source := (load(CLIP_SOURCE) as PackedScene).instantiate()
	var player := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in player.get_animation_list():
		var copy := player.get_animation(clip).duplicate(true) as Animation
		# The batch spine is straight; the pack keeps its own lean (rest pose).
		for track in range(copy.get_track_count() - 1, -1, -1):
			if String(copy.track_get_path(track).get_subname(0)) in SPINE:
				copy.remove_track(track)
		copy.loop_mode = Animation.LOOP_NONE if clip in ONE_SHOTS else Animation.LOOP_LINEAR
		_clips.append(copy)
		_clip_names.append(clip)
	source.free()


func _hand_bone(tag: String) -> int:
	return skeleton.find_bone("LeftHand" if tag == "L" else "RightHand")


## NPCs never hold the rod; keep the clip playing.
func set_cast_arm(_index: int, _angle: float) -> void:
	pass
