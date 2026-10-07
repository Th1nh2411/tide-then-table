extends Control
## Standalone test for SaveSystem (run with F6). Uses a scratch file, so the
## real save is never touched. Checks round-trip and broken/missing data.

const TEST_PATH: String = "user://save_test.json"

@export var fish_catalog: FishCatalog

var _failures: int = 0
var _log: PackedStringArray = []

@onready var _result_label: Label = %ResultLabel


func _ready() -> void:
	_test_round_trip()
	_test_missing_fields()
	_test_wrong_types()
	_test_bad_storage_entries()
	_test_corrupted_and_missing_file()
	SaveSystem.delete_save(TEST_PATH)
	GameState.reset()
	_log.insert(0, "SaveSystem: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))
	_result_label.text = "\n".join(_log)


func _test_round_trip() -> void:
	GameState.reset()
	GameState.money = 1234
	GameState.day = 6
	GameState.last_rating = 4
	GameState.upgrade_levels = {"boat": 2, "rod": 1}
	GameState.story_flags = {"saw_glowing_fish": true}
	var item := InventoryItem.new(_fish("cua"), 0.7)
	item.freshness = 65.0
	GameState.storage.append(item)
	GameState.record_catch(_fish("cua"), 3, 1.4)
	item.size = 1.25
	GameState.add_day_record({"day": 5, "earned": 300, "market": 20, "rating": 4})
	_check("save writes file", SaveSystem.save_game(TEST_PATH) and SaveSystem.has_save(TEST_PATH))
	GameState.reset()
	_check("load ok", SaveSystem.load_game(TEST_PATH))
	_check("money", GameState.money == 1234)
	_check("day", GameState.day == 6)
	_check("rating", GameState.last_rating == 4)
	_check("upgrades", GameState.get_upgrade_level("boat") == 2 and GameState.get_upgrade_level("rod") == 1)
	_check("story flag", GameState.has_flag("saw_glowing_fish"))
	_check("dex counts", int(GameState.caught_species.get("cua", 0)) == 3)
	_check("size record", is_equal_approx(GameState.best_size(_fish("cua")), 1.4))
	_check("item size", GameState.storage.size() == 1 and is_equal_approx(GameState.storage[0].size, 1.25))
	_check("day history", GameState.day_history.size() == 1 and int(GameState.day_history[0].get("earned", 0)) == 300)
	var loaded: InventoryItem = GameState.storage[0] if GameState.storage.size() == 1 else null
	_check("storage item", loaded != null and loaded.fish.id == "cua"
		and is_equal_approx(loaded.quality, 0.7) and is_equal_approx(loaded.freshness, 65.0))


func _test_missing_fields() -> void:
	_write('{"money": 500}')
	_check("missing fields still load", SaveSystem.load_game(TEST_PATH))
	_check("missing -> defaults", GameState.money == 500 and GameState.day == 1
		and GameState.storage.is_empty() and GameState.upgrade_levels.is_empty())


func _test_wrong_types() -> void:
	_write('{"money": "abc", "day": -3, "storage": "x", "upgrade_levels": [1, 2], "story_flags": 7, "last_rating": 99}')
	_check("wrong types still load", SaveSystem.load_game(TEST_PATH))
	_check("bad money -> default", GameState.money == GameState.STARTING_MONEY)
	_check("negative day -> 1", GameState.day == 1)
	_check("rating clamped", GameState.last_rating == 5)
	_check("bad containers ignored", GameState.storage.is_empty() and GameState.upgrade_levels.is_empty()
		and GameState.story_flags.is_empty())


func _test_bad_storage_entries() -> void:
	_write('{"storage": [{"fish": "ca_rong"}, 5, {"fish": "cua", "quality": "x", "freshness": 500}]}')
	SaveSystem.load_game(TEST_PATH)
	var only: InventoryItem = GameState.storage[0] if GameState.storage.size() == 1 else null
	_check("unknown fish + junk skipped, bad numbers fixed", only != null and only.fish.id == "cua"
		and only.quality == 1.0 and only.freshness == 100.0)


func _test_corrupted_and_missing_file() -> void:
	_write("not json {{")
	GameState.money = 999
	_check("corrupted file -> false", not SaveSystem.load_game(TEST_PATH))
	_check("corrupted file -> fresh game", GameState.money == GameState.STARTING_MONEY)
	SaveSystem.delete_save(TEST_PATH)
	_check("no file -> false", not SaveSystem.load_game(TEST_PATH))


func _write(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	var line := "%s  %s" % ["PASS" if ok else "FAIL", label]
	print(line)
	_log.append(line)


func _fish(id: String) -> FishData:
	for f in fish_catalog.fish:
		if f.id == id:
			return f
	return null
