extends Node
## Standalone test for StoryTimeline (debug jumps, F9): cutscene order, the
## state rebuilt for a day / moment, and that the restaurant then picks the
## right arrival cutscene by itself.

var _failures: int = 0


func _ready() -> void:
	var all := StoryTimeline.load_all()
	var ids: Array[String] = []
	for cutscene in all:
		ids.append(cutscene.id)
	_check("loads every cutscene, intro first", all.size() >= 11 and ids[0] == "intro_call")
	var unlisted := ids.filter(func(id: String) -> bool: return not StoryTimeline.WHEN.has(id))
	_check("every cutscene has a moment in WHEN %s" % [unlisted], unlisted.is_empty())
	var arrivals: Array[Cutscene] = []
	for id in ["opening_day", "vy_arrives", "wave_awaken"]:
		arrivals.append(load(StoryTimeline.CUTSCENE_DIR + id + ".tres") as Cutscene)

	_check("night 3 -> sea scene", StoryTimeline.prepare(3, StoryTimeline.Slot.SEA) == StoryTimeline.SCENES[StoryTimeline.Slot.SEA])
	_check("night 3: day set, cat adopted, beer seen", GameState.day == 3 and GameState.has_flag("cat_adopted")
		and GameState.has_flag(DialogueLibrary.SEEN_PREFIX + "beer_day"))
	_check("night 3: not fainted yet, no omen", not GameState.has_flag("wave_fainted")
		and not GameState.has_flag(Story.OMEN_DAY_FLAG))

	StoryTimeline.prepare(3, StoryTimeline.Slot.ARRIVAL)
	_check("day 3 at the restaurant: fainted, picks wave_awaken", GameState.has_flag("wave_fainted")
		and DialogueLibrary.pick(arrivals).id == "wave_awaken")

	StoryTimeline.prepare(4, StoryTimeline.Slot.ARRIVAL)
	_check("day 4: omen on day 4, power, picks vy_arrives", int(GameState.story_flags.get(Story.OMEN_DAY_FLAG, 0)) == 4
		and WaveMark.has_power() and DialogueLibrary.pick(arrivals).id == "vy_arrives")

	StoryTimeline.prepare(5, StoryTimeline.Slot.SEA)
	_check("night 5: fog open, Vy not hired by a skipped choice", Story.is_fog_open()
		and not GameState.has_flag("vy_hire_now") and GameState.staff.is_empty())
	_check("night 5: no arrival cutscene left", DialogueLibrary.pick(arrivals) == null)

	var thanks := load(StoryTimeline.CUTSCENE_DIR + "regular_thanks.tres") as Cutscene
	StoryTimeline.prepare_for(thanks)
	_check("prepare_for: requirement met, not seen yet", DialogueLibrary.can_play(thanks))

	GameState.reset()
	print("story_timeline_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
