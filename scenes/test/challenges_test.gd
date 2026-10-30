extends Node
## Standalone test (F6) for daily challenges, achievements and lifetime stats:
## deterministic + possible rolls, progress from a ShiftLog, rewards paid
## once, achievements unlock once, stats survive a save round trip.

const CHALLENGES: ChallengeCatalog = preload("res://data/challenges/challenge_catalog.tres")
const ACHIEVEMENTS: AchievementCatalog = preload("res://data/achievements/achievement_catalog.tres")

var _failures := 0


func _ready() -> void:
	_test_catalogs()
	_test_roll()
	_test_saved_picks()
	_test_progress()
	_test_settle_once()
	_test_achievements()
	_test_stats_save()
	_test_icon_art()
	GameState.reset()
	print("challenges_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _test_catalogs() -> void:
	var ids: Dictionary = {}
	for challenge in CHALLENGES.challenges:
		ids[challenge.id] = true
	_check("8 challenge templates, unique ids, {n} in text", CHALLENGES.challenges.size() == 8 and ids.size() == 8
		and CHALLENGES.challenges.all(func(c: ChallengeData) -> bool: return c.text.contains("{n}")))
	var stat_keys: Array[String] = LifetimeStats.INT_KEYS
	_check("achievements read known stat keys", ACHIEVEMENTS.achievements.size() >= 10
		and ACHIEVEMENTS.achievements.all(func(a: AchievementData) -> bool: return stat_keys.has(a.stat)))


func _ids(picks: Array[ChallengeData]) -> String:
	var ids := PackedStringArray()
	for challenge in picks:
		ids.append(challenge.id)
	return ",".join(ids)


func _test_roll() -> void:
	var all := {"grill": true, "beer": true, "hot": true}
	var first := DailyChallenges.roll(CHALLENGES, 4, all)
	_check("rolls 3", first.size() == 3)
	_check("same day -> same picks", _ids(first) == _ids(DailyChallenges.roll(CHALLENGES, 4, all)))
	var differs := false
	for day in range(1, 8):
		differs = differs or _ids(DailyChallenges.roll(CHALLENGES, day, all)) != _ids(first)
	_check("other days differ", differs)
	var none := {"grill": false, "beer": false, "hot": false}
	var impossible := false
	for day in range(1, 20):
		for challenge in DailyChallenges.roll(CHALLENGES, day, none):
			impossible = impossible or challenge.kind in [ChallengeData.Kind.GRILL, ChallengeData.Kind.BEER, ChallengeData.Kind.HOT]
	_check("no grill/beer/HOT challenge when the menu can't", not impossible)
	var beer_day1 := false
	for challenge in DailyChallenges.roll(CHALLENGES, 1, all):
		beer_day1 = beer_day1 or challenge.kind == ChallengeData.Kind.BEER
	_check("no beer challenge on day 1", not beer_day1)
	var grill: DishData = load("res://data/dishes/tom_nuong.tres")
	var boiled: DishData = load("res://data/dishes/tom_luoc.tres")
	var ctx := DailyChallenges.context([boiled] as Array[DishData], false, boiled.id)
	_check("context: boiled HOT dish, no grill", not bool(ctx["grill"]) and bool(ctx["hot"]))
	ctx = DailyChallenges.context([grill] as Array[DishData], true, "")
	_check("context: grill dish, beer, no HOT", bool(ctx["grill"]) and bool(ctx["beer"]) and not bool(ctx["hot"]))


func _test_saved_picks() -> void:
	GameState.reset()
	GameState.day = 3
	var picks := DailyChallenges.ensure(CHALLENGES, 3, {"grill": true, "beer": true, "hot": true})
	var again := DailyChallenges.ensure(CHALLENGES, 3, {"grill": false, "beer": false, "hot": false})
	_check("picks kept for the day (story flags)", picks.size() == 3 and _ids(picks) == _ids(again))
	var json := JSON.new()
	json.parse(JSON.stringify(SaveSystem.to_dict()))
	GameState.reset()
	SaveSystem.apply_dict(json.data)
	_check("picks survive a save round trip", _ids(DailyChallenges.saved_for(CHALLENGES, 3)) == _ids(picks))
	_check("no picks for another day", DailyChallenges.saved_for(CHALLENGES, 4).is_empty())


func _challenge(kind: ChallengeData.Kind, target: int) -> ChallengeData:
	var challenge := ChallengeData.new()
	challenge.id = "t%d" % kind
	challenge.text = "x {n}"
	challenge.kind = kind
	challenge.target = target
	challenge.reward_k = 25
	return challenge


func _test_progress() -> void:
	var grill: DishData = load("res://data/dishes/tom_nuong.tres")
	var beer: DishData = load("res://data/dishes/bia_con_meo.tres")
	var shift := ShiftLog.new()
	var pings: Array[int] = [0]
	shift.logged.connect(func() -> void: pings[0] += 1)
	shift.record_dish(grill, 60, true)
	shift.record_dish(beer, 40, false)
	shift.record_party(100, 10, 0.8)
	shift.record_dish(grill, 60, false)
	shift.record_party(60, 0, 0.2)
	_check("log counts", shift.grill_count() == 2 and shift.beer_count() == 1 and shift.hot_count() == 1
		and shift.parties_served() == 2 and shift.tips_count() == 1 and shift.fast_count(0.5) == 1
		and shift.earned == 170 and pings[0] == 5)
	var grill2 := _challenge(ChallengeData.Kind.GRILL, 2)
	var state := DailyChallenges.status(grill2, shift, 1, 0.5, false)
	_check("grill 2/2 done mid-shift", bool(state["done"]) and int(state["progress"]) == 2)
	var earn := _challenge(ChallengeData.Kind.EARN, 200)
	_check("earn 170/200 not done", not bool(DailyChallenges.status(earn, shift, 1, 0.5, false)["done"]))
	var calm := _challenge(ChallengeData.Kind.NOBODY_LEFT, 2)
	_check("nobody-left waits for closing", not bool(DailyChallenges.status(calm, shift, 1, 0.5, false)["done"])
		and bool(DailyChallenges.status(calm, shift, 1, 0.5, true)["done"]))
	shift.record_lost(15)
	var after := DailyChallenges.status(calm, shift, 1, 0.5, true)
	_check("someone left -> failed", bool(after["failed"]) and not bool(after["done"]) and shift.earned == 185)
	var growing := _challenge(ChallengeData.Kind.PARTIES, 3)
	growing.target_per_day = 0.5
	_check("target grows with the day", growing.target_on(1) == 3 and growing.target_on(5) == 5
		and growing.describe(5) == "x 5")


func _test_settle_once() -> void:
	GameState.reset()
	var shift := ShiftLog.new()
	shift.record_party(50, 5, 0.9)
	var picks: Array[ChallengeData] = [_challenge(ChallengeData.Kind.PARTIES, 1), _challenge(ChallengeData.Kind.TIPS, 3)]
	var money := GameState.money
	var results := DailyChallenges.settle(picks, shift, GameState.day, 0.5)
	_check("settle: one done, paid", results.size() == 2 and bool(results[0]["done"]) and int(results[0]["reward"]) == 25
		and not bool(results[1]["done"]) and GameState.money == money + 25)
	var twice := DailyChallenges.settle(picks, shift, GameState.day, 0.5)
	_check("settle twice pays nothing more", GameState.money == money + 25 and int(twice[0]["reward"]) == 0)


func _test_achievements() -> void:
	GameState.reset()
	var stats: Dictionary = {}
	var shift := ShiftLog.new()
	var grill: DishData = load("res://data/dishes/tom_nuong.tres")
	shift.record_dish(grill, 60, false)
	shift.record_party(60, 0, 0.7)
	LifetimeStats.apply(stats, shift, 5, 1)
	_check("stats added", LifetimeStats.value(stats, "served_total") == 1 and LifetimeStats.value(stats, "grill_total") == 1
		and LifetimeStats.value(stats, "five_star_days") == 1 and LifetimeStats.value(stats, "dish_kinds") == 1
		and LifetimeStats.value(stats, "staff_max") == 1 and LifetimeStats.value(stats, "perfect_days") == 0)
	var money := GameState.money
	var fresh := Achievements.check(ACHIEVEMENTS, stats)
	var ids: Array[String] = []
	for achievement in fresh:
		ids.append(achievement.id)
	_check("first guest / five star / staff unlocked", ids.has("first_guest") and ids.has("five_star")
		and ids.has("staff_1") and not ids.has("guests_100"))
	_check("rewards paid + flags set", GameState.money > money and GameState.has_flag("ach_first_guest"))
	var paid := GameState.money
	_check("unlock once", Achievements.check(ACHIEVEMENTS, stats).is_empty() and GameState.money == paid)
	var hundred: AchievementData = ACHIEVEMENTS.find("guests_100")
	_check("progress capped", Achievements.progress(hundred, stats) == 1
		and Achievements.progress(hundred, {"served_total": 500}) == 100)


func _test_stats_save() -> void:
	GameState.reset()
	var shift := ShiftLog.new()
	shift.record_dish(load("res://data/dishes/tom_luoc.tres"), 50, true)
	shift.record_party(50, 5, 0.9)
	LifetimeStats.apply(GameState.stats, shift, 3, 0)
	var before: Dictionary = GameState.stats.duplicate(true)
	var json := JSON.new()
	json.parse(JSON.stringify(SaveSystem.to_dict()))
	GameState.reset()
	_check("reset clears stats", GameState.stats.is_empty())
	SaveSystem.apply_dict(json.data)
	var same := GameState.stats.size() == before.size()
	for key: String in before:
		if key != "dishes_sold":
			same = same and GameState.stats.get(key) is int and int(GameState.stats[key]) == int(before[key])
	var sold: Dictionary = GameState.stats.get("dishes_sold", {})
	_check("stats save round trip", same and int(sold.get("tom_luoc", 0)) == 1 and sold.get("tom_luoc") is int)
	_check("bad stats ignored", LifetimeStats.from_save("x").is_empty()
		and LifetimeStats.from_save({"served_total": "a", "dishes_sold": 3}).is_empty())


## Final art dropped in by file name replaces the placeholder.
func _test_icon_art() -> void:
	_check("placeholder icon without art", GoalIcons.icon("heart") != null)
	var old_root := Art.root
	Art.root = "user://goal_icons_test/"
	DirAccess.make_dir_recursive_absolute(Art.root + "ui/icons")
	DirAccess.make_dir_recursive_absolute(Art.root + "ui/badges")
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.save_png(Art.root + "ui/icons/heart.png")
	var badge := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	badge.save_png(Art.root + "ui/badges/five_star.png")
	Art.clear_cache()
	_check("icon PNG replaces placeholder", GoalIcons.icon("heart").get_width() == 16)
	_check("badge PNG used, else its icon", GoalIcons.badge("five_star", "star").get_width() == 24
		and GoalIcons.badge("grill_20", "fire") == GoalIcons.icon("fire"))
	DirAccess.remove_absolute(Art.root + "ui/icons/heart.png")
	DirAccess.remove_absolute(Art.root + "ui/badges/five_star.png")
	Art.root = old_root
	Art.clear_cache()


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL", label])
