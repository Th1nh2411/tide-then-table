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
	var passed: bool = sea.rod != null and sea.rod.basket.count() == 0 and sea.rod.state == Fishing3D.State.IDLE
	Input.action_press("throttle_forward")
	var start_z: float = sea.boat.position.z
	for i in range(45):
		await get_tree().physics_frame
	Input.action_release("throttle_forward")
	passed = passed and sea.boat.position.z < start_z - 0.2
	passed = passed and sea.boat_data != null and sea.boat_data.id == "thuyen_thung"
	print("%s SeaScene3D smoke" % ("PASS" if passed else "FAIL"))
	get_tree().quit(0 if passed else 1)
