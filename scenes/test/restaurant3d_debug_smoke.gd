extends Node
## Verifies the 2D restaurant's F1/F2 debug inventory shortcuts in 3D.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	for cutscene_id in ["opening_day", "vy_arrives", "wave_awaken"]:
		GameState.set_flag("dlg_" + cutscene_id)
	var room: Node3D = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	add_child(room)
	await get_tree().process_frame
	var before_fish: int = GameState.storage.size()
	var f1 := InputEventKey.new()
	f1.pressed = true
	f1.physical_keycode = KEY_F1
	room._unhandled_key_input(f1)
	assert(GameState.storage.size() == before_fish + room.fish_catalog.fish.size(), "F1 did not add every fish")
	assert(room.planning_panel.visible, "planning panel closed after F1")
	var beer: DishData = load("res://data/dishes/bia_con_meo.tres")
	var before_beer: int = room.market_stock.count(beer)
	var f2 := InputEventKey.new()
	f2.pressed = true
	f2.physical_keycode = KEY_F2
	room._unhandled_key_input(f2)
	assert(room.market_stock.count(beer) == before_beer + beer.buy_units(beer.has_bulk()), "F2 did not stock beer")
	var f4 := InputEventKey.new()
	f4.pressed = true
	f4.physical_keycode = KEY_F4
	room._unhandled_key_input(f4)
	assert(WaveMark.has_power() and room.wave_power.charges == WaveMark.max_charges(), "F4 did not grant Nhịp Sóng")
	assert(room.orders.size() == 4, "base seats upgrade should provide four tables")
	room.rng.seed = 42
	var plain_interval: float = room._next_spawn_interval()
	GameState.upgrade_levels["decor"] = 2
	room.rng.seed = 42
	assert(room._next_spawn_interval() < plain_interval, "decor should attract guests faster")
	room.queue_free()
	await get_tree().process_frame
	GameState.upgrade_levels["seats"] = 2
	GameState.set_flag("cat_adopted")
	var upgraded: Node3D = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	add_child(upgraded)
	assert(upgraded.orders.size() == 8, "seats level 2 should provide eight tables")
	assert(upgraded.cat_node != null, "adopted cat should appear in the 3D restaurant")
	print("PASS restaurant3d debug F1 fish, F2 drinks, F4 Nhịp Sóng, seats and cat")
	get_tree().quit()
