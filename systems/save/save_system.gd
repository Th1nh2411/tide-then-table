class_name SaveSystem
extends RefCounted
## Saves/loads GameState as JSON. Saved at the start of every sea day.
## Loading is defensive: a missing or wrongly typed field falls back to the
## fresh-game value instead of crashing, and unknown fish are skipped.
## `path` parameters exist so tests can use a scratch file.

const SAVE_PATH: String = "user://save.json"
const SAVE_VERSION: int = 1
const FISH_CATALOG_PATH: String = "res://data/fish/fish_catalog.tres"


static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func delete_save(path: String = SAVE_PATH) -> void:
	if has_save(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
	var items: Array = []
	for item: InventoryItem in GameState.storage:
		items.append(item.to_dict())
	return {
		"version": SAVE_VERSION,
		"money": GameState.money,
		"day": GameState.day,
		"storage": items,
		"upgrade_levels": GameState.upgrade_levels.duplicate(),
		"story_flags": GameState.story_flags.duplicate(),
		"last_rating": GameState.last_rating,
		"boat_hp": GameState.boat_hp,
		"caught_species": GameState.caught_species.duplicate(),
		"day_history": GameState.day_history.duplicate(true),
	}


## Applies save data on top of the current (freshly reset) GameState.
static func apply_dict(data: Dictionary) -> void:
	GameState.money = maxi(_get_int(data, "money", GameState.money), 0)
	GameState.day = maxi(_get_int(data, "day", GameState.day), 1)
	GameState.last_rating = clampi(_get_int(data, "last_rating", GameState.last_rating), 1, 5)
	var hp: Variant = data.get("boat_hp")
	if hp is float or hp is int:
		GameState.boat_hp = clampf(float(hp), 0.0, BoatCondition.MAX_HP)

	var catalog: FishCatalog = load(FISH_CATALOG_PATH)
	var saved_storage: Variant = data.get("storage")
	if saved_storage is Array:
		for entry: Variant in saved_storage:
			var item := InventoryItem.from_dict(entry, catalog)
			if item:
				GameState.storage.append(item)

	var levels: Variant = data.get("upgrade_levels")
	if levels is Dictionary:
		for upgrade_id: Variant in levels:
			if upgrade_id is String and (levels[upgrade_id] is int or levels[upgrade_id] is float):
				GameState.upgrade_levels[upgrade_id] = maxi(int(levels[upgrade_id]), 0)

	var caught: Variant = data.get("caught_species")
	if caught is Dictionary:
		for fish_id: Variant in caught:
			if fish_id is String and (caught[fish_id] is int or caught[fish_id] is float):
				GameState.caught_species[fish_id] = maxi(int(caught[fish_id]), 0)

	var history: Variant = data.get("day_history")
	if history is Array:
		for entry: Variant in history:
			if entry is Dictionary:
				GameState.add_day_record(entry)

	var flags: Variant = data.get("story_flags")
	if flags is Dictionary:
		for flag_name: Variant in flags:
			if flag_name is String:
				GameState.story_flags[flag_name] = flags[flag_name]


## JSON numbers come back as floats; accept int or float, else the fallback.
static func _get_int(data: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = data.get(key)
	return int(value) if value is int or value is float else fallback
