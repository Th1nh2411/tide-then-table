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
	await _ghost_cast()
	print("PSX CHARACTERS ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


## Every ghost-cast id loads its own model with the ghost look; the pool
## rotates without repeating a face; a ghost figure has no collider.
func _ghost_cast() -> void:
	var files: Dictionary = {}
	var ok := true
	for id: String in GhostCast3D.POOL:
		ok = ok and PsxCharacterVisual.CAST.has(id) and id in PsxCharacterVisual.GHOSTS and PersonRig3D.LOOKS.has(id)
		files[PsxCharacterVisual.CAST.get(id, "")] = true
	check(ok and files.size() == GhostCast3D.POOL.size(), "ghost cast: %d ids, each its own model, all ghosts" % GhostCast3D.POOL.size())
	var seen: Array[String] = []
	for i in GhostCast3D.POOL.size():
		seen.append(GhostCast3D.next_id())
	var unique := true
	for i in seen.size():
		unique = unique and seen.count(seen[i]) == 1
	check(unique, "the pool shows every face once before repeating")
	var rig := GhostCast3D.figure(self, "ma_da")
	await get_tree().process_frame
	var blocker := rig.get_node_or_null("PersonBlocker") as StaticBody3D
	var ghost := not GhostCast3D.materials(rig).is_empty() and rig.visual().has_meta(StylePass3D.SKIP)
	check(ghost and blocker != null and blocker.collision_layer == 0 and GhostCast3D.actor_of(rig) != null, "ma_da: ghost look, no collider, an uncanny actor")
	var faded := GhostCast3D.figure(self, "corpse", true)
	var tween := create_tween()
	GhostCast3D.fade(tween, faded, 0.0, 0.05)
	await tween.finished
	var m := GhostCast3D.materials(faded)
	check(not m.is_empty() and GhostLook3D.opacity(m[0]) < 0.01 and GhostLook3D.opacity(GhostCast3D.materials(rig)[0]) > 0.99, "a unique ghost fades alone")
	rig.queue_free()
	faded.queue_free()


func _local(visual: RinPilotVisual, bone: int) -> Vector3:
	return visual.to_local(visual.skeleton.to_global(visual.skeleton.get_bone_global_pose(bone).origin))
