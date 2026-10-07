extends Control
## Standalone test for rod catches (run with F6): depth weighting, featured
## spots, fish size, weight text and size-based prices.

const SAMPLES: int = 4000

@export var fish_catalog: FishCatalog
@export var grill_dish: DishData

var _failures: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 12345
	GameState.reset()
	_test_depth()
	_test_depth_weighting()
	_test_spot()
	_test_size()
	_test_weight_and_price()
	GameState.reset()
	print("CatchRoll: %s" % ("TẤT CẢ PASS" if _failures == 0 else "%d FAIL" % _failures))


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


func _test_spot() -> void:
	var spot := FishingSpot.new()
	spot.zone = FishData.Zone.OPEN_SEA
	spot.featured = _fish("ca_thu")
	spot.featured_chance = 0.7
	var hits := 0
	for i in SAMPLES:
		if spot.roll_fish(fish_catalog, _rng) == spot.featured:
			hits += 1
	# 0.7 featured + its normal zone share of the other 0.3.
	_check("spot: featured dominates", float(hits) / SAMPLES > 0.7)
	_check("spot hint unknown -> ???", spot.hint_text().contains("???"))
	GameState.record_catch(_fish("ca_thu"), 1)
	_check("spot hint known -> name", spot.hint_text().contains("Cá thu"))
	spot.big_shadow = true
	_check("spot hint big shadow", spot.hint_text().begins_with("bóng cá lớn"))
	spot.free()


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
	var small: Array[InventoryItem] = [InventoryItem.new(_fish("ca_thu"), 1.0, 1.0)]
	var large: Array[InventoryItem] = [InventoryItem.new(_fish("ca_thu"), 1.0, 1.5)]
	var p_small := KitchenLogic.calc_price(grill_dish, 1.0, small)
	var p_large := KitchenLogic.calc_price(grill_dish, 1.0, large)
	_check("bigger fish sells for more", p_large == roundi(p_small * 1.5))
	var copy := InventoryItem.from_dict(large[0].to_dict(), fish_catalog)
	_check("size saved in item dict", copy != null and is_equal_approx(copy.size, 1.5))


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
