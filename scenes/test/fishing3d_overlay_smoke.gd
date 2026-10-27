extends Node
## Run with: godot --headless --path . --scene res://scenes/test/fishing3d_overlay_smoke.tscn

func _ready() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load("res://scenes/fishing3d/fishing_overlay_3d.tscn")
	var overlay: FishingOverlay3D = packed.instantiate()
	add_child(overlay)
	await get_tree().process_frame
	var fish: FishData = load("res://data/fish/ca_mu.tres")
	var seen: Array = []
	overlay.catch_detailed.connect(func(_fish: FishData, caught: bool, quality: float, count: int, size: float) -> void:
		seen.append(["detailed", caught, quality, count, size]))
	overlay.catch_finished.connect(func(caught: bool, _fish: FishData) -> void:
		seen.append(["finished", caught]))
	overlay.start_catch(fish)
	if not get_tree().paused or not overlay.active:
		_fail("start_catch did not pause the 3D world")
		return
	Input.action_press("throttle_forward")
	overlay._on_minigame_finished(fish, true, 0.7, 1)
	for i in 3:
		await get_tree().process_frame
	if not get_tree().paused or not overlay.active or not seen.is_empty():
		_fail("held throttle resumed the world before release")
		return
	Input.action_release("throttle_forward")
	for i in 4:
		await get_tree().process_frame
	if get_tree().paused or overlay.active or seen.size() != 2:
		_fail("release did not restore world and emit both results")
		return
	if seen[0][0] != "detailed" or seen[1][0] != "finished" or not seen[1][1]:
		_fail("catch result order or value was wrong")
		return
	print("PASS fishing3d overlay pause, held input, release, result order")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	Input.action_release("throttle_forward")
	get_tree().paused = false
	get_tree().quit(1)
