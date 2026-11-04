extends Node
## Regression checks for native 3D night-trip progression.

var failures: int = 0

func check(value: bool, label: String) -> void:
	print("PASS " + label if value else "FAIL " + label)
	if not value:
		failures += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset()
	var packed := load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene
	var sea: Node = packed.instantiate()
	add_child(sea)
	sea.set_physics_process(false)
	await get_tree().process_frame
	check(is_equal_approx(float(sea.get("oil_capacity")), 100.0), "sea3d lamp has a fixed tank (no upgrades)")
	sea.call("_physics_process", 1.0)
	check(is_equal_approx(float(sea.get("oil")), 100.0), "sea3d dock does not burn oil")
	var boat := sea.get("boat") as CharacterBody3D
	boat.position = SeaLayout3D.to_world(Vector2(900, 1000))
	sea.call("_physics_process", 1.0)
	check(is_equal_approx(float(sea.get("oil")), 100.0 - 100.0 / 240.0), "sea3d sailing uses original oil burn rate")
	var before := float(sea.get("oil"))
	var at := boat.position
	sea.set("fishing", true)
	sea.call("_physics_process", 1.0)
	sea.set("fishing", false)
	check(float(sea.get("oil")) < before and boat.position == at, "sea3d lamp burns while the line is out, the boat holds still")
	sea.call("_spend_oil", float(sea.get("oil")) - 50.0)
	check(DayClock.current_minutes > 0.0, "sea3d clock follows the tank fraction")
	var school: int = sea.call("_nearest_school_index")
	check(school >= 0, "sea3d starter boat can reach a fishing school")
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
	check(banned == 0, "sea3d has no shoal marker or arrow")
	_check_landmarks(sea)
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


## Diegetic navigation: no HUD markers or floating names; lights + the bell.
func _check_landmarks(sea: Node) -> void:
	var texts := 0
	for node in sea.get_children():  # world text (the basket count / bite "!" belong to the rod)
		texts += 1 if node is Label3D else 0
	check(texts == 0 and not sea.has_method("navigation_targets"), "sea3d has no place names or edge markers")
	var marks := sea.get("landmarks") as SeaLandmarks3D
	check(marks != null and marks.beams.size() == 2, "sea3d both lighthouses sweep a beam")
	var pivot: Node3D = marks.beams[0][0] if marks else null
	var before := pivot.rotation.y if pivot else 0.0
	if marks:
		marks._process(0.5)
	check(pivot != null and not is_equal_approx(pivot.rotation.y, before), "sea3d lighthouse beam turns")
	var green: bool = marks != null and marks.raft_lamp != null \
		and (marks.raft_lamp.material_override as StandardMaterial3D).albedo_color.g > 0.9
	check(green, "sea3d lobster raft keeps a green lamp")
	var start: Vector3 = sea.get("START")
	var bell: DockBell3D = marks.bell if marks else null
	check(bell != null and Vector2(bell.global_position.x - start.x, bell.global_position.z - start.z).length() < 6.0
		and DockBell3D.RANGE >= 35.0 and DockBell3D.RANGE <= 45.0, "sea3d dock bell hangs at the pier, heard within ~40 m")
	if bell:
		var rang := bell.rings
		bell._process(DockBell3D.EVERY + DockBell3D.JITTER + 0.1)
		bell._process(DockBell3D.EVERY + DockBell3D.JITTER + 0.1)
		check(bell.rings > rang, "sea3d dock bell rings every few seconds")
