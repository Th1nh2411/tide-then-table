class_name OmenPicker
extends RefCounted
## Picks tonight's omen (pure, PLAN §10 H5): at most one per night, none on
## the first or the last night, never the same omen two nights running,
## obvious ones only on early days (OmenCatalog.allowed: subtlety).
## Deterministic per (loop count, day): the same day of the same loop always
## gets the same omen, so reloads, tests and the bot agree. Stored as story
## flags: LoopCalendar.OMEN_FLAG (judged when Rin wakes) + ID_FLAG.

const ID_FLAG := "omen_id"
const CATALOG: OmenCatalog = preload("res://data/omens/omen_catalog.tres")
const SALT := "xom_den_omen"


## Tonight's omen id for this loop and day ("" = a calm night).
static func pick(catalog: OmenCatalog, loop: int, day: int) -> String:
	var previous := ""
	for d: int in range(1, day + 1):
		previous = _roll(catalog, loop, d, previous)
	return previous


static func _roll(catalog: OmenCatalog, loop: int, day: int, previous: String) -> String:
	if day < catalog.first_day or day > catalog.last_day:
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SALT, loop, day])
	if rng.randf() >= catalog.chance:
		return ""
	var choices: Array[OmenData] = []
	var total := 0.0
	for omen in catalog.omens:
		if omen.id != previous and omen.weight > 0.0 and catalog.allowed(omen, day):
			choices.append(omen)
			total += omen.weight
	var at := rng.randf() * total
	for omen in choices:
		at -= omen.weight
		if at < 0.0:
			return omen.id
	return choices.back().id if not choices.is_empty() else ""


## Called when a day starts (village morning): sets or clears tonight's flags.
static func start_day(catalog: OmenCatalog = CATALOG) -> void:
	var id := pick(catalog, LoopCalendar.loops(), GameState.day)
	if id == "":
		GameState.story_flags.erase(ID_FLAG)
		GameState.story_flags.erase(LoopCalendar.OMEN_FLAG)
	else:
		GameState.set_flag(ID_FLAG, id)
		GameState.set_flag(LoopCalendar.OMEN_FLAG)


## Tonight's omen, or null on a calm night.
static func tonight(catalog: OmenCatalog = CATALOG) -> OmenData:
	if not GameState.has_flag(LoopCalendar.OMEN_FLAG):
		return null
	return catalog.find(str(GameState.story_flags.get(ID_FLAG, "")))


static func is_tonight(id: String) -> bool:
	var omen := tonight()
	return omen != null and omen.id == id


## False omens: ids of the custom omens whose normal (eerie but right) state
## shows tonight. Never tonight's omen (that one shows its wrong state).
static func customs(catalog: OmenCatalog, loop: int, day: int) -> Array[String]:
	var omen_id := pick(catalog, loop, day)
	var pool: Array[String] = []
	for omen in catalog.omens:
		if omen.custom and omen.id != omen_id:
			pool.append(omen.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SALT, "customs", loop, day])
	var count := rng.randi_range(catalog.customs_min, catalog.customs_max)
	if omen_id != "":
		count = catalog.customs_on_omen_night
	var shown: Array[String] = []
	while shown.size() < count and not pool.is_empty():
		shown.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return shown


## Tonight's state of one omen entry: "omen", "normal" or "" (not shown).
static func state(id: String, catalog: OmenCatalog = CATALOG) -> String:
	if is_tonight(id):
		return "omen"
	var omen := catalog.find(id)
	if omen == null or not omen.custom:
		return "normal"
	return "normal" if customs(catalog, LoopCalendar.loops(), GameState.day).has(id) else ""
