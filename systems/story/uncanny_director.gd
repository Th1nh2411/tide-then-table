class_name UncannyDirector
extends RefCounted
## Which "uncanny" visuals may play tonight (pure). Deterministic per
## (loop, day) like OmenPicker, so reloads / tests / the bot agree. Dose
## (UncannyDose): mùng 9-10 only moved props / unseen tricks, from 11 small
## sights, from 12 wrong movement, 13-14 the heavy ones (appear beside Rin,
## dash, one-frame flash), never more than one heavy per night. Never
## touches omens: OmenPicker alone decides which nights are wrong.
## Jump scares are gated here too: never two on consecutive days.

const DOSE: UncannyDose = preload("res://data/story/uncanny_dose.tres")
const SALT := "xom_den_uncanny"
## Day of the last jump scare this loop (normal flag: cleared on reset).
const SCARE_DAY_FLAG := "uncanny_scare_day"
## Kept through resets (note_ prefix): once per playthrough.
const TU_FLAG := "note_scare_tu"
const FAKE_FLAG := "note_scare_fake"
## Set when this loop's subtitle trick played (cleared on reset).
const SUBTITLE_FLAG := "uncanny_subtitle"
const SUBTITLE_KINDS: Array[String] = ["repeat", "wrong_name", "extra"]
const HEAVY: Array[String] = ["appear_close", "dash", "flash"]
## Light effects that may also play on an omen night (wrong movement only).
const OMEN_NIGHT_LIGHT: Array[String] = ["stare", "freeze", "choppy", "wrong_walk", "door_closed"]


## Tonight's plan: {"light": Array[String] (may repeat), "heavy": String
## ("" = none), "subtitle": String ("" = none), "ut_cues": bool}.
static func plan(loop: int, day: int, omen: bool, dose: UncannyDose = DOSE) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SALT, loop, day])
	var light: Array[String] = []
	var pool := allowed_light(day, dose)
	var count := mini(dose.light_base + int(dose.light_per_day * float(day - 1)), dose.light_cap)
	for i in (count if not pool.is_empty() else 0):
		light.append(pool[rng.randi() % pool.size()])
	var heavy := ""
	var heavies := allowed_heavy(day, dose)
	if not heavies.is_empty() and rng.randf() < dose.heavy_chance:
		heavy = heavies[rng.randi() % heavies.size()]
	var subtitle := ""
	if day in dose.subtitle_days and day == subtitle_day(loop, dose):
		subtitle = SUBTITLE_KINDS[rng.randi() % SUBTITLE_KINDS.size()]
	# Omen nights keep their own haunting; the doubt tricks are for calm nights
	# and the omen nights only get the movement (the warnings).
	if omen:
		var kept: Array[String] = []
		for id in light:
			if id in OMEN_NIGHT_LIGHT:
				kept.append(id)
		light = kept
	return {"light": light, "heavy": heavy, "subtitle": subtitle,
		"ut_cues": day >= dose.ut_cues_from_day}


static func allowed_light(day: int, dose: UncannyDose = DOSE) -> Array[String]:
	var ids: Array[String] = []
	for id: String in dose.light_from_day:
		if day >= int(dose.light_from_day[id]):
			ids.append(id)
	ids.sort()
	return ids


static func allowed_heavy(day: int, dose: UncannyDose = DOSE) -> Array[String]:
	var ids: Array[String] = []
	if day > dose.heavy_last_day:
		return ids
	for id: String in dose.heavy_from_day:
		if day >= int(dose.heavy_from_day[id]):
			ids.append(id)
	ids.sort()
	return ids


## The one day of this loop the subtitle trick plays.
static func subtitle_day(loop: int, dose: UncannyDose = DOSE) -> int:
	if dose.subtitle_days.is_empty():
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SALT, "subtitle", loop])
	return dose.subtitle_days[rng.randi() % dose.subtitle_days.size()]


## Tonight's plan from GameState.
static func tonight() -> Dictionary:
	return plan(LoopCalendar.loops(), GameState.day, GameState.has_flag(LoopCalendar.OMEN_FLAG))


static func has(plan_: Dictionary, id: String) -> bool:
	return plan_.get("heavy", "") == id or (plan_.get("light", []) as Array).has(id)


# --- Jump scares ---

## No scare yesterday (or earlier today) in this loop.
static func scare_allowed(day: int = -1) -> bool:
	var d := GameState.day if day < 0 else day
	var last := int(GameState.story_flags.get(SCARE_DAY_FLAG, -10))
	return last != d - 1 and last != d


static func mark_scare(day: int = -1) -> void:
	GameState.set_flag(SCARE_DAY_FLAG, GameState.day if day < 0 else day)


## Ông Tư behind Rin: once per playthrough, on its day.
static func tu_scare_due(day: int = -1, dose: UncannyDose = DOSE) -> bool:
	var d := GameState.day if day < 0 else day
	return d == dose.tu_scare_day and not GameState.has_flag(TU_FLAG) and scare_allowed(d)


## The calm day of this loop the fake scare may play (2 or 3).
static func fake_scare_day(loop: int, dose: UncannyDose = DOSE) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SALT, "fake", loop])
	return dose.fake_scare_days[rng.randi() % dose.fake_scare_days.size()]


static func fake_scare_due(dose: UncannyDose = DOSE) -> bool:
	return not GameState.has_flag(LoopCalendar.OMEN_FLAG) and not GameState.has_flag(FAKE_FLAG) \
		and GameState.day == fake_scare_day(LoopCalendar.loops(), dose) and scare_allowed()


## Which face fills the view when the sea takes Rin (by reset count).
static func wrong_night_variant(loops: int, dose: UncannyDose = DOSE) -> int:
	return posmod(loops, maxi(dose.wrong_night_variants, 1))


## The subtitle trick of this loop may still play.
static func subtitle_due(plan_: Dictionary) -> bool:
	return str(plan_.get("subtitle", "")) != "" and not GameState.has_flag(SUBTITLE_FLAG)
