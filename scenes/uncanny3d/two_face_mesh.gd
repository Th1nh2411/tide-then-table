class_name TwoFaceMesh
extends RefCounted
## Builds TwoFace3D's copy of a model's face, in Head-bone space: every
## triangle whose three vertices are skinned mostly to Head and sit in front
## of the head's centre, turned 180° round the head's up axis. Uses the skin's
## bind poses, so it matches the rest pose exactly; keeps UVs and materials.


## {"mesh": ArrayMesh, "centre": Vector3, "front": float, "back": float}
## (front / back = how far the head reaches ahead of / behind its centre),
## or {} when the model has no skinned head.
static func build(model: Node, skeleton: Skeleton3D, head: int, forward: Vector3, up: Vector3,
		face_from: float, head_weight: float, depth_keep: float = 1.0) -> Dictionary:
	var parts: Array[Dictionary] = []
	var box := AABB()
	var has_box := false
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var binds := _head_binds(mi, skeleton, head)
		if binds.is_empty():
			continue
		var pose := mi.skin.get_bind_pose(binds[0])
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var part := _head_part(arrays, binds, pose, head_weight)
			if part.is_empty():
				continue
			part["material"] = mi.get_active_material(s)
			parts.append(part)
			for p: Vector3 in (part["head_points"] as PackedVector3Array):
				if has_box:
					box = box.expand(p)
				else:
					box = AABB(p, Vector3.ZERO)
					has_box = true
	if not has_box:
		return {}
	var centre := box.get_center()
	var front := 0.0
	var back := 0.0
	for part in parts:
		for p: Vector3 in (part["head_points"] as PackedVector3Array):
			front = maxf(front, (p - centre).dot(forward))
			back = maxf(back, -(p - centre).dot(forward))
	var axis := (up - forward * up.dot(forward)).normalized()
	var turn := Basis(axis, PI)
	var mesh := ArrayMesh.new()
	for part in parts:
		var arrays := _face_arrays(part, centre, forward, front, face_from, depth_keep, turn)
		if arrays.is_empty():
			continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, part["material"] as Material)
	if mesh.get_surface_count() == 0:
		return {}
	return {"mesh": mesh, "centre": centre, "front": front, "back": back}


## Skin bind indices of `head` (first) and the bones under it (eyes, jaw);
## empty if the mesh is not skinned to it.
static func _head_binds(mi: MeshInstance3D, skeleton: Skeleton3D, head: int) -> PackedInt32Array:
	var binds := PackedInt32Array()
	if mi.skin == null or mi.mesh == null:
		return binds
	var under := PackedInt32Array()
	for i in mi.skin.get_bind_count():
		var bone := mi.skin.get_bind_bone(i)
		if bone < 0:
			bone = skeleton.find_bone(mi.skin.get_bind_name(i))
		if bone == head:
			binds.append(i)
		elif _below(skeleton, bone, head):
			under.append(i)
	if binds.is_empty():
		return binds
	binds.append_array(under)
	return binds


static func _below(skeleton: Skeleton3D, bone: int, head: int) -> bool:
	var parent := skeleton.get_bone_parent(bone) if bone >= 0 else -1
	while parent >= 0:
		if parent == head:
			return true
		parent = skeleton.get_bone_parent(parent)
	return false


## Positions in Head space + which vertices are mostly Head (or under it;
## those still use Head's bind, so they follow the head, not the eyes).
static func _head_part(arrays: Array, binds: PackedInt32Array, pose: Transform3D, head_weight: float) -> Dictionary:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if arrays[Mesh.ARRAY_BONES] == null or verts.is_empty():
		return {}
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / verts.size()
	var local := PackedVector3Array()
	var is_head := PackedByteArray()
	var head_points := PackedVector3Array()
	local.resize(verts.size())
	is_head.resize(verts.size())
	for v in verts.size():
		var w := 0.0
		for k in per:
			if binds.has(bones[v * per + k]):
				w += weights[v * per + k]
		local[v] = pose * verts[v]
		is_head[v] = 1 if w >= head_weight else 0
		if w >= head_weight:
			head_points.append(local[v])
	if head_points.is_empty():
		return {}
	return {"arrays": arrays, "local": local, "is_head": is_head, "head_points": head_points, "basis": pose.basis}


## The face triangles of one surface, turned round the head's centre;
## depth_keep < 1 flattens it towards its front (eye sockets stay out of the hair).
static func _face_arrays(part: Dictionary, centre: Vector3, forward: Vector3, front: float,
		face_from: float, depth_keep: float, turn: Basis) -> Array:
	var ahead := front * face_from
	var arrays: Array = part["arrays"]
	var local: PackedVector3Array = part["local"]
	var is_head: PackedByteArray = part["is_head"]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		for i in local.size():
			indices.append(i)
	var bind_basis: Basis = part["basis"]
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_uv := PackedVector2Array()
	var remap := {}
	var out_i := PackedInt32Array()
	for t in range(0, indices.size() - 2, 3):
		var keep := true
		for k in 3:
			var v := indices[t + k]
			keep = keep and is_head[v] == 1 and (local[v] - centre).dot(forward) > ahead
		if not keep:
			continue
		for k in 3:
			var v := indices[t + k]
			if not remap.has(v):
				remap[v] = out_v.size()
				var rel := local[v] - centre
				var d := rel.dot(forward)
				rel += forward * ((front - (front - d) * depth_keep) - d)
				out_v.append(centre + turn * rel)
				out_n.append((turn * (bind_basis * normals[v])).normalized() if not normals.is_empty() else -forward)
				out_uv.append(uvs[v] if not uvs.is_empty() else Vector2.ZERO)
			out_i.append(int(remap[v]))
	if out_i.is_empty():
		return []
	var result := []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = out_v
	result[Mesh.ARRAY_NORMAL] = out_n
	result[Mesh.ARRAY_TEX_UV] = out_uv
	result[Mesh.ARRAY_INDEX] = out_i
	return result
