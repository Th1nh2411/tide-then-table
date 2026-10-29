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
		check(visual.skeleton.get_bone_count() == 20 and mesh.skin != null, id + " has real imported skin")
		visual.sample_motion("Walk", 0)
		await get_tree().process_frame
		var first := mesh.bake_mesh_from_current_skeleton_pose()
		visual.sample_motion("Walk", 0.25)
		await get_tree().process_frame
		var second := mesh.bake_mesh_from_current_skeleton_pose()
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
		actor.set_carrying(true)
		check(actor.plate.visible and visual.animation.current_animation == "Carry", id + " carry API")
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
