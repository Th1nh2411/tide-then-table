extends Node3D
## PSX pack NPCs (PsxCharacterVisual): every cast id loads on the humanoid
## profile rig, plays the retargeted clips, stands / walks / sits / carries.

var failures := 0


func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for id: String in PsxCharacterVisual.CAST:
		var actor := PersonRig3D.build(self, id)
		await get_tree().process_frame
		var visual := actor.get_node_or_null("PsxPilot") as PsxCharacterVisual
		if visual == null:
			check(false, id + " uses PsxCharacterVisual")
			continue
		var sk := visual.skeleton
		var ok := sk.name == "GeneralSkeleton" and visual.bone("Foot.L") >= 0 and visual.bone("Thigh.R") >= 0
		ok = ok and visual._hand_bone("L") >= 0 and visual._hand_bone("R") >= 0
		for clip: String in ["Idle", "Walk", "Carry"]:
			ok = ok and visual.animation.has_animation(clip)
		check(ok, id + " has the humanoid rig and Idle/Walk/Carry")
		var head := _local(visual, sk.find_bone("Head"))
		var ankle := _local(visual, visual.bone("Foot.L"))
		check(head.y > 1.25 and head.y < 1.85 and ankle.y > -0.01 and ankle.y < 0.13, id + " stands on the ground (head %.2f, ankle %.2f)" % [head.y, ankle.y])
		var start := _local(visual, visual.bone("Foot.L"))
		var moved := 0.0
		for frame in 30:
			var step := Vector3(0, 0, 1.3 / 60.0)
			actor.position += step
			actor.drive_ground_motion(step, 1.0 / 60.0, false)
			moved = maxf(moved, _local(visual, visual.bone("Foot.L")).distance_to(start))
		check(visual.animation.current_animation == "Walk" and moved > 0.08, id + " walks by ground distance")
		actor.set_carrying(true)
		for frame in 20:
			actor.drive_ground_motion(Vector3(0, 0, 0.5 / 60.0), 1.0 / 60.0, false)
		var hands := (visual.hand_position("L") + visual.hand_position("R")) * 0.5
		check(actor.plate.visible and actor.plate.position.distance_to(hands) < 0.3 and hands.z > 0.15, id + " carries the plate in both hands, in front")
		actor.set_carrying(false)
		actor.set_seated(true)
		visual.sample_motion("SitIdle", 0.0)
		var hips := _local(visual, sk.find_bone("Hips"))
		var seated_ankle := _local(visual, visual.bone("Foot.L"))
		check(absf(hips.y - 0.5) < 0.05 and absf(seated_ankle.y - ankle.y) < 0.03 and seated_ankle.z > 0.15, id + " sits on the stool, feet on the floor")
		actor.queue_free()
	var walk := (load(PsxCharacterVisual.CLIP_SOURCE) as PackedScene) != null
	check(walk, "Clip source imports")
	var looks: Dictionary = {}
	for i in PersonRig3D.GUEST_POOL:
		looks[PersonRig3D.next_guest_variant()] = true
	check(looks.size() == PersonRig3D.GUEST_POOL, "Guests cycle through the whole pool")
	var a := PersonRig3D.build(self, "drowned")
	var b := PersonRig3D.build(self, "drowned")
	check(a.get_variant() != b.get_variant() and a.get_variant().begins_with("drowned"), "Drowned ghosts alternate the two models")
	print("PSX CHARACTERS ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _local(visual: RinPilotVisual, bone: int) -> Vector3:
	return visual.to_local(visual.skeleton.to_global(visual.skeleton.get_bone_global_pose(bone).origin))
