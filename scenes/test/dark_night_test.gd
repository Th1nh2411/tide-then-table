extends Node
## Standalone test for đêm âm (DarkNight3D, run with F6): a calm night's sea
## is untouched; with the omen flag the sea turns dark (fog, water, oil burn,
## "sea_dark" bed) and haunts; being taken by the sea goes to the bedroom,
## which judges the night as RESET (back to mùng 9).

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"
const BEDROOM := "res://scenes/home3d/bedroom_scene_3d.tscn"

var _failures := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene = null  # stay a root sibling across scene changes
	_run.call_deferred()


func _run() -> void:
	SaveSystem.autosave_off = true
	SceneRouter.fade_duration = 0.01
	GameState.reset()
	# Calm night: no đêm âm node, nothing changed.
	var calm := await _open_sea()
	var calm_fog := _fog(calm)
	var calm_open := (calm.get_node("SeaWater") as SeaWater3D).shader_color("open_color")
	_check(DarkNight3D.active(calm) == null, "calm night has no đêm âm")
	_check(is_equal_approx(calm.oil_burn_scale, 1.0), "calm night burns oil normally")
	_check(Sfx._bed_name == "sea", "calm night plays the 'sea' bed")
	_check_false_sounds(calm)
	calm.queue_free()
	await get_tree().process_frame
	# Omen night, went out anyway: đêm âm.
	GameState.day = 3
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	var sea := await _open_sea()
	var dark := DarkNight3D.active(sea)
	_check(dark != null, "omen night adds đêm âm")
	_check(sea.get_node_or_null(CalmNightSounds3D.NODE_NAME) == null, "no calm-night false sounds on đêm âm")
	if dark == null:
		_finish()
		return
	_check(_fog(sea) > calm_fog * 2.0, "fog is thicker")
	var dark_open := (sea.get_node("SeaWater") as SeaWater3D).shader_color("open_color")
	_check(calm_open.a == 0.0 and dark_open == dark.look.water_open, "calm water keeps its colours, đêm âm repaints it")
	_check(is_equal_approx(sea.oil_burn_scale, dark.oil_burn_scale) and dark.oil_burn_scale > 1.0, "oil burns faster")
	_check(Sfx._bed_name == DarkNight3D.BED and HorrorBed.MIXES.has(DarkNight3D.BED), "đêm âm plays the 'sea_dark' bed")
	_check(dark.find_child("RedMoon", false, false) != null, "red moon is up")
	# Dread grows by day: mùng 10 only sounds; figures far off until 13 tháng Bảy.
	GameState.day = 2
	_check(not dark.event_pool().has("figure") and not dark.event_pool().has("swim"), "mùng 10: only sounds")
	GameState.day = 3
	_check(dark.event_pool().has("figure") and dark.figure_distance(5.0) >= dark.far_figure_distance, "day 3: figures, but far off")
	GameState.day = 5
	_check(is_equal_approx(dark.figure_distance(5.0), 5.0), "13 tháng Bảy: figures come to the lamp's edge")
	GameState.day = 3
	# Haunting: a figure at the edge of the light vanishes when looked at.
	dark._spawn_figure(DarkNightFigure3D.Kind.STAND)
	var figure: DarkNightFigure3D = dark.find_children("*", "DarkNightFigure3D", false, false)[0]
	var camera := get_viewport().get_camera_3d()
	_check(camera != null and (-camera.global_basis.z).angle_to(figure.global_position - camera.global_position)
		> deg_to_rad(figure.look_angle_deg), "figure appears off to the side")
	camera.look_at(figure.global_position + Vector3.UP)
	figure._process(0.0)
	await get_tree().create_timer(0.4).timeout
	_check(not is_instance_valid(figure), "figure vanishes when looked at")
	# Away long enough -> taken; the result is a loop reset.
	dark.taken_speed = 40.0
	dark.away_seconds = dark.taken_after_seconds
	_check(dark.should_take(), "time at sea triggers the ending")
	dark.take()
	var bedroom := await _scene(BEDROOM)
	_check(bedroom != null, "taken by the sea -> bedroom")
	_check(GameState.day == 1 and LoopCalendar.loops() == 1 and not GameState.has_flag(LoopCalendar.OMEN_FLAG),
		"bedroom judged it RESET: back to mùng 9")
	_check(_reset_rule(), "omen + went out = RESET")
	_finish()


## Calm nights: rare harmless sounds (25-60 s apart), never the đêm âm knock.
func _check_false_sounds(calm: SeaScene3D) -> void:
	var sounds := calm.get_node_or_null(CalmNightSounds3D.NODE_NAME) as CalmNightSounds3D
	_check(sounds != null, "calm night has false sounds")
	if sounds == null:
		return
	var gaps_ok := true
	for day: int in [1, 4, 7]:
		GameState.day = day
		for i in range(50):
			var gap := sounds.next_gap()
			gaps_ok = gaps_ok and gap >= 25.0 and gap <= 60.0
	GameState.day = 1
	_check(gaps_ok, "false sounds are rare: one every 25-60 s")
	for kind: String in CalmNightSounds3D.KINDS:
		sounds.play(kind)
	var recipes_ok := Sfx.has_sound("slap") and Sfx.has_sound("tock") and Sfx.has_sound("plip")
	_check(sounds.played.size() == CalmNightSounds3D.KINDS.size() and not sounds.played.has("knock3")
		and recipes_ok and Sfx.SOUNDS["tock"] != Sfx.SOUNDS["knock3"], "each false sound plays, none is the knock")


## LoopCalendar's rule straight, without a scene in between.
func _reset_rule() -> bool:
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	LoopCalendar.choose(true)
	var result := LoopCalendar.take_result()
	GameState.story_flags.erase(LoopCalendar.OMEN_FLAG)
	return result == LoopCalendar.Result.RESET


func _open_sea() -> SeaScene3D:
	SceneRouter.go_to(SEA)
	return await _scene(SEA) as SeaScene3D


func _scene(path: String) -> Node:
	for i in 240:
		var current := get_tree().current_scene
		if current and current.scene_file_path == path and not SceneRouter._is_transitioning:
			await get_tree().process_frame
			return current
		await get_tree().process_frame
	return null


func _fog(sea: SeaScene3D) -> float:
	var envs := sea.find_children("*", "WorldEnvironment", false, false)
	return (envs[0] as WorldEnvironment).environment.fog_density if not envs.is_empty() else 0.0


func _check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1


func _finish() -> void:
	GameState.reset()
	print("DARK NIGHT TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)
