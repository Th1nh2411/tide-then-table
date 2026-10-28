extends Node
## Nested inventory pause, retained stun, and fainting across a real minigame.

var _failures: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _frames(count: int) -> void:
	for i: int in range(count):
		await get_tree().process_frame

func _check(ok: bool, words: String) -> void:
	print(("PASS " if ok else "FAIL ") + words)
	if not ok:
		_failures += 1

func _run() -> void:
	GameState.reset()
	var overlay: FishingOverlay3D = load("res://scenes/fishing3d/fishing_overlay_3d.tscn").instantiate()
	var hold_ui: HoldUI = load("res://scenes/ui/hold_ui.tscn").instantiate()
	add_child(hold_ui)
	hold_ui.setup(GridInventory.new(Vector2i(4, 4)))
	add_child(overlay)
	overlay.bind_hold(hold_ui)
	var fish: FishData = load("res://data/fish/ca_thu.tres")
	overlay.trip_stun = 0.42
	overlay._minigame.result_seconds = 0.01
	overlay.start_catch(fish)
	var fight := overlay._minigame._game as FishFightGame
	_check(is_equal_approx(fight.stun, 0.42), "3D fishing retains trip stun")
	overlay._open_hold()
	_check(hold_ui.visible and get_tree().paused, "hold opens during fishing without resuming boat")
	_check(overlay._minigame.process_mode == Node.PROCESS_MODE_DISABLED and hold_ui.layer > overlay.layer,
		"sorting suspends fight and inventory renders above fishing viewport")
	await _frames(6)
	hold_ui.close()
	_check(get_tree().paused and overlay.active, "closing nested hold preserves fishing pause")
	_check(overlay._minigame.process_mode == Node.PROCESS_MODE_ALWAYS, "fight resumes after sorting")
	fight.stun = 0.65
	fight._finish(false, false)
	await _frames(10)
	_check(not overlay.active and not get_tree().paused and is_equal_approx(overlay.trip_stun, 0.65),
		"failed cast preserves stun and restores world")
	var results: Array[String] = []
	overlay.catch_detailed.connect(func(_fish: FishData, _caught: bool, _quality: float, _count: int, _size: float) -> void:
		results.append("catch"))
	overlay.catch_finished.connect(func(_caught: bool, _fish: FishData) -> void: results.append("finished"))
	overlay.rin_fainted.connect(func() -> void: results.append("fainted"))
	overlay.start_catch(fish)
	fight = overlay._minigame._game as FishFightGame
	fight.stun = 1.0
	fight.rin_fainted.emit()
	fight._finish(false, false)
	await _frames(10)
	_check(results == ["catch", "finished", "fainted"], "faint rescue emits after fishing result and release")
	_check(not get_tree().paused, "faint leaves world unpaused for rescue")
	get_tree().quit(1 if _failures else 0)
