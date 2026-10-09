class_name SaveSystem
extends RefCounted
## Saves/loads GameState as JSON. Saved at the start of every night trip
## (resume at sea) and on the rest card after it (resume at the restaurant).
## Loading is defensive: a missing or wrongly typed field falls back to the
## fresh-game value instead of crashing, and unknown fish are skipped.
## `path` parameters exist so tests can use a scratch file.

const SAVE_PATH: String = "user://save.json"
## 2: + orders, map pins, weather, resume point (older saves load fine).
const SAVE_VERSION: int = 2
const RESUME_POINTS: Array[String] = ["sea", "restaurant"]
const FISH_CATALOG_PATH: String = "res://data/fish/fish_catalog.tres"


static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


static func delete_save(path: String = SAVE_PATH) -> void:
	if has_save(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Autosave unless the run was started with `-- --no-autosave` (tests).
## `resume_at`: where Continue will start ("sea" or "restaurant").
static func autosave(resume_at: String) -> void:
	GameState.resume_at = resume_at
	if not OS.get_cmdline_user_args().has("--no-autosave"):
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
		"best_sizes": GameState.best_sizes.duplicate(),
		"pantry": GameState.pantry.duplicate(),
		"staff": GameState.staff.duplicate(true),
		"day_history": GameState.day_history.duplicate(true),
		"orders": GameState.orders.duplicate(true),
		"weather_id": GameState.weather_id,
		"resume_at": GameState.resume_at,
		"map_pins": GameState.map_pins.map(func(pin: Vector2) -> Array: return [pin.x, pin.y]),
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

	var sizes: Variant = data.get("best_sizes")
	if sizes is Dictionary:
		for fish_id: Variant in sizes:
			if fish_id is String and (sizes[fish_id] is int or sizes[fish_id] is float):
				GameState.best_sizes[fish_id] = clampf(float(sizes[fish_id]), 0.0, CatchRoll.STORED_MAX)

	var pantry: Variant = data.get("pantry")
	if pantry is Dictionary:
		for dish_id: Variant in pantry:
			if dish_id is String and (pantry[dish_id] is int or pantry[dish_id] is float):
				GameState.pantry[dish_id] = maxi(int(pantry[dish_id]), 0)

	var staff: Variant = data.get("staff")
	if staff is Dictionary:
		for key: String in ["hired", "candidates", "seen"]:
			var ids: Variant = staff.get(key)
			if ids is Array:
				GameState.staff[key] = ids.filter(func(id: Variant) -> bool: return id is String)
		var ad_day: Variant = staff.get("ad_day")
		if ad_day is int or ad_day is float:
			GameState.staff["ad_day"] = int(ad_day)

	var history: Variant = data.get("day_history")
	if history is Array:
		for entry: Variant in history:
			if entry is Dictionary:
				GameState.add_day_record(entry)

	var saved_orders: Variant = data.get("orders")
	if saved_orders is Array:
		for entry: Variant in saved_orders:
			var order := FishOrders.from_save(entry, catalog)
			if not order.is_empty():
				GameState.orders.append(order)

	var resume: Variant = data.get("resume_at")
	if resume is String and RESUME_POINTS.has(resume):
		GameState.resume_at = resume

	var weather: Variant = data.get("weather_id")
	if weather is String:
		GameState.weather_id = weather

	var pins: Variant = data.get("map_pins")
	if pins is Array:
		for entry: Variant in pins:
			if entry is Array and entry.size() == 2 and _is_number(entry[0]) and _is_number(entry[1]) \
					and GameState.map_pins.size() < GameState.MAX_PINS:
				GameState.map_pins.append(Vector2(float(entry[0]), float(entry[1])))

	var flags: Variant = data.get("story_flags")
	if flags is Dictionary:
		for flag_name: Variant in flags:
			if flag_name is String:
				GameState.story_flags[flag_name] = flags[flag_name]


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


## JSON numbers come back as floats; accept int or float, else the fallback.
static func _get_int(data: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = data.get(key)
	return int(value) if value is int or value is float else fallback
