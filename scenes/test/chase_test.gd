extends Node3D
## "Too close to a phenomenon" + chases + the talk camera (F6): the warning
## band and notice distance, chaser speed against a walking / running Rin
## (RestaurantScene3D's own speeds and stamina), the director's gates (not
## before mùng 12, once a night, never for the bot), chases only push Rin
## landward, the `uncanny_skip` meta, a caught night resetting to mùng 9
## with note_ flags kept, and in the real village: the talk camera turning
## to ông Tám and letting go, the warning overlay, a noticed figure chasing,
## frozen while seen, a safe place ending it (wet steps next morning),
## being caught, and nothing Rin must approach carrying a zone.

const T: ProximityTuning = preload("res://data/story/proximity_tuning.tres")
const DARK_SPOT := Vector3(30.0, 0, 3.5)  # the lane, away from lamps and the shrine

var failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	_rules()
	_speeds()
	_gates()
	_caught_resets()
	await _village()
	GameState.reset()
	UncannyDirector.bot = false
	print("CHASE TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		failures += 1


func _rules() -> void:
	_check(ChaseRules.warning(T.warn_distance + 0.5) == 0.0 and ChaseRules.warning(T.warn_distance) == 0.0, "no warning outside ~4 m")
	var mid := ChaseRules.warning((T.warn_distance + T.notice_distance) * 0.5)
	_check(mid > 0.4 and mid < 0.6 and is_equal_approx(ChaseRules.warning(T.notice_distance), 1.0), "the warning rises to full at the notice distance")
	_check(ChaseRules.notices(T.notice_distance) and not ChaseRules.notices(T.notice_distance + 0.1), "it notices Rin at 1.5 m, not before")
	_check(ChaseRules.reaction(true, true, false) == ChaseRules.Reaction.CHASE
		and ChaseRules.reaction(true, true, true) == ChaseRules.Reaction.SCARE
		and ChaseRules.reaction(false, true, false) == ChaseRules.Reaction.SCARE
		and ChaseRules.reaction(false, false, false) == ChaseRules.Reaction.VANISH, "chase / face / vanish by the rules")
	var a := ChaseRules.chase_seconds(2, 5)
	_check(a == ChaseRules.chase_seconds(2, 5) and a >= 10.0 and a <= 20.0, "a chase lasts 10-20 s, the same for the same loop + day")
	_check(ChaseRules.pushes_landward(-3.0, 1.0, true) and not ChaseRules.pushes_landward(4.0, 1.0, true)
		and ChaseRules.pushes_landward(4.0, 1.0, false), "near the water it only comes from the sea side")
	var skip := Node3D.new()
	skip.set_meta(ChaseRules.SKIP_META, true)
	var child := Node3D.new()
	skip.add_child(child)
	add_child(skip)
	_check(ChaseRules.skipped(child) and ProximityZone3D.guard(child) == null, "uncanny_skip: never guarded (chú Bảy)")
	skip.free()


## Rin flees the moment it notices him, looking ahead (it is always unseen).
func _speeds() -> void:
	var walking := _flee(false)
	var running := _flee(true)
	_check(walking < T.chase_seconds_min, "a walking Rin is caught (%.1f s)" % walking)
	_check(running < 0.0, "a running Rin outlasts even a 20 s chase")
	var runner := ChaseRules.Runner.new(T)
	var still := 0.0
	for i in 60:
		still += float(runner.step(true, 1.0 / 60.0)["move"])
	_check(still == 0.0, "it does not move while Rin looks at it")


## Seconds until caught, -1 = never within chase_seconds_max.
func _flee(run: bool) -> float:
	var scene := RestaurantScene3D.new()
	var walk: float = scene.walk_speed
	var fast: float = scene.run_speed
	var drain: float = scene.stamina_seconds
	var rest_delay: float = scene.stamina_rest_delay
	var refill: float = scene.stamina_refill_seconds
	var resume: float = scene.stamina_resume
	scene.free()
	var runner := ChaseRules.Runner.new(T)
	var gap := T.notice_distance
	var stamina := 1.0
	var winded := false
	var rest := 0.0
	var dt := 1.0 / 60.0
	var t := 0.0
	while t < T.chase_seconds_max:
		t += dt
		if winded and stamina >= resume:
			winded = false
		var fast_now := run and not winded
		if fast_now:
			stamina = maxf(stamina - dt / drain, 0.0)
			rest = 0.0
			winded = stamina <= 0.0
		else:
			rest += dt
			if rest >= rest_delay:
				stamina = minf(stamina + dt / refill, 1.0)
		gap += (fast if fast_now else walk) * dt
		if t > T.start_wait:
			gap -= float(runner.step(false, dt)["move"])
		if gap <= T.catch_distance:
			return t
	return -1.0


func _gates() -> void:
	GameState.reset()
	_check(not UncannyDirector.chase_allowed(3) and UncannyDirector.chase_allowed(4), "no chase before mùng 12")
	GameState.day = 4
	UncannyDirector.mark_chase()
	_check(not UncannyDirector.chase_allowed(4) and UncannyDirector.chase_allowed(5), "at most one chase a night")
	_check(not UncannyDirector.chase_allowed(7), "none on rằm")
	GameState.reset()


func _caught_resets() -> void:
	GameState.reset()
	GameState.day = 5
	GameState.set_flag("note_clue_3")
	GameState.set_flag(LoopCalendar.CHOICE_FLAG, "out")
	GameState.set_flag(LoopCalendar.CATCH_FLAG, 3)
	LoopCalendar.caught()
	var result := VillageDay3D.judge_morning()
	_check(result == LoopCalendar.Result.RESET and GameState.day == 1 and LoopCalendar.loops() == 1, "caught = back to mùng 9 even with 3 fish")
	_check(GameState.has_flag("note_clue_3") and not GameState.has_flag(LoopCalendar.CAUGHT_FLAG), "note_ flags kept, the caught flag used up")
	_check(LoopCalendar.missed() == LoopCalendar.MISSED_CAUGHT and VillageSpots3D.NEWS.hint(LoopCalendar.missed()) != "", "the mùng 9 paper hints at it")
	var tam: NpcLinesData = load("res://data/story/ong_tam.tres")
	_check(tam.lines_for(1, "", LoopCalendar.MISSED_CAUGHT)[0].contains("lại gần"), "ông Tám says not to go near")
	var note: NoteData = load("res://data/story/kieng_note.tres")
	_check(note.lines.size() <= 6 and " ".join(note.lines).contains("đừng có lại gần"), "the kiêng note teaches it (still 6 rules)")
	GameState.reset()


func _village() -> void:
	GameState.reset()
	GameState.day = 4
	var village := (load(VillageLayout3D.SCENE) as PackedScene).instantiate() as VillageScene3D
	get_tree().root.add_child(village)
	var was := get_tree().current_scene
	get_tree().current_scene = village
	await get_tree().process_frame
	await get_tree().process_frame
	await _talk_camera(village)
	var view := LookAtSpeaker3D.view()
	view.set_process(false)  # the test aims the camera itself from here
	var camera := village.get_viewport().get_camera_3d()
	_excluded(village)
	await _warning_and_chase(village, camera)
	get_tree().current_scene = was
	village.queue_free()
	await get_tree().process_frame


## E on ông Tám with Rin facing away: the view turns to his head, then lets go.
func _talk_camera(village: VillageScene3D) -> void:
	var view := LookAtSpeaker3D.view()
	_check(view != null, "the first-person view is there")
	if view == null:
		return
	var tam := village.npcs.tam
	village.player.global_position = tam.global_position + Vector3(-1.2, 0, 0.6)
	view.turn(PI)
	await get_tree().process_frame
	var head := tam.global_position + Vector3.UP * 1.2
	var camera := village.get_viewport().get_camera_3d()
	var before := UnseenCheck.look_angle(camera, head)
	village.npcs.tam_talk.say()
	_check(view.turning(), "a line starts the turn")
	for i in 30:
		await get_tree().process_frame
	var after := UnseenCheck.look_angle(camera, head)
	_check(before > 90.0 and after < 12.0, "the view turned to the speaker (%.0f° -> %.0f°)" % [before, after])
	_check(not view.turning(), "the turn ends (~0.3 s)")
	view.turn(1.0)
	for i in 5:
		await get_tree().process_frame
	_check(UnseenCheck.look_angle(camera, head) > 40.0, "afterwards Rin looks away freely")
	get_tree().paused = true
	_check(not LookAtSpeaker3D.at(head), "no turn while paused / in a menu")
	get_tree().paused = false


func _excluded(village: VillageScene3D) -> void:
	var ok := true
	for rig: Node in [village.bao_model, village.vy.rig, village.npcs.tam, village.npcs.hai]:
		if rig and not rig.find_children(ProximityZone3D.NODE_NAME, "", true, false).is_empty():
			ok = false
	_check(ok, "Bảo, Vy, ông Tám, chú Hai carry no zone")
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	var seat := AnhUtRegular3D.attach(village)
	await get_tree().process_frame
	_check(seat.ghost != null and ProximityZone3D.of(seat.ghost) != null and seat.ut == null, "the guest without a shadow has a zone, anh Út never")
	seat.queue_free()
	GameState.story_flags.erase(LoopCalendar.OMEN_FLAG)


func _figure(village: VillageScene3D, at: Vector3, kind: ProximityZone3D.Kind) -> Dictionary:
	var body := GhostCast3D.figure(village)
	body.global_position = at
	var zone := ProximityZone3D.guard(body, kind, GhostCast3D.actor_of(body))
	zone.set_process(false)
	await get_tree().process_frame
	return {"body": body, "zone": zone}


func _warning_and_chase(village: VillageScene3D, camera: Camera3D) -> void:
	var player := village.player
	var fx := ProximityFx3D.of(village)
	var fig := await _figure(village, DARK_SPOT + Vector3(-2.5, 0, 0), ProximityZone3D.Kind.CHASE)
	var zone := fig["zone"] as ProximityZone3D
	player.global_position = DARK_SPOT + Vector3(6.0, 0, 0)
	zone._process(0.0)
	player.global_position = DARK_SPOT + Vector3(0.5, 0, 0)  # 3 m
	zone._process(0.0)
	fx._process(0.5)
	_check(fx.level > 0.2 and Chase3D.running(village) == false, "warning band at 3 m: overlay + heartbeat, no reaction yet")
	UncannyDirector.bot = true
	player.global_position = DARK_SPOT + Vector3(-1.2, 0, 0)
	zone._process(0.0)
	_check(not Chase3D.running(village) and not zone._done, "the bot never sets it off")
	UncannyDirector.bot = false
	zone._process(0.0)
	var chase := village.get_node_or_null(Chase3D.NODE_NAME) as Chase3D
	_check(chase != null, "at 1.3 m it notices Rin and gives chase (mùng 12)")
	if chase == null:
		return
	chase.set_process(false)
	var body := fig["body"] as Node3D
	player.global_position = DARK_SPOT + Vector3(3.0, 0, 0)
	chase._wait = 0.0
	camera.look_at_from_position(player.global_position + Vector3.UP * 1.55, body.global_position + Vector3.UP * 1.0)
	var start := body.global_position
	for i in 10:
		chase._process(0.1)
	_check(body.global_position.distance_to(start) < 0.01, "frozen while Rin looks at it")
	camera.look_at_from_position(player.global_position + Vector3.UP * 1.55, player.global_position + Vector3(5, 1.5, 0))
	for i in 24:
		chase._process(0.1)
		await get_tree().process_frame  # its dash is a tween
	_check(body.global_position.distance_to(start) > 1.0, "it comes while he looks away (dash + glide)")
	# Safe at the shrine: it ends, fades, and wet steps wait outside the door next morning.
	player.global_position = VillageLaneBuilder3D.SHRINE + Vector3(0, 0, 1.0)
	chase._process(0.1)
	_check(chase._over and not chase._caught and GameState.has_flag(Chase3D.TRACE_FLAG), "the roadside shrine ends the chase")
	Chase3D.leave_trace(village)
	_check(village.has_node("ChaseFootprints") and not GameState.has_flag(Chase3D.TRACE_FLAG), "next morning: wet steps up to the door")
	chase.queue_free()
	await get_tree().process_frame
	# Not twice a night: the next figure only shows its face.
	var second := await _figure(village, DARK_SPOT + Vector3(-2.5, 0, 0), ProximityZone3D.Kind.CHASE)
	var zone2 := second["zone"] as ProximityZone3D
	player.global_position = DARK_SPOT + Vector3(6.0, 0, 0)
	zone2._process(0.0)
	player.global_position = DARK_SPOT + Vector3(-1.3, 0, 0)
	zone2._process(0.0)
	_check(zone2._done and not Chase3D.running(village), "one chase a night: the second only shows its face")
	# Caught: reset flag, Rin stops.
	GameState.story_flags.erase(UncannyDirector.CHASE_FLAG)
	GameState.story_flags.erase(UncannyDirector.SCARE_DAY_FLAG)
	var third := await _figure(village, DARK_SPOT + Vector3(-1.0, 0, 0), ProximityZone3D.Kind.CHASE)
	var caught := Chase3D.start(village, third["body"] as Node3D)
	caught.set_process(false)
	caught.reload = false
	player.global_position = DARK_SPOT + Vector3(-0.6, 0, 0)
	caught._process(0.1)
	_check(caught._caught and GameState.has_flag(LoopCalendar.CAUGHT_FLAG) and village.leaving, "caught: Rin stops, the night is a reset")
	# A sea-side rule check in the scene: on the sand, a figure landward of Rin never chases.
	village.leaving = false
	GameState.story_flags.erase(UncannyDirector.CHASE_FLAG)
	var sand := VillageLayout3D.waterfront_point(Vector3(-8.0, 0, 6.0))
	var landward := await _figure(village, sand + Vector3(0, 0, 1.2), ProximityZone3D.Kind.CHASE)
	var zone3 := landward["zone"] as ProximityZone3D
	player.global_position = sand + Vector3(0, 0, 6.0)
	zone3._process(0.0)
	player.global_position = sand
	var reaction := zone3.notice()
	_check(reaction != ChaseRules.Reaction.CHASE, "by the sea a figure on the land side never chases Rin seaward")
	caught.queue_free()
