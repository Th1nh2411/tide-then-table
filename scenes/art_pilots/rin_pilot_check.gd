extends Node3D
## Meaningful compatibility checks for the new weighted Rin renderer.

var _failures := 0

func _check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1

func _ready() -> void:
	var actor := PersonRig3D.build(self, "rin")
	await get_tree().process_frame
	var visual := actor.get_node("RinPilot") as RinPilotVisual
	_check(visual != null and visual.skeleton.get_bone_count() == 20, "Rin uses 20-bone Hunyuan pilot")
	_check(actor.arms.size() == 2 and actor.legs.size() == 2 and actor.plate != null, "PersonRig anchors and plate API retained")
	var mesh := visual.model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_check(mesh.skin != null, "Imported mesh is actually skinned")
	var triangles := 0
	var normalized := true
	for surface: int in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for vertex: int in weights.size() / 4:
			var total := 0.0
			for influence: int in 4:
				total += weights[vertex * 4 + influence]
			if absf(total - 1.0) > 0.002:
				normalized = false
	_check(triangles == 3000 and mesh.mesh.get_surface_count() == 7, "Hunyuan 3000 triangles preserved with seven material regions")
	_check(normalized, "Skin weights are normalized")
	visual.sample_motion("Walk", 0.0)
	await get_tree().process_frame
	var first := mesh.bake_mesh_from_current_skeleton_pose()
	visual.sample_motion("Walk", 0.25)
	await get_tree().process_frame
	var second := mesh.bake_mesh_from_current_skeleton_pose()
	var moved := 0
	var finite := true
	for surface: int in first.get_surface_count():
		var a: PackedVector3Array = first.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		var b: PackedVector3Array = second.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for i in a.size():
			finite = finite and b[i].is_finite()
			if a[i].distance_to(b[i]) > 0.005:
				moved += 1
	_check(moved > 300 and finite, "Walk deforms real skin vertices without invalid coordinates")
	actor.set_carrying(true)
	visual.sample_motion("Carry", 0.25)
	await get_tree().process_frame
	_check(actor.plate.visible and visual.animation.assigned_animation == "Carry", "Carry selects the pose and shows the existing plate")
	for tag: String in ["L", "R"]:
		var hand := visual.hand_position(tag)
		_check(absf(hand.y - 1.055) < 0.025 and absf(hand.z - 0.37) < 0.025, "Carry wrist " + tag + " matches the plate grip")
	actor.set_carrying(false)
	actor.set_raised(true)
	_check(visual.animation.current_animation == "Raised", "Raised emote retains actor API")
	actor.set_raised(false)
	var rod := Node3D.new()
	actor.arms[1].add_child(rod)
	actor.arms[1].rotation.x = 0.2
	await get_tree().process_frame
	await get_tree().process_frame
	var before := visual.hand_position("L")
	actor.arms[1].rotation.x = -1.3
	await get_tree().process_frame
	await get_tree().process_frame
	var after := visual.hand_position("L")
	var attachment := actor.arms[1].to_global(Vector3(0, -0.6, 0))
	var wrist := actor.to_global(after)
	_check(before.distance_to(after) > 0.1, "Legacy cast arm rotation moves the skinned arm")
	_check(attachment.distance_to(wrist) < 0.01, "Legacy rod grip follows the actual wrist")
	var bao := PersonRig3D.build(self, "bao")
	_check(bao.get_node_or_null("RinPilot") == null and bao.arms.size() == 2, "Other actors retain their existing renderer")
	actor.queue_free()
	bao.queue_free()
	await get_tree().process_frame
	print("RIN PILOT CHECK ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)
