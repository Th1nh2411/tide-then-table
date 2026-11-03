class_name VillageDay3D
extends RefCounted
## The day's turns on the village map. Every morning is a fresh load of the
## village scene behind a black fade (simplest way to reset the day: omens,
## guests, shift, dock props and rằm props are all rebuilt), which judges
## the night just slept (LoopCalendar). Sleeping on the bed and coming back
## from the sea both lead here:
## - bed: no trip tonight -> choose(false); reload -> morning (judged);
## - thúng: the night sea; docking records the fish (choose(true, n)) and
##   reloads the village at night on the pier (NIGHT_FLAG); then the bed.

## Set by the sea on docking: the next village load starts at night on the pier.
const NIGHT_FLAG := "village_night"
const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"


## Morning: judges last night (next day / back to mùng 9 / the ending) and
## picks tonight's omen. END: the caller goes to the ending.
static func judge_morning() -> LoopCalendar.Result:
	var result := LoopCalendar.take_result()
	if result == LoopCalendar.Result.END:
		# Rằm judged here (fallback; the sea normally goes to the epilogue itself).
		RamNight.finish(RamNight.current(LoopCalendar.last_choice == "out"))
		return result
	if result == LoopCalendar.Result.NEXT:
		LoopCalendar.next_day()
	elif result == LoopCalendar.Result.RESET:
		LoopCalendar.reset_loop()
	OmenPicker.start_day()
	return result


## The bed: the night is "stayed home" unless he already went out.
static func sleep(host: VillageScene3D) -> void:
	if not GameState.story_flags.has(LoopCalendar.CHOICE_FLAG):
		LoopCalendar.choose(false)
	host.leaving = true
	SceneRouter.go_to(VillageLayout3D.SCENE)


## Down into the thúng: the night at sea.
static func to_sea(host: VillageScene3D) -> void:
	host.leaving = true
	SceneRouter.go_to(SEA)


## The sea's trip end (SeaTrip3D): back to the pier at night.
static func back_from_sea() -> void:
	GameState.set_flag(NIGHT_FLAG)
	SceneRouter.go_to(VillageLayout3D.SCENE)


## Called from _ready while the fade into the village is still running.
static func go_to_ending(host: Node) -> void:
	while SceneRouter._is_transitioning:
		await host.get_tree().process_frame
	SceneRouter.go_to(RamEpilogue3D.SCENE)


## Rằm went by with nothing found: over the wake's black screen, the gate closes.
static func gate_closed(host: Node) -> void:
	var over := OnScreenText.new()
	host.add_child(over)
	over.layer = 31
	Sfx.play("whisper", 0.0)
	await RamFx3D.say_lines(over, RamFx3D.LINES.gate_closed, 1.5)
	over.queue_free()
