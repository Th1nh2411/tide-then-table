extends Node3D
## Standalone test for the uncanny visuals (run with F6): UncannyDirector's
## dose per day (only props / unseen tricks on mùng 9-10, wrong movement
## from 12, heavy only 13-14, at most one heavy a night, the same plan for
## the same loop + day, omen nights get movement only), one subtitle trick
## per loop, UnseenCheck, the jump-scare gates (ông Tư once, kept through a
## reset; never two scares on consecutive days), SubtitleTricks, the flash
## setting, the head-look toolkit on a real PSX rig, and the two faces
## (uncanny_two_faces_checks.gd).

const LOOPS := 150
const SCRATCH := "user://uncanny_test.cfg"
const MOVEMENT: Array[String] = ["stare", "freeze", "choppy", "wrong_walk", "glitch_face"]
const TwoFacesChecks = preload("res://scenes/test/uncanny_two_faces_checks.gd")


func _ready() -> void:
	var failures := 0
	failures += _check_dose()
	failures += _check_unseen()
	failures += _check_scares()
	failures += _check_subtitles()
	failures += _check_flash_setting()
	failures += await _check_head_look()
	failures += await TwoFacesChecks.run(self, _check)
	GameState.reset()
	print("uncanny_test: %s" % ("ALL PASS" if failures == 0 else "%d FAIL" % failures))
	get_tree().quit(0 if failures == 0 else 1)


func _check_dose() -> int:
	var early_ok := true
	var movement_ok := true
	var heavy_ok := true
	var one_heavy := true
	var omen_ok := true
	var heavy_seen := false
	var subtitle_ok := true
	for loop in LOOPS:
		var subtitles := 0
		for day in range(1, LoopCalendar.NIGHTS + 1):
			for omen: bool in [false, true]:
				var plan := UncannyDirector.plan(loop, day, omen)
				var light: Array = plan["light"]
				var heavy := str(plan["heavy"])
				if day <= 2:
					for id: String in light:
						early_ok = early_ok and id in ["props_turned", "door_closed"]
				if day <= 3:
					for id: String in light:
						movement_ok = movement_ok and not id in MOVEMENT
				if day <= 4 or day >= LoopCalendar.NIGHTS:
					heavy_ok = heavy_ok and heavy == ""
				heavy_seen = heavy_seen or heavy != ""
				for id: String in light:
					one_heavy = one_heavy and not id in UncannyDirector.HEAVY
				if omen:
					for id: String in light:
						omen_ok = omen_ok and id in UncannyDirector.OMEN_NIGHT_LIGHT
				elif str(plan["subtitle"]) != "":
					subtitles += 1
		subtitle_ok = subtitle_ok and subtitles == 1
	var failures := _check("mùng 9-10: only moved props / unseen tricks", early_ok)
	failures += _check("no wrong movement before mùng 12", movement_ok)
	failures += _check("no heavy effect on day <= 12 or on rằm", heavy_ok)
	failures += _check("heavy effects do show up on 13-14", heavy_seen)
	failures += _check("at most one heavy effect a night", one_heavy)
	failures += _check("omen nights: wrong movement only", omen_ok)
	failures += _check("one subtitle trick per loop", subtitle_ok)
	failures += _check("same loop + day -> same plan",
		UncannyDirector.plan(4, 5, false) == UncannyDirector.plan(4, 5, false))
	var differs := false
	for loop in range(1, 30):
		differs = differs or UncannyDirector.plan(loop, 6, false) != UncannyDirector.plan(0, 6, false)
	failures += _check("loops differ", differs)
	failures += _check("anh Út's cues from day 4", not UncannyDirector.plan(0, 3, false)["ut_cues"]
		and UncannyDirector.plan(0, LoopCalendar.NIGHTS, false)["ut_cues"])
	return failures


func _check_unseen() -> int:
	var eye := Vector3.ZERO
	var fwd := Vector3.FORWARD
	var failures := _check("unseen: straight ahead is in view", UnseenCheck.in_view(eye, fwd, 72.0, 16.0 / 9.0, Vector3(0, 0, -5)))
	failures += _check("unseen: behind is out of view", not UnseenCheck.in_view(eye, fwd, 72.0, 16.0 / 9.0, Vector3(0, 0, 5)))
	failures += _check("unseen: far to the side is out of view", not UnseenCheck.in_view(eye, fwd, 72.0, 16.0 / 9.0, Vector3(5, 0, -1)))
	failures += _check("unseen: just past the edge is in the margin", UnseenCheck.in_view(eye, fwd, 72.0, 16.0 / 9.0,
		Vector3(0, 0, -5).rotated(Vector3.UP, deg_to_rad(-57.0))))
	failures += _check("unseen: occluded counts as unseen", UnseenCheck.unseen(true, true) and not UnseenCheck.unseen(true, false))
	return failures


func _check_scares() -> int:
	GameState.reset()
	var dose := UncannyDirector.DOSE
	GameState.day = dose.tu_scare_day
	var failures := _check("ông Tư due on his day", UncannyDirector.tu_scare_due())
	GameState.day = dose.tu_scare_day + 1
	failures += _check("ông Tư not on other days", not UncannyDirector.tu_scare_due())
	GameState.day = dose.tu_scare_day
	GameState.set_flag(UncannyDirector.TU_FLAG)
	UncannyDirector.mark_scare()
	LoopCalendar.reset_loop()
	failures += _check("ông Tư flag survives a reset", GameState.has_flag(UncannyDirector.TU_FLAG))
	GameState.day = dose.tu_scare_day
	failures += _check("ông Tư fires once per playthrough", not UncannyDirector.tu_scare_due())
	failures += _check("scare day is per loop (cleared on reset)", not GameState.has_flag(UncannyDirector.SCARE_DAY_FLAG))
	UncannyDirector.mark_scare(2)
	failures += _check("no scare the day after a scare", not UncannyDirector.scare_allowed(3) and not UncannyDirector.scare_allowed(2))
	failures += _check("a scare two days later is fine", UncannyDirector.scare_allowed(4))
	var spaced := true
	for loop in 50:
		var fake := UncannyDirector.fake_scare_day(loop)
		spaced = spaced and fake in dose.fake_scare_days and absi(fake - dose.tu_scare_day) > 1
	spaced = spaced and absi(dose.tu_scare_day - LoopCalendar.NIGHTS) > 1
	failures += _check("planned scares never on consecutive days (fake, ông Tư, rằm)", spaced)
	GameState.reset()
	GameState.day = UncannyDirector.fake_scare_day(LoopCalendar.loops())
	failures += _check("fake scare due on its calm day", UncannyDirector.fake_scare_due())
	UncannyDirector.mark_scare(GameState.day - 1)
	failures += _check("fake scare waits if yesterday had one", not UncannyDirector.fake_scare_due())
	GameState.reset()
	GameState.day = UncannyDirector.fake_scare_day(0)
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	failures += _check("no fake scare on an omen night", not UncannyDirector.fake_scare_due())
	failures += _check("wrong-night faces rotate", UncannyDirector.wrong_night_variant(0) != UncannyDirector.wrong_night_variant(1)
		and UncannyDirector.wrong_night_variant(3) == UncannyDirector.wrong_night_variant(0))
	GameState.reset()
	return failures


func _check_subtitles() -> int:
	var line := RestaurantFish3D.ASK_LINE
	var wrong := SubtitleTricks.wrong_name("Bảo: Món bàn 2 xong rồi Rin!")
	var failures := _check("wrong name: Rin becomes Tư", wrong.contains("Tư") and not wrong.contains("Rin"))
	failures += _check("wrong name without his name adds it", SubtitleTricks.wrong_name(line).ends_with("Tư."))
	failures += _check("repeat is word for word", SubtitleTricks.line_for("repeat", line) == line)
	failures += _check("extra line has no speaker present", SubtitleTricks.speaker(SubtitleTricks.extra(0)) != "Bảo")
	return failures


func _check_flash_setting() -> int:
	var real_before := FileAccess.get_file_as_string(GameSettings.PATH)
	GameSettings.path = SCRATCH
	GameSettings.clear_cache()
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var failures := _check("flashes on by default", GameSettings.flash_effects())
	GameSettings.set_flash_effects(false)
	failures += _check("flash skipped when the setting is off", SingleFrameFlash3D.play(self) == null)
	GameSettings.set_flash_effects(true)
	var flash := SingleFrameFlash3D.play(self)
	failures += _check("flash plays when on", flash != null)
	if flash:
		flash.queue_free()
	camera.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	GameSettings.path = GameSettings.PATH
	GameSettings.clear_cache()
	failures += _check("player's settings.cfg untouched", FileAccess.get_file_as_string(GameSettings.PATH) == real_before)
	return failures


## A PSX rig with the head look: target behind it -> the head turns far round.
func _check_head_look() -> int:
	var rig := PersonRig3D.build(self, "bao")
	var target := Node3D.new()
	add_child(target)
	target.global_position = rig.global_position + Vector3(-0.6, 1.6, -2.0)  # behind-left (rig faces +Z)
	var actor := UncannyActor3D.attach(rig)
	var skeleton := rig.visual().skeleton
	var head := skeleton.find_bone("Head")
	var before := _head_forward(skeleton, head)
	# Modifier poses are reverted after each frame: read them as they apply.
	var seen: Array[Vector3] = [before]
	actor.look.modification_processed.connect(func() -> void: seen[0] = _head_forward(skeleton, head))
	actor.stare_at(target, 150.0, 0.0)
	for i in 4:
		await get_tree().process_frame
	var after := seen[0]
	var turned := rad_to_deg(Vector2(before.x, before.z).angle_to(Vector2(after.x, after.z)))
	var failures := _check("stare_at turns the head past the shoulder (%.0f°)" % absf(turned), absf(turned) > 100.0)
	actor.freeze()
	await get_tree().process_frame
	failures += _check("freeze holds the pose", actor.is_frozen())
	actor.release()
	actor.glitch_face(true)
	failures += _check("glitch_face shows the noise only on the head", actor.glitch.visible)
	rig.queue_free()
	target.queue_free()
	return failures


func _head_forward(skeleton: Skeleton3D, bone: int) -> Vector3:
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	return pose.basis.z.normalized()


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
