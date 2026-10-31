class_name SeaCatch3D
extends RefCounted
## Rod casts at bubble shoals, nets, and storing what comes up in the hold.
## Host (SeaScene3D) fields written: fishing, nets, net_haul, net_haul_count.

static func try_fish(sea: SeaScene3D) -> void:
	if sea.overlay == null:
		sea._say("Màn câu cá chưa được nạp.", 2.5)
		return
	var boat := sea.boat
	var weather := sea.weather
	for i in range(sea.shoals.size()):
		var shoal := sea.shoals[i]
		if shoal.fish_left > 0 and boat.position.distance_to(shoal.pos) < 4.8 and boat.velocity.length() < 2.4:
			var rarity := weather.rarity_bonus if weather else 0.0
			var species_bonus := weather.species_bonus if weather else {}
			var fish := shoal.roll_fish(sea.fish_catalog, sea.rng, rarity, species_bonus)
			if fish == null:
				sea._say("Chỗ này không còn cá.", 2.0)
				return
			var used := shoal.max_fish - shoal.fish_left
			var school := shoal.school_count()
			sea.fishing = true
			boat.velocity = Vector3.ZERO
			sea.yaw_velocity = 0.0
			sea._spend_oil(2.0)
			var size := CatchRoll.snap_size(CatchRoll.roll_size(sea.rng, shoal.depth, shoal.big_shadow), fish.typical_kg)
			size = CatchRoll.snap_size(minf(size + used * 0.08, CatchRoll.MAX_SIZE), fish.typical_kg)
			var difficulty := float(GameState.get_upgrade_value(SeaScene3D.ROD_UPGRADE)) * CatchRoll.size_zone_scale(size) * WaveMark.fight_scale(fish, CatchRoll.is_big(size)) * maxf(1.0 - used * 0.08, 0.75)
			# One fish leaves the shoal per cast, caught or not.
			shoal.fish_left -= 1
			sea.overlay.set("zone", SeaLayout3D.zone_at(boat.position, Story.is_fog_open()))
			if sea.cast_cinematic_enabled and sea.cinematic:
				cast_then_fish(sea, shoal.pos, fish, difficulty, size, school)
			else:
				sea.overlay.call("start_catch", fish, difficulty, size, 1, school)
			return
	sea._say("Tìm bọt khí trên mặt biển, đến gần rồi giảm ga để câu.", 2.5)

static func cast_then_fish(sea: SeaScene3D, target: Vector3, fish: FishData, difficulty: float, size: float, school: int) -> void:
	sea._cast_played = true
	await sea.cinematic.play(target)
	if sea.ending or not sea.is_inside_tree():
		return
	sea.overlay.call("start_catch", fish, difficulty, size, 1, school)
	sea.cinematic.reveal()

static func drop_net(sea: SeaScene3D) -> void:
	var boat := sea.boat
	if sea.nets.size() >= 2:
		sea._say("Đã thả hết 2 lưới. Hãy kéo lưới cũ lên.", 2.5)
		return
	if boat.velocity.length() > 1.5:
		sea._say("Giảm ga trước khi thả lưới.", 2.0)
		return
	var zone := SeaLayout3D.zone_at(boat.position, Story.is_fog_open())
	if sea.fish_catalog.get_fish_for_zone(zone, FishData.CatchMethod.NET).is_empty():
		sea._say("Vùng này không hợp để thả lưới.", 2.0)
		return
	var pos := boat.position + Vector3.BACK.rotated(Vector3.UP, boat.rotation.y) * 2.8
	for net in sea.nets:
		if pos.distance_to(net["pos"]) < 7.0:
			sea._say("Hai lưới quá gần nhau.", 2.0)
			return
	var buoy := Node3D.new()
	sea.add_child(buoy)
	buoy.position = pos
	SeaWorldBuilder3D.batch_model(buoy, "net_buoy", Vector3(0, 0.06, 0))
	var map_net := Node2D.new()
	map_net.add_to_group("net_buoys")
	sea.add_child(map_net)
	map_net.position = SeaLayout3D.to_map(pos)
	sea.nets.append({"pos": pos, "zone": zone, "time": sea.elapsed, "node": buoy, "map_node": map_net})
	sea._spend_oil(1.0)
	sea._say("Đã thả lưới. Quay lại sau một lúc để kéo lên.", 2.5)

## Removes a net (buoy + map marker).
static func remove_net(sea: SeaScene3D, index: int) -> void:
	var net := sea.nets[index]
	(net["node"] as Node3D).queue_free()
	(net["map_node"] as Node2D).queue_free()
	sea.nets.remove_at(index)

static func try_haul_net(sea: SeaScene3D) -> bool:
	var boat := sea.boat
	for i in range(sea.nets.size()):
		var net := sea.nets[i]
		if boat.position.distance_to(net["pos"]) >= 3.4:
			continue
		if boat.velocity.length() > 1.5:
			sea._say("Giảm ga trước khi kéo lưới.", 2.0)
			return true
		var soak := sea.elapsed - float(net["time"])
		var count := clampi(roundi(8.0 * soak / 90.0), 0, 8)
		var zone: FishData.Zone = net["zone"]
		var haul: Array[Array] = []
		var depth: float = [0.1, 0.5, 0.8, 1.0][clampi(int(zone), 0, 3)]
		for animal in range(count):
			var species := sea.fish_catalog.pick_random(zone, sea.rng, FishData.CatchMethod.NET)
			if species:
				var size := CatchRoll.snap_size(CatchRoll.roll_size(sea.rng, depth, false), species.typical_kg)
				haul.append([species, size])
		remove_net(sea, i)
		if haul.is_empty():
			sea._say("Lưới còn trống. Đợi lâu hơn trước khi kéo.", 2.5)
			return true
		if sea.overlay == null:
			sea._say("Không nạp được màn kéo lưới.", 2.5)
			return true
		sea.net_haul = haul
		sea.net_haul_count = haul.size()
		var species_counts: Dictionary = {}
		var main_species: FishData = haul[0][0]
		for entry: Array in haul:
			var species: FishData = entry[0]
			species_counts[species] = int(species_counts.get(species, 0)) + 1
			if int(species_counts[species]) > int(species_counts.get(main_species, 0)):
				main_species = species
		sea.fishing = true
		boat.velocity = Vector3.ZERO
		sea.yaw_velocity = 0.0
		sea._spend_oil(2.0)
		var bonus := 1.0 + GameState.get_upgrade_level("net") * 0.15
		sea.overlay.call("start_catch", main_species, bonus, 1.0, sea.net_haul_count)
		return true
	return false

static func on_catch_detailed(sea: SeaScene3D, fish: FishData, caught: bool, quality: float, count: int, size: float) -> void:
	if not sea.net_haul.is_empty():
		var haul := sea.net_haul.duplicate()
		sea.net_haul.clear()
		sea.net_haul_count = 0
		if not caught:
			sea._say("Lưới tuột mất mẻ hải sản.", 2.0)
			return
		var species_counts: Dictionary = {}
		for entry: Array in haul:
			var species: FishData = entry[0]
			store_catch(sea, species, quality, 1, float(entry[1]))
			species_counts[species.display_name] = int(species_counts.get(species.display_name, 0)) + 1
		var parts := PackedStringArray()
		for name: String in species_counts:
			parts.append("%d %s" % [species_counts[name], name])
		sea._say("Kéo lưới được %s!" % ", ".join(parts), 3.0)
		sea._update_hud()
		return
	if not caught:
		sea._say("Cá tuột mất rồi.", 2.0)
		return
	store_catch(sea, fish, quality, count, size)
	sea._update_hud()

static func store_catch(sea: SeaScene3D, fish: FishData, quality: float, count: int, size: float) -> void:
	if fish == null or count <= 0:
		return
	var hold := sea.hold
	var is_new := int(GameState.caught_species.get(fish.id, 0)) == 0
	var previous_best := GameState.best_size(fish)
	# A landed catch belongs in the Dex even when the hold needs sorting.
	GameState.record_catch(fish, count, size)
	if Story.on_fish_caught(fish):
		sea._say("[WARN] species_id không có trong database. Ngoài khơi đông bắc có gì đó lạ.", 3.0)
	var rewards := CollectionRewards.claim(fish, size, is_new, previous_best)
	if not is_new and previous_best > 0.0 and size > previous_best:
		Sfx.play("shutter")  # size record: Rin snaps a photo
	var overflow: Array[InventoryItem] = []
	for i in range(count):
		var item := InventoryItem.new(fish, quality, size)
		item.is_new = is_new
		if not hold.auto_place(item):
			overflow.append(item)
	sea._say("Bắt được %s %s. Khoang đầy %d%%.%s" % [fish.display_name, fish.weight_text(size), roundi(hold.fill_fraction() * 100.0), "\n" + "\n".join(rewards) if not rewards.is_empty() else ""], 4.0)
	if not overflow.is_empty() and sea.hold_ui:
		sea.hold_ui.open_overflow(overflow)
	if is_new and sea.new_catch_card:
		# Batch hauls finish opening overflow before the reveal claims pause.
		sea.new_catch_card.show_fish.call_deferred(fish, size)
