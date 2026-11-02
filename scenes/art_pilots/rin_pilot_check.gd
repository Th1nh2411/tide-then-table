extends Node3D
## Pilot2 art transfer and compatibility checks using actual GPU skin deformation.
var _failures := 0
func _check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1

func _ready() -> void:
	var actor := PersonRig3D.build(self, "rin")
	await get_tree().process_frame
	var visual := actor.get_node("RinPilot") as RinPilotVisual
	_check(visual.skeleton.get_bone_count() == 62, "Rin retains pilot2's native 62-bone rig")
	_check(actor.arms.size() == 2 and actor.legs.size() == 2 and actor.plate != null, "PersonRig anchors and plate API retained")
	var meshes := visual.model.find_children("*", "MeshInstance3D", true, false)
	var triangles := 0
	var normalized := true
	for mesh: MeshInstance3D in meshes:
		_check(mesh.skin != null, "Actual skin retained: " + mesh.name)
		for surface: int in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for vertex: int in weights.size() / 4:
				var total := 0.0
				for influence: int in 4:
					total += weights[vertex * 4 + influence]
				normalized = normalized and absf(total - 1.0) < 0.002
	_check(triangles == 5338 and meshes.size() == 6, "Pilot2 body retained with transferred hair and added glasses")
	_check(normalized, "All skin weights normalized")
	var source: Node3D = load("res://assets/models/ready/rin/rin_pilot2.glb").instantiate()
	add_child(source)
	var source_skeleton := source.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var source_animation := source.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var retained := true
	for clip: String in source_animation.get_animation_list():
		retained = retained and visual.animation.has_animation(clip)
	_check(retained, "All 24 original pilot2 animations remain available")
	var duration := source_animation.get_animation("CharacterArmature|Walk").length
	var max_error := 0.0
	for step: int in 8:
		var time := duration * float(step) / 8.0
		source_animation.play("CharacterArmature|Walk")
		source_animation.seek(time, true)
		source_animation.pause()
		visual.sample_motion("Walk", time)
		await get_tree().process_frame
		source_skeleton.force_update_all_bone_transforms()
		for bone: String in ["Head", "Wrist.L", "Wrist.R", "UpperLeg.L", "LowerLeg.R", "Foot.L", "Foot.R"]:
			var a := source_skeleton.to_global(source_skeleton.get_bone_global_pose(source_skeleton.find_bone(bone)).origin)
			var b := visual.skeleton.to_global(visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone(bone)).origin)
			max_error = maxf(max_error, a.distance_to(b))
	_check(max_error < 0.003, "Native Walk preserved against original pilot2 (max joint error %.6fm)" % max_error)
	var finite := true
	for mesh: MeshInstance3D in meshes:
		var baked := mesh.bake_mesh_from_current_skeleton_pose()
		for surface: int in baked.get_surface_count():
			var points: PackedVector3Array = baked.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for point: Vector3 in points:
				finite = finite and point.is_finite()
	_check(finite, "All six meshes deform with finite coordinates on GPU")
	actor.set_carrying(true)
	visual.sample_motion("Carry", 0.25)
	await get_tree().process_frame
	_check(actor.plate.visible and visual.animation.assigned_animation == "Carry", "Carry compatibility clip and existing plate work")
	var grip := (visual.hand_position("L") + visual.hand_position("R")) * 0.5
	_check(grip.distance_to(actor.plate.position) < 0.12, "Tray follows the new rig's wrists")
	actor.set_carrying(false)
	_check(not visual.animation.has_animation("Raised"), "No obsolete Raised clip")
	var rod := Node3D.new()
	actor.arms[1].add_child(rod)
	actor.sample_cast(0.45)
	var wind_up := visual.hand_position("L")
	actor.sample_cast(0.9)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(visual.animation.assigned_animation == "Cast" and wind_up.distance_to(visual.hand_position("L")) > 0.15, "Cast compatibility clip moves the wrist")
	_check(actor.arms[1].to_global(Vector3(0, -0.6, 0)).distance_to(actor.to_global(visual.hand_position("L"))) < 0.01, "Rod stays attached to the new wrist")
	var bao := PersonRig3D.build(self, "bao")
	_check(bao.get_node_or_null("PsxPilot") is PsxCharacterVisual, "NPCs use the PSX pack visual")
	actor.queue_free()
	source.queue_free()
	bao.queue_free()
	await get_tree().process_frame
	print("RIN PILOT CHECK ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)
