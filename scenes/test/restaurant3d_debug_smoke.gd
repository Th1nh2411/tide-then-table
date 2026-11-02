extends Node
## Verifies the 3D restaurant's debug keys (F4 Nhịp Sóng), seat upgrades and the cat.

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	var room: Node3D = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	room.auto_open = false
	add_child(room)
	await get_tree().process_frame
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
	assert(room._has_stock(), "the fixed menu is always available")
	room.queue_free()
	await get_tree().process_frame
	GameState.upgrade_levels["seats"] = 2
	GameState.set_flag("cat_adopted")
	var upgraded: Node3D = load("res://scenes/restaurant3d/restaurant_scene_3d.tscn").instantiate()
	upgraded.auto_open = false
	add_child(upgraded)
	assert(upgraded.orders.size() == 8, "seats level 2 should provide eight tables")
	assert(upgraded.cat_node != null, "adopted cat should appear in the 3D restaurant")
	print("PASS restaurant3d debug F4 Nhịp Sóng, fixed menu, seats and cat")
	get_tree().quit()
