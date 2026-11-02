class_name RestaurantLease3D
extends RefCounted
## Unrented bays are plain public pavement; only the renovation preview marks a new bay.

static func preview(parent: Node3D, before: int, after: int) -> void:
	if after <= before: return
	var left := RestaurantLayout3D.lease_left(after)
	var right := RestaurantLayout3D.lease_left(before)
	var z := (RestaurantLayout3D.BACK_Z+RestaurantLayout3D.PUBLIC_WALK_Z)*.5
	_box(parent,Vector3((left+right)*.5,.025,z),Vector3(right-left,.025,RestaurantLayout3D.PUBLIC_WALK_Z-RestaurantLayout3D.BACK_Z),Color(.3,1,.45,.25))

static func _box(parent: Node3D, at: Vector3, size_: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size_
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = at
