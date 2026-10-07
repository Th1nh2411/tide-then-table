extends Control
## Standalone test for night-trip systems (run with F6): weather picking,
## boat range limits, event kind picking, dolphin target choice, bottles.
## Visiting things needs the sea scene (autosaves), so that's not done here.

@export var weather_catalog: WeatherCatalog
@export var boats: Array[BoatData] = []
@export var fish_catalog: FishCatalog

var _failures: int = 0


func _ready() -> void:
	GameState.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	# Weather.
	_check("weather find", weather_catalog.find("rain").rain and weather_catalog.find("moon").night_brightness > 1.0)
	_check("unknown weather -> first", weather_catalog.find("bão tuyết") == weather_catalog.weathers[0])
	var seen: Dictionary = {}
	for i in 400:
		seen[weather_catalog.pick(rng).id] = true
	_check("all weathers can roll", seen.size() == weather_catalog.weathers.size())
	var moon := weather_catalog.find("moon")
	var squid := 0
	for i in 2000:
		if fish_catalog.pick_random(FishData.Zone.NEARSHORE, rng, FishData.CatchMethod.ROD, 0.0, 0.0, moon.species_bonus).id == "muc":
			squid += 1
	# Nearshore rod fish: squid ~43% normally, ~69% with the moon's x3.
	_check("moon: more squid (%d/2000)" % squid, squid > 1250)

	# Boat range: bigger boat goes further out (smaller y).
	var range_node := BoatRange.new()
	var limits: Array[float] = []
	for boat in boats:
		limits.append(range_node.limit_for(boat))
	_check("boat range grows", limits[0] > limits[1] and not is_finite(limits[2]))
	range_node.free()

	# Event kinds: no duplicates, count capped.
	var kinds := NightEvents.pick_kinds(rng, 6, [1.0, 1.0, 1.0, 1.0])
	_check("event kinds unique", kinds.size() == 4 and kinds.duplicate().size() == 4
		and kinds.has(0) and kinds.has(1) and kinds.has(2) and kinds.has(3))

	# Dolphins: big shadow first, unreachable spots skipped.
	var near := _spot(Vector2(0, 900), "tom", false)
	var big := _spot(Vector2(0, 850), "cua", true)
	var far := _spot(Vector2(0, 100), "ca_mu", true)
	_check("dolphins -> reachable big shadow", DolphinPod.best_spot([near, big, far], 800.0) == big)
	for spot in [near, big, far]:
		spot.free()

	# Bottles.
	_check("bottles default 0", MessageBottle.pages_read() == 0)
	GameState.set_flag(MessageBottle.READ_FLAG, 3.0)
	_check("bottles from save", MessageBottle.pages_read() == 3)
	# Dock unload mid-night: storage now, still counted in tonight's catch.
	GameState.reset()
	var tom: FishData = fish_catalog.fish.filter(func(f: FishData) -> bool: return f.id == "tom")[0]
	GameState.unload_catch([InventoryItem.new(tom), InventoryItem.new(tom)])
	_check("unload -> storage", GameState.storage.size() == 2 and GameState.trip_catch.size() == 2)
	GameState.finish_sea_day(120.0, false, [InventoryItem.new(tom)])
	_check("trip catch joins last catch", GameState.last_catch.size() == 3 and GameState.storage.size() == 3
		and GameState.trip_catch.is_empty())
	GameState.reset()
	print("Night: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


func _spot(pos: Vector2, fish_id: String, big_shadow: bool) -> FishingSpot:
	var spot := FishingSpot.new()
	spot.position = pos
	spot.big_shadow = big_shadow
	for f in fish_catalog.fish:
		if f.id == fish_id:
			spot.featured = f
	return spot


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
