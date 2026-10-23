class_name StoryTimeline
extends RefCounted
## Debug jumps (DebugJumpMenu, F9): when each cutscene normally plays, and a
## fresh game set up as if the story had run up to a given day + moment
## (every earlier cutscene watched, its flags set, the omen on day 4).

enum Slot { INTRO, SEA, ARRIVAL, AFTER_SHIFT }

const CUTSCENE_DIR: String = "res://data/cutscenes/"
const RESTAURANT_SCENE: String = "res://scenes/restaurant/restaurant_scene.tscn"
const SCENES: Dictionary = {
	Slot.INTRO: "res://scenes/intro/intro_scene.tscn",
	Slot.SEA: "res://scenes/sea/sea_scene.tscn",
	Slot.ARRIVAL: RESTAURANT_SCENE,
	Slot.AFTER_SHIFT: RESTAURANT_SCENE,
}
const SLOT_NAMES: Dictionary = {
	Slot.INTRO: "mở đầu",
	Slot.SEA: "đêm (biển)",
	Slot.ARRIVAL: "tới quán",
	Slot.AFTER_SHIFT: "sau ca",
}
## Cutscene id -> [day, Slot] in a normal run (see PLAN.md story timeline).
## Unlisted ones fall back to [min_day, AFTER_SHIFT].
const WHEN: Dictionary = {
	"intro_call": [1, Slot.INTRO],
	"opening_day": [1, Slot.ARRIVAL],
	"beer_day": [1, Slot.AFTER_SHIFT],
	"cat_arrival": [2, Slot.SEA],
	"regular_thanks": [2, Slot.AFTER_SHIFT],
	"wave_faint": [3, Slot.SEA],
	"wave_awaken": [3, Slot.ARRIVAL],
	"nam_fog_tale": [3, Slot.AFTER_SHIFT],
	"fog_omen": [4, Slot.SEA],
	"vy_arrives": [4, Slot.ARRIVAL],
	"vy_stands_up": [4, Slot.AFTER_SHIFT],
}
## Flags a skipped cutscene must not leave behind (a choice the player
## didn't make: hiring Vy).
const SKIPPED_FLAGS: Array[String] = ["vy_hire_now"]


## Every cutscene in CUTSCENE_DIR, in story order.
static func load_all() -> Array[Cutscene]:
	var list: Array[Cutscene] = []
	for file in DirAccess.get_files_at(CUTSCENE_DIR):
		file = file.trim_suffix(".remap")  # exported builds
		if file.ends_with(".tres"):
			var cutscene := load(CUTSCENE_DIR + file) as Cutscene
			if cutscene:
				list.append(cutscene)
	list.sort_custom(func(a: Cutscene, b: Cutscene) -> bool: return _before(when(a), when(b)))
	return list


## [day, Slot] the cutscene plays at.
static func when(cutscene: Cutscene) -> Array:
	var fallback: Array = [maxi(cutscene.min_day, 1), Slot.AFTER_SHIFT]
	return WHEN.get(cutscene.id, fallback)


## Fresh game at `day` / `slot`: everything that plays earlier is watched.
## Returns the scene to go to.
static func prepare(day: int, slot: Slot) -> String:
	GameState.reset()
	GameState.day = day
	var now: Array = [day, slot]
	for cutscene in load_all():
		if _before(when(cutscene), now):
			watch(cutscene)
	if not _before(now, [Story.OMEN_DAY, Slot.SEA]):
		GameState.set_flag(Story.OMEN_DAY_FLAG, Story.OMEN_DAY)
	return SCENES[slot]


## prepare() for this cutscene's moment, plus whatever it requires.
static func prepare_for(cutscene: Cutscene) -> String:
	var at := when(cutscene)
	var path := prepare(at[0], at[1])
	if cutscene.requires_flag and not GameState.has_flag(cutscene.requires_flag):
		GameState.set_flag(cutscene.requires_flag)
	return path


## Marks a cutscene seen with the flags its script sets (main branch).
static func watch(cutscene: Cutscene) -> void:
	if cutscene.requires_flag and not GameState.has_flag(cutscene.requires_flag):
		GameState.set_flag(cutscene.requires_flag)
	for command in CutsceneScript.parse(cutscene.script_text):
		var args: PackedStringArray = command["args"]
		if command["cmd"] == "set_flag" and not args.is_empty() and not SKIPPED_FLAGS.has(args[0]):
			GameState.set_flag(args[0])
	DialogueLibrary.mark_done(cutscene)


## Whether the cutscene is played by the scene itself on arrival (intro,
## restaurant arrival); the others are played by the debug menu.
static func plays_by_itself(cutscene: Cutscene) -> bool:
	var slot: Slot = when(cutscene)[1]
	return slot == Slot.INTRO or slot == Slot.ARRIVAL


static func _before(a: Array, b: Array) -> bool:
	return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])
