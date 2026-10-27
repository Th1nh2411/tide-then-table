extends Node
## Scene-based smoke: use a writable APPDATA when running headless on Windows.

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameState.reset()
	GameState.day = 2
	var sea := (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate()
	add_child(sea)
	await get_tree().process_frame
	_check(not sea.night_events.is_empty(), "night events spawn after day 1")
	var fish: FishData = sea.fish_catalog.fish[0]
	sea.hold.auto_place(InventoryItem.new(fish))
	var before_money := GameState.money
	sea._visit_poi("shrine")
	await get_tree().process_frame
	sea.poi_dialog._answered.emit(0)
	await get_tree().process_frame
	_check(sea.shrine_blessed and sea.blessed_damage_scale == 0.5 and GameState.money == before_money - 10,
		"Miếu Cá Ông blessing")
	sea._visit_poi("lighthouse")
	await get_tree().process_frame
	sea.poi_dialog._answered.emit(0)
	await get_tree().process_frame
	_check(Lighthouse.pages_read() == 1, "Đá Canh Đêm page flag")
	sea._visit_poi("raft")
	await get_tree().process_frame
	sea.poi_dialog._answered.emit(1)
	await get_tree().process_frame
	_check(sea.hold.items.is_empty() and GameState.money > before_money - 10, "Anh Út buys hold")
	_check(PhoneMap._snap["places"].size() >= 6, "3D POIs on phone map")
	sea.night_events.clear()
	var bottle_node := Node3D.new()
	sea.add_child(bottle_node)
	sea.night_events.append({"kind": NightEvents.Kind.BOTTLE, "pos": Vector3.ZERO,
		"node": bottle_node, "done": false, "time": 0.0, "towing": false, "owner": "Chú Sáu"})
	sea._visit_night_event(0)
	await get_tree().process_frame
	sea.poi_dialog._answered.emit(0)
	await get_tree().process_frame
	_check(MessageBottle.pages_read() == 1 and sea.night_events[0]["done"], "Chai thư story page")
	var stranded_node := Node3D.new()
	sea.add_child(stranded_node)
	sea.night_events.append({"kind": NightEvents.Kind.STRANDED, "pos": Vector3.ZERO,
		"node": stranded_node, "done": false, "time": 0.0, "towing": false, "owner": "Chú Sáu"})
	sea._visit_night_event(1)
	await get_tree().process_frame
	sea.poi_dialog._answered.emit(0)
	await get_tree().process_frame
	_check(sea._is_towing(), "Ghe chết máy tow state")
	sea.trip_end_cutscenes.clear()
	var tow_money := GameState.money
	sea._end_trip(false)
	_check(GameState.money == tow_money + 80 and not GameState.trip_notes.is_empty(), "tow reward at dock")
	print("SEA POI 3D SMOKE PASS")
	get_tree().paused = false
	get_tree().quit(0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		push_error("SEA POI 3D SMOKE FAIL: " + label)
		get_tree().paused = false
		get_tree().quit(1)
