extends Control
## Standalone test for rod catches (run with F6): depth weighting, featured
## fish size and weight text.

const SAMPLES: int = 4000

@export var fish_catalog: FishCatalog

var _failures: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 12345
	GameState.reset()
	_test_depth()
	_test_depth_weighting()
	_test_size()
	_test_weight_and_price()
	_test_rods()
	GameState.reset()
	print("CatchRoll: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


## Rods never bring up shrimp or crab (nets are gone; those stay uncaught).
func _test_rods() -> void:
	var rod_ids: Array[String] = []
	for zone in [0, 1, 2]:
		for fish in fish_catalog.get_fish_for_zone(zone as FishData.Zone, FishData.CatchMethod.ROD):
			rod_ids.append(fish.id)
	_check("rods: no shrimp / crab, reef has mackerel", not rod_ids.has("tom") and not rod_ids.has("cua")
		and fish_catalog.get_fish_for_zone(FishData.Zone.REEF, FishData.CatchMethod.ROD).any(
			func(f: FishData) -> bool: return f.id == "ca_thu"))


func _test_depth() -> void:
	_check("depth: shore = 0", is_zero_approx(CatchRoll.depth_at(1160.0, 1160.0, 0.0)))
	_check("depth: far edge = 1", is_equal_approx(CatchRoll.depth_at(0.0, 1160.0, 0.0), 1.0))
	_check("depth: clamped", is_zero_approx(CatchRoll.depth_at(1300.0, 1160.0, 0.0)))


func _test_depth_weighting() -> void:
	var shallow := _share(FishData.Zone.OPEN_SEA, 0.0, "ca_mu")
	var deep := _share(FishData.Zone.OPEN_SEA, 1.0, "ca_mu")
	print("    ca_mu share open sea: depth0 %.2f, depth1 %.2f" % [shallow, deep])
	_check("deeper -> more pricey fish", deep > shallow + 0.1)
	var glow0 := _share(FishData.Zone.OPEN_SEA, 0.0, "ca_thu_phat_sang")
	var glow1 := _share(FishData.Zone.OPEN_SEA, 1.0, "ca_thu_phat_sang")
	_check("aberrant not boosted by depth", glow1 <= glow0 + 0.01)


func _test_size() -> void:
	var shallow := _mean_size(0.0, false)
	var deep := _mean_size(1.0, false)
	var big := _mean_size(1.0, true)
	print("    mean size: shore %.2f, deep %.2f, big shadow %.2f" % [shallow, deep, big])
	_check("size: deeper -> bigger", deep > shallow + 0.15)
	_check("size: big shadow -> biggest", big > deep + 0.2)
	var in_range := true
	for i in SAMPLES:
		var s := CatchRoll.roll_size(_rng, 1.0, true)
		in_range = in_range and s >= CatchRoll.MIN_SIZE and s <= CatchRoll.MAX_SIZE
	_check("size: clamped", in_range)
	_check("size: big fish harder", CatchRoll.size_zone_scale(1.5) < 1.0 and CatchRoll.size_zone_scale(0.8) > 1.0)
	GameState.record_catch(_fish("cua"), 1, 1.2)
	GameState.record_catch(_fish("cua"), 1, 0.9)
	_check("record keeps biggest", is_equal_approx(GameState.best_size(_fish("cua")), 1.2))


func _test_weight_and_price() -> void:
	_check("weight kg text", _fish("ca_mu").weight_text(1.3) == "4kg")
	_check("weight g text", _fish("muc").weight_text(1.3) == "520g")
	var snapped := CatchRoll.snap_size(1.3, 3.0)
	_check("snap to whole kg", is_equal_approx(_fish("ca_mu").weight_kg(snapped), 4.0))
	_check("snap small to 10g", is_equal_approx(_fish("tom").weight_kg(CatchRoll.snap_size(1.17, 0.06)), 0.07))


func _share(zone: FishData.Zone, depth: float, id: String) -> float:
	var hits := 0
	for i in SAMPLES:
		var f := fish_catalog.pick_random(zone, _rng, FishData.CatchMethod.ROD, depth, 3.0)
		if f.id == id:
			hits += 1
	return float(hits) / SAMPLES


func _mean_size(depth: float, big: bool) -> float:
	var total := 0.0
	for i in SAMPLES:
		total += CatchRoll.roll_size(_rng, depth, big)
	return total / SAMPLES


func _check(label: String, ok: bool) -> void:
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])


func _fish(id: String) -> FishData:
	for f in fish_catalog.fish:
		if f.id == id:
			return f
	return null
