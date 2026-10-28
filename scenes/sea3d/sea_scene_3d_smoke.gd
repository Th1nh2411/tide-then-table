extends Node
## Run as sea_scene_3d_smoke.tscn so project autoloads are available.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	GameState.reset()
	var sea := (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate()
	add_child(sea)
	await get_tree().process_frame
	sea.new_catch_card.queue_free()
	sea.new_catch_card = null
	var fish: FishData = sea.fish_catalog.fish[0]
	sea._on_catch_detailed(fish, true, 1.0, 1, 1.0)
	var state := GameState
	var passed: bool = sea.hold.items.size() == 1 and int(state.caught_species.get(fish.id, 0)) == 1
	sea._unload()
	passed = passed and sea.hold.items.is_empty() and state.storage.size() == 1
	Input.action_press("throttle_forward")
	var start_z: float = sea.boat.position.z
	for i in range(45):
		await get_tree().physics_frame
	Input.action_release("throttle_forward")
	passed = passed and sea.boat.position.z < start_z - 0.2
	passed = passed and sea.map_boat_proxy != null and sea.phone_app != null
	sea.boat.position = Vector3(0, 0, 0)
	sea.boat.velocity = Vector3.ZERO
	sea._drop_net()
	passed = passed and sea.nets.size() == 1
	var tom: FishData = load("res://data/fish/tom.tres")
	var oc: FishData = load("res://data/fish/oc_huong.tres")
	var tom_before := int(state.caught_species.get(tom.id, 0))
	var oc_before := int(state.caught_species.get(oc.id, 0))
	sea.net_haul.clear()
	sea.net_haul.append([tom, 1.0])
	sea.net_haul.append([oc, 1.0])
	sea.net_haul_count = 2
	sea._on_catch_detailed(tom, true, 1.0, 2, 1.0)
	passed = passed and int(state.caught_species.get(tom.id, 0)) == tom_before + 1
	passed = passed and int(state.caught_species.get(oc.id, 0)) == oc_before + 1
	var had_wave := WaveMark.has_power()
	var f4 := InputEventKey.new()
	f4.pressed = true
	f4.physical_keycode = KEY_F4
	sea._unhandled_input(f4)
	passed = passed and WaveMark.has_power() != had_wave
	print("%s SeaScene3D smoke" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)
