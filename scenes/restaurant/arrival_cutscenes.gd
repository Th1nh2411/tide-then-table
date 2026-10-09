class_name ArrivalCutscenes
extends RefCounted
## Story scenes on arriving at the restaurant, before the menu (opening day,
## beer on day 2, Vy on day 3...): the highest-priority eligible one plays,
## once. The Vy scene can hire her on the spot (flag "vy_hire_now").

const HIRE_VY_FLAG := "vy_hire_now"


## Plays one if any is due (await it). Returns a message to show, or "".
static func play(player: CutscenePlayer, cutscenes: Array[Cutscene], roster: StaffRoster) -> String:
	var scene := DialogueLibrary.pick(cutscenes) as Cutscene
	if scene == null:
		return ""
	await player.play(scene)
	if not GameState.story_flags.has(HIRE_VY_FLAG):
		return ""
	GameState.story_flags.erase(HIRE_VY_FLAG)
	var vy := roster.catalog.find("vy")
	return "Vy vào làm từ hôm nay!" if vy and roster.hire(vy) else ""
