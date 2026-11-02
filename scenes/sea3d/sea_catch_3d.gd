class_name SeaCatch3D
extends RefCounted
## Rod casts at bubble shoals and storing what comes up in the hold.
## Host (SeaScene3D) fields written: fishing.

static func try_fish(sea: SeaScene3D) -> void:
	if sea.overlay == null:
		sea._say("Màn câu cá chưa được nạp.", 2.5)
		return
	var boat := sea.boat
	for i in range(sea.shoals.size()):
		var shoal := sea.shoals[i]
		if shoal.fish_left > 0 and boat.position.distance_to(shoal.pos) < 4.8 and boat.velocity.length() < 2.4:
			var fish := shoal.roll_fish(sea.fish_catalog, sea.rng, 0.0, {})
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
			var difficulty := CatchRoll.size_zone_scale(size) * maxf(1.0 - used * 0.08, 0.75)
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

static func on_catch_detailed(sea: SeaScene3D, fish: FishData, caught: bool, quality: float, count: int, size: float) -> void:
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
		sea._say("Con cá này... sao lại phát sáng?", 3.0)
	if not is_new and previous_best > 0.0 and size > previous_best:
		Sfx.play("shutter")  # size record: Rin snaps a photo
	var overflow: Array[InventoryItem] = []
	for i in range(count):
		var item := InventoryItem.new(fish, quality, size)
		item.is_new = is_new
		if not hold.auto_place(item):
			overflow.append(item)
	sea._say("Bắt được %s %s. Khoang đầy %d%%." % [fish.display_name, fish.weight_text(size), roundi(hold.fill_fraction() * 100.0)], 4.0)
	if not overflow.is_empty() and sea.hold_ui:
		sea.hold_ui.open_overflow(overflow)
	if is_new and sea.new_catch_card:
		# Batch hauls finish opening overflow before the reveal claims pause.
		sea.new_catch_card.show_fish.call_deferred(fish, size)
