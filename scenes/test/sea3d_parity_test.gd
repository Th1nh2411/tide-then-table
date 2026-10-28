extends Node
## Regression checks for native 3D night-trip progression.

class CaptureOverlay:
	extends CanvasLayer
	var calls: int = 0
	var school_value: int = 0
	var scale_value: float = 0.0
	var size_value: float = 0.0
	func start_catch(_fish: FishData, zone_scale: float = 1.0, size: float = 1.0, _count: int = 1, school: int = 6) -> void:
		calls += 1
		school_value = school
		scale_value = zone_scale
		size_value = size

var failures: int = 0

func check(value: bool, label: String) -> void:
	print("PASS " + label if value else "FAIL " + label)
	if not value:
		failures += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset()
	GameState.upgrade_levels["lamp"] = 2
	GameState.upgrade_levels["rod"] = 2
	var packed := load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene
	var sea: Node = packed.instantiate()
	add_child(sea)
	sea.set_physics_process(false)
	await get_tree().process_frame
	check(is_equal_approx(float(sea.get("oil_capacity")), 190.0), "sea3d lamp upgrade increases nightly oil capacity")
	sea.call("_physics_process", 1.0)
	check(is_equal_approx(float(sea.get("oil")), 190.0), "sea3d dock does not burn oil")
	var boat := sea.get("boat") as CharacterBody3D
	boat.position = SeaLayout3D.to_world(Vector2(900, 1000))
	sea.call("_physics_process", 1.0)
	check(is_equal_approx(float(sea.get("oil")), 190.0 - 100.0 / 240.0), "sea3d sailing uses original oil burn rate")
	sea.call("_spend_oil", 94.5833333333)
	check(is_equal_approx(DayClock.current_minutes, 180.0), "sea3d clock uses upgraded tank fraction")
	var school: int = sea.call("_nearest_school_index")
	check(school >= 0, "sea3d starter boat can reach a fishing school")
	var pin_world := Vector3(11, 0, 20)
	GameState.map_pins.append(sea.call("_map_pos", pin_world))
	var destinations: Array = sea.call("navigation_targets")
	var pin_matches := false
	for target: Dictionary in destinations:
		if target["label"] == "Ghim 1":
			pin_matches = (target["pos"] as Vector3).is_equal_approx(pin_world)
	check(pin_matches, "sea3d map pins round-trip to navigation world coordinates")
	var original := sea.get("overlay") as CanvasLayer
	original.queue_free()
	var capture := CaptureOverlay.new()
	sea.add_child(capture)
	sea.set("overlay", capture)
	var shoal: SeaShoals3D.Shoal = sea.shoals[school]
	shoal.fish_left = 3
	shoal.max_fish = 3
	sea.set("cast_cinematic_enabled", false)
	boat.position = shoal.pos
	boat.velocity = Vector3.ZERO
	sea.set("rng", RandomNumberGenerator.new())
	sea.call("_try_fish")
	check(capture.school_value == 3 and shoal.fish_left == 2, "sea3d minigame fish count equals shoal fish left, then shoal drops by one")
	check(capture.calls == 1 and capture.scale_value > 1.2 and capture.size_value > 0.0, "sea3d casts pass rod upgrade and rolled size to minigame")
	sea.call("_on_catch_finished", false, null)
	sea.call("_try_fish")
	sea.call("_on_catch_finished", false, null)
	sea.call("_try_fish")
	sea.call("_on_catch_finished", false, null)
	sea.call("_try_fish")
	check(capture.calls == 3, "sea3d fishing school empties after three fish")
	sea.set("hold", GridInventory.new(Vector2i.ONE))
	var card := sea.get("new_catch_card") as NewCatchCard
	card.queue_free()
	sea.set("new_catch_card", null)
	var fish := load("res://data/fish/ca_thu.tres") as FishData
	var before: int = GameState.money
	sea.call("_store_catch", fish, 1.0, 1, 1.0)
	check(int(GameState.caught_species.get(fish.id, 0)) == 1, "sea3d overflow catch records Dex before sorting")
	check(GameState.money > before, "sea3d new species pays collection reward")
	var hold_ui := sea.get("hold_ui") as HoldUI
	check(hold_ui.has_pending(), "sea3d full hold preserves catch in overflow tray")
	hold_ui.close()
	var after: int = GameState.money
	sea.call("_store_catch", fish, 1.0, 1, 1.0)
	check(GameState.money == after, "sea3d repeated species does not duplicate discovery reward")
	hold_ui.close()
	# Dolphins must run outside the jellyfish branch.
	var dolphin := Node3D.new()
	sea.add_child(dolphin)
	dolphin.position = boat.position + Vector3(2, 0, 0)
	var events: Array[Dictionary] = [{"kind": NightEvents.Kind.DOLPHINS, "pos": boat.position, "node": dolphin, "done": false, "time": 0.0, "towing": false, "owner": "Chú Sáu"}]
	shoal.fish_left = 2
	sea.set("night_events", events)
	sea.call("_update_night_events", 1.0)
	check(bool(events[0]["done"]) and dolphin.position.distance_to(boat.position) < 2.0, "sea3d dolphins detect boat and lead toward fish")
	_check_shoals(sea)
	_check_bubbles(sea)
	get_tree().paused = false
	sea.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)


func _check_shoals(sea: Node) -> void:
	var catalog := sea.get("fish_catalog") as FishCatalog
	var ok_zones := true
	var ok_depth := true
	var ok_species := true
	var ok_count := true
	var ok_spacing := true
	var layout_ok := true
	var half := SeaLayout3D.size_world() * 0.5
	for fog_open: bool in [false, true]:
		for seed_value in range(25):
			var r := RandomNumberGenerator.new()
			r.seed = seed_value
			var list := SeaShoals3D.spawn(catalog, r, fog_open)
			var per_zone: Dictionary = {}
			for s in list:
				per_zone[s.zone] = int(per_zone.get(s.zone, 0)) + 1
				var px := SeaLayout3D.to_map(s.pos)
				if SeaLayout3D.zone_at(s.pos, fog_open) != s.zone or not SeaLayout3D.zone_rect(s.zone).has_point(px):
					ok_zones = false
				if not is_equal_approx(s.depth, clampf((1160.0 - px.y) / 1160.0, 0.0, 1.0)):
					ok_depth = false
				if s.featured == null or not s.featured.zones.has(s.zone):
					ok_species = false
				if absf(s.pos.x) > half.x or absf(s.pos.z) > half.y:
					layout_ok = false
				for o in list:
					if o != s and o.pos.distance_to(s.pos) < 10.0 - 0.01:
						ok_spacing = false
			for zone: FishData.Zone in SeaLayout3D.SPOT_COUNT:
				if zone == FishData.Zone.FOG and not fog_open:
					if per_zone.has(zone):
						ok_count = false
				elif int(per_zone.get(zone, 0)) != int(SeaLayout3D.SPOT_COUNT[zone]):
					ok_count = false
	check(ok_zones, "sea3d shoals spawn inside their zone rect (fog only when open)")
	check(ok_count, "sea3d shoal counts match 2D spot_count per zone")
	check(ok_depth, "sea3d shoal depth follows shore-to-deep distance")
	check(ok_species, "sea3d shoal featured species belong to the shoal zone")
	check(ok_spacing and layout_ok, "sea3d shoals keep spacing and stay on the map")
	var near := SeaLayout3D.to_world(Vector2(960, 1000))
	check(SeaLayout3D.zone_at(near, false) == FishData.Zone.NEARSHORE and SeaLayout3D.zone_at(SeaLayout3D.to_world(Vector2(960, 700)), false) == FishData.Zone.REEF \
		and SeaLayout3D.zone_at(SeaLayout3D.to_world(Vector2(960, 300)), false) == FishData.Zone.OPEN_SEA, "sea3d zone layout matches 2D bands")
	check(SeaLayout3D.to_map(SeaLayout3D.to_world(Vector2(480, 345))).is_equal_approx(Vector2(480, 345)), "sea3d map coordinates round-trip")
	var reach_small := SeaLayout3D.reach_z(0.32)
	check(reach_small > SeaLayout3D.reach_z(0.6) and SeaLayout3D.reach_z(1.0) == -INF, "sea3d boat range grows with max_depth")
	var placed := (sea.get("LIGHTHOUSE_POS") as Vector3).is_equal_approx(SeaLayout3D.to_world(SeaLayout3D.LIGHTHOUSE_PX))
	check(placed and (sea.get("shoals") as Array).size() >= 12, "sea3d scene uses layout positions and rolled shoals")


func _check_bubbles(sea: Node) -> void:
	var spots: Array = sea.get("bubble_spots")
	var shoals: Array = sea.get("shoals")
	check(spots.size() == shoals.size() and spots.size() > 0, "sea3d has one bubble node per active shoal")
	var banned := 0
	for node: Node in sea.get_children():
		var n := String(node.name).to_lower()
		if n.contains("buoy") or n.contains("marker") or n.contains("beam"):
			banned += 1
	for target: Dictionary in sea.call("navigation_targets"):
		if str(target["label"]).begins_with("Cá"):
			banned += 1
	check(banned == 0, "sea3d has no shoal marker or arrow")
	var spot: BubbleSpot3D = spots[0]
	var shoal: SeaShoals3D.Shoal = spot.shoal
	var boat := sea.get("boat") as Node3D
	boat.position = shoal.pos
	spot.view_range = 8.0
	shoal.fish_left = 5
	spot.update_bubbles()
	var many := 0
	for b in spot.bubbles:
		many += 1 if b.visible else 0
	shoal.fish_left = 1
	spot.update_bubbles()
	var few := 0
	for b in spot.bubbles:
		few += 1 if b.visible else 0
	check(spot.shown and many > few and few > 0, "sea3d bubbles scale with shoal size")
	boat.position = shoal.pos + Vector3(40, 0, 0)
	spot.update_bubbles()
	check(not spot.shown, "sea3d bubbles hide outside lamp range")
	boat.position = shoal.pos
	shoal.fish_left = 0
	spot.update_bubbles()
	var gone := true
	for b in spot.bubbles:
		gone = gone and not b.visible
	check(gone and not spot.shown, "sea3d bubbles vanish when the shoal is empty")
