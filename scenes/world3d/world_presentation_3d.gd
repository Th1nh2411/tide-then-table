class_name WorldPresentation3D
extends RefCounted
## Shared presentation settings; source GLBs stay editable and unchanged.
const RESTAURANT_STOOL_SCALE := 0.85

static func cast_shadows(root: Node) -> void:
	if root is MeshInstance3D:
		(root as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for node in root.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
