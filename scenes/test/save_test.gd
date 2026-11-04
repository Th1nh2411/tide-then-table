extends Control
## Standalone test for SaveSystem (run with F6). Uses a scratch file, so the
## real save is never touched. Checks round-trip, broken/missing data and old saves.

const TEST_PATH: String = "user://save_test.json"

@export var fish_catalog: FishCatalog

var _failures: int = 0
var _log: PackedStringArray = []

@onready var _result_label: Label = %ResultLabel


func _ready() -> void:
	_test_round_trip()
	_test_missing_fields()
	_test_wrong_types()
	_test_old_save_fields_ignored()
	_test_corrupted_and_missing_file()
	SaveSystem.delete_save(TEST_PATH)
	GameState.reset()
	_log.insert(0, "SaveSystem: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))
	_result_label.text = "\n".join(_log)


func _test_round_trip() -> void:
	GameState.reset()
	GameState.day = 6
	GameState.last_rating = 4
	GameState.story_flags = {"saw_glowing_fish": true, "fog_omen_day": 4}
	GameState.record_catch(_fish("cua"), 3, 1.4)
	GameState.resume_at = "home"
	GameState.play_seconds = 1800.5
	GameState.add_day_record({"day": 5, "earned": 300, "rating": 4, "served": 9})
	_check("save writes file", SaveSystem.save_game(TEST_PATH) and SaveSystem.has_save(TEST_PATH))
	GameState.reset()
	_check("load ok", SaveSystem.load_game(TEST_PATH))
	_check("day", GameState.day == 6)
	_check("rating", GameState.last_rating == 4)
	_check("story flag", GameState.has_flag("saw_glowing_fish"))
	_check("dex counts", int(GameState.caught_species.get("cua", 0)) == 3)
	_check("resume point", GameState.resume_at == "home")
	_check("play time", is_equal_approx(GameState.play_seconds, 1800.5))
	var stats := EndingStats.lines(7)
	_check("ending stats: 3 lines, days + minutes", stats.size() == 3 and stats[0] == "6 ngày · 30 phút")
	_check("ending stats: catch + earnings", stats[1] == "3 con cá · 1/7 loài" and stats[2].contains("300k"))
	_check("size record", is_equal_approx(GameState.best_size(_fish("cua")), 1.4))
	_check("day history", GameState.day_history.size() == 1 and int(GameState.day_history[0].get("earned", 0)) == 300)
	_check("whole numbers stay ints (JSON floats)", GameState.day_history[0].get("earned") is int
		and GameState.story_flags.get("fog_omen_day") is int)
	var data := SaveSystem.to_dict()
	_check("no money / upgrades / storage in the save", not data.has("money") and not data.has("upgrade_levels")
		and not data.has("storage") and not data.has("orders") and not data.has("staff") and not data.has("social")
		and not data.has("boat_hp"))


func _test_missing_fields() -> void:
	_write('{"day": 3}')
	_check("missing fields still load", SaveSystem.load_game(TEST_PATH))
	_check("missing -> defaults", GameState.day == 3 and GameState.last_rating == GameState.STARTING_RATING
		and GameState.caught_species.is_empty() and GameState.resume_at == "home")


func _test_wrong_types() -> void:
	_write('{"day": -3, "caught_species": "x", "story_flags": 7, "last_rating": 99, "resume_at": "moon", "boat_hp": 500}')
	_check("wrong types still load", SaveSystem.load_game(TEST_PATH))
	_check("negative day -> 1", GameState.day == 1)
	_check("bad resume -> home", GameState.resume_at == "home")
	_check("rating clamped", GameState.last_rating == 5)
	_check("old hull field ignored", not "boat_hp" in GameState)
	_check("bad containers ignored", GameState.caught_species.is_empty() and GameState.story_flags.is_empty())


## A save from the cozy build (money, upgrades, storage...) still loads.
func _test_old_save_fields_ignored() -> void:
	_write('{"version": 2, "money": 999, "day": 4, "upgrade_levels": {"boat": 2}, "storage": [{"fish": "cua"}], "orders": [1], "pantry": {"bia_con_meo": 3}, "staff": {"hired": ["vy"]}, "stats": {}, "social": {}}')
	_check("old save loads", SaveSystem.load_game(TEST_PATH))
	_check("old save keeps the day only", GameState.day == 4 and not SaveSystem.to_dict().has("money"))


func _test_corrupted_and_missing_file() -> void:
	_write("not json {{")
	GameState.day = 5
	_check("corrupted file -> false", not SaveSystem.load_game(TEST_PATH))
	_check("corrupted file -> fresh game", GameState.day == GameState.STARTING_DAY)
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
