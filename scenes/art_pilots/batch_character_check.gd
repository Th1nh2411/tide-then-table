extends Node3D
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func _ready() -> void:
	for id: String in ["bao", "vy", "vy_sau", "co_nam", "ong_tam", "guest_1", "guest_2", "guest_3", "guest_rich", "guest_regular", "staff"]:
		var actor := PersonRig3D.build(self,id)
		await get_tree().process_frame
		var visual := actor.get_node("BatchPilot") as BatchCharacterVisual
		var mesh := visual.model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var details := visual.model.find_children("CharacterFaceDetails*", "MeshInstance3D", true, false)
		check(details.size() == 1 and (details[0] as MeshInstance3D).skin != null, id + " eye details use real head skin")
		check(visual.skeleton.get_bone_count() == 20 and mesh.skin != null, id + " has real imported skin")
		visual.sample_motion("Walk", 0)
		await get_tree().process_frame
		var first := mesh.bake_mesh_from_current_skeleton_pose()
		var eyes := details[0] as MeshInstance3D
		var first_eyes := eyes.bake_mesh_from_current_skeleton_pose()
		var head := visual.skeleton.find_bone("Head")
		var first_head := visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(head)
		visual.sample_motion("Walk", 0.25)
		await get_tree().process_frame
		var second := mesh.bake_mesh_from_current_skeleton_pose()
		var second_eyes := eyes.bake_mesh_from_current_skeleton_pose()
		var second_head := visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(head)
		var follows_head := true
		for surface: int in first_eyes.get_surface_count():
			var a: PackedVector3Array = first_eyes.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var b: PackedVector3Array = second_eyes.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for i in a.size():
				var local_a := first_head.affine_inverse() * eyes.to_global(a[i])
				var local_b := second_head.affine_inverse() * eyes.to_global(b[i])
				follows_head = follows_head and local_a.distance_to(local_b) < 0.0001
		check(follows_head, id + " eyes and pupils follow the head during Walk without drifting")
		var moved := 0
		var finite := true
		var triangles := 0
		for surface: int in first.get_surface_count():
			var a: PackedVector3Array = first.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var b: PackedVector3Array = second.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			triangles += a.size()/3
			for i in a.size():
				finite = finite and b[i].is_finite()
				if a[i].distance_to(b[i]) > .005: moved += 1
		check(triangles == 3000 and moved > 250 and finite, id + " preserves 3000 triangles and deforms on Walk")
		var hips_rest := visual.skeleton.get_bone_global_rest(visual.skeleton.find_bone("Hips")).origin.y
		var body_scale := hips_rest / 0.92
		var narrow := true
		var not_crossed := true
		var walk_duration := visual.animation.get_animation("Walk").length
		for step: int in 16:
			visual.sample_motion("Walk", walk_duration * float(step) / 16.0)
			await get_tree().process_frame
			var left := visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("Foot.L")).origin
			var right := visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("Foot.R")).origin
			narrow = narrow and absf(left.x - right.x) < 0.27 * body_scale
			not_crossed = not_crossed and left.x > 0.07 * body_scale and right.x < -0.07 * body_scale
		# Original vertical/forward motion is intentionally retained; check_lateral_walk.py
		# compares Y/Z transforms against the source across the complete cycle.
		check(narrow and not_crossed, id + " Walk narrows lateral foot tracks without crossing")
		actor.set_carrying(true)
		check(actor.plate.visible and visual.animation.current_animation == "Carry", id + " carry API")
		visual.sample_motion("Carry", 0.25)
		await get_tree().process_frame
		var carry_left := visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("Foot.L")).origin
		var carry_right := visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("Foot.R")).origin
		check(absf(absf(carry_left.x-carry_right.x)/body_scale-0.386) < 0.001, id + " Carry restores the original stance after Walk")
		actor.set_carrying(false)
		check(not visual.animation.has_animation("Raised"), id + " has no Raised clip")
		actor.queue_free()
		await get_tree().process_frame
	var guest := PersonRig3D.build(self,"guest")
	guest.set_carrying(true)
	guest.set_variant("guest_rich")
	check(guest.get_variant() == "guest_rich" and guest.carrying and guest.plate.visible, "Guest appearance switch preserves gameplay state")
	var cat := PersonRig3D.build(self,"cat")
	check(cat.find_children("*", "MeshInstance3D", true, false).size() > 0, "Cat uses actual inferred mesh")
	print("BATCH CHARACTER CHECK ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)
