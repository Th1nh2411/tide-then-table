class_name SaveSystem
extends RefCounted
## Saves/loads GameState as JSON. Saved each morning only (horror build).
## Loading is defensive: a missing or wrongly typed field falls back to the
## fresh-game value instead of crashing. Fields of older saves (money,
## upgrades, storage, orders, pantry, staff, stats, social, weather, map pins)
## are ignored.
## `path` parameters exist so tests can use a scratch file.

const SAVE_PATH: String = "user://save.json"
## 3: horror build, no money / upgrades / storage / orders / staff / social /
## weather / map pins.
const SAVE_VERSION: int = 3
const RESUME_POINTS: Array[String] = ["sea", "restaurant", "home"]


static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func delete_save(path: String = SAVE_PATH) -> void:
	if has_save(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Off for the rest of the session (tests, bots), so a
## made-up state never overwrites the real save.
static var autosave_off: bool = false


## Autosave unless the run was started with `-- --no-autosave` (tests).
## `resume_at`: where Continue will start ("home" in the horror build; "sea" / "restaurant" older saves).
static func autosave(resume_at: String) -> void:
	GameState.resume_at = resume_at
	if not autosave_off and not OS.get_cmdline_user_args().has("--no-autosave"):
		save_game()


static func save_game(path: String = SAVE_PATH) -> bool:
	# Write to a temp file first, then swap it in, so a crash mid-write
	# can't leave a half-written save behind.
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Save failed: %s" % error_string(error))
		return false
	return true


## Resets GameState and fills it from the save. Returns false (GameState left
## as a fresh game) if the file is missing or not valid JSON.
static func load_game(path: String = SAVE_PATH) -> bool:
	GameState.reset()
	if not has_save(path):
		return false
	# JSON.new().parse reports errors via its return value instead of
	# printing engine errors, which suits an expected "corrupted file" case.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		push_warning("Save file is corrupted: %s" % path)
		return false
	apply_dict(json.data)
	return true


static func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"day": GameState.day,
		"story_flags": GameState.story_flags.duplicate(),
		"last_rating": GameState.last_rating,
		"boat_hp": GameState.boat_hp,
		"caught_species": GameState.caught_species.duplicate(),
		"best_sizes": GameState.best_sizes.duplicate(),
		"day_history": GameState.day_history.duplicate(true),
		"resume_at": GameState.resume_at,
		"play_seconds": GameState.play_seconds,
	}


## Applies save data on top of the current (freshly reset) GameState.
static func apply_dict(data: Dictionary) -> void:
	GameState.day = maxi(_get_int(data, "day", GameState.day), 1)
	GameState.last_rating = clampi(_get_int(data, "last_rating", GameState.last_rating), 1, 5)
	var played: Variant = data.get("play_seconds")
	if _is_number(played):
		GameState.play_seconds = maxf(float(played), 0.0)
	var hp: Variant = data.get("boat_hp")
	if hp is float or hp is int:
		GameState.boat_hp = clampf(float(hp), 0.0, BoatCondition.MAX_HP)

	var caught: Variant = data.get("caught_species")
	if caught is Dictionary:
		for fish_id: Variant in caught:
			if fish_id is String and (caught[fish_id] is int or caught[fish_id] is float):
				GameState.caught_species[fish_id] = maxi(int(caught[fish_id]), 0)

	var sizes: Variant = data.get("best_sizes")
	if sizes is Dictionary:
		for fish_id: Variant in sizes:
			if fish_id is String and (sizes[fish_id] is int or sizes[fish_id] is float):
				GameState.best_sizes[fish_id] = clampf(float(sizes[fish_id]), 0.0, CatchRoll.STORED_MAX)

	var history: Variant = data.get("day_history")
	if history is Array:
		for entry: Variant in history:
			if entry is Dictionary:
				var record: Dictionary = {}
				for key: Variant in entry:
					record[key] = _whole(entry[key])
				GameState.add_day_record(record)

	var resume: Variant = data.get("resume_at")
	if resume is String and RESUME_POINTS.has(resume):
		GameState.resume_at = resume

	var flags: Variant = data.get("story_flags")
	if flags is Dictionary:
		for flag_name: Variant in flags:
			if flag_name is String:
				GameState.story_flags[flag_name] = _whole(flags[flag_name])


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


## JSON gives every number back as a float: 4.0 -> 4, 0.5 stays.
static func _whole(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, roundf(value)) and absf(value) < 1e15:
		return int(value)
	return value


## JSON numbers come back as floats; accept int or float, else the fallback.
static func _get_int(data: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = data.get(key)
	return int(value) if value is int or value is float else fallback
