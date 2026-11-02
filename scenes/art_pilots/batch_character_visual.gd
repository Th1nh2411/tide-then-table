class_name BatchCharacterVisual
extends RinPilotVisual
## Weighted inferred batch mesh; shares the gameplay hand and motion API.
## Unused since NPCs moved to `PsxCharacterVisual`; kept (with assets/models/ready
## characters) as the fallback while the PSX pack licence is unverified.

var asset_id: String = "bao"

func _ready() -> void:
	load_variant(asset_id)

func load_variant(id: String) -> void:
	asset_id = id
	if model:
		remove_child(model)
		model.queue_free()
	model = load("res://assets/models/ready/%s/%s.glb" % [id, id]).instantiate()
	add_child(model)
	WorldPresentation3D.cast_shadows(model)
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	animation = model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip: String in animation.get_animation_list():
		animation.get_animation(clip).loop_mode = Animation.LOOP_NONE if clip in ["Cast","SitDown","StandUp"] else Animation.LOOP_LINEAR
	_motion = "Idle"
	animation.play(_motion)
	animation.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	_foot_plant = GroundFootPlant3D.new(self)
