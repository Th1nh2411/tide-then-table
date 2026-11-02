extends Node
## Standalone test for the first-person rod (Fishing3D) in the real sea scene
## (run with F6): cast lands the bobber in reach, an early click reels in, a
## late click loses the bite, a hooked fish reels in and is held, no cast
## while holding, E while looking at the basket drops it in, holding the
## reel too long snaps the line, nothing bites in the pier water.

const SEA := "res://scenes/sea3d/sea_scene_3d.tscn"
const STEP := 1.0 / 30.0

var _failures := 0
var _sea: SeaScene3D
var _rod: Fishing3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	GameState.day = 2
	_sea = (load(SEA) as PackedScene).instantiate() as SeaScene3D
	add_child(_sea)
	await get_tree().process_frame
	_rod = _sea.get_node_or_null(Fishing3D.NODE_NAME) as Fishing3D
	_check("the sea has a rod and a basket in the thúng", _rod != null and _rod.basket.get_parent() == _sea.boat_visual)
	if _rod == null:
		get_tree().quit(1)
		return
	_rod.set_process(false)  # this test steps it by hand
	var shoal: SeaShoals3D.Shoal = _sea.shoals[_sea._nearest_school_index()]
	shoal.fish_left = 3
	_sea.boat.global_position = shoal.pos + Vector3(0, 0, 8.0)
	_cast_and_land(shoal.pos)
	_check("a cast lands the bobber on the water and waits", _rod.state == Fishing3D.State.WAITING
		and _rod.rod.bobber.visible and _sea.fishing and absf(_rod.target.y - FishingSpot3D.WATER_Y) < 0.01)
	_rod.press()
	_check("clicking before a bite reels the line back in", _rod.state == Fishing3D.State.IDLE
		and not _rod.rod.bobber.visible and not _sea.fishing)
	_cast_and_land(shoal.pos)
	_rod.force_bite()
	_check("a bite shows the ! over the bobber", _rod.state == Fishing3D.State.BITE and _rod.rod.mark.visible)
	_ticks(1.4)
	_check("too late: the fish is gone, the bobber waits again", _rod.state == Fishing3D.State.WAITING and not _rod.rod.mark.visible)
	_rod.force_bite()
	_rod.press()
	_check("a click in the window hooks the fish (one leaves the shoal)", _rod.state == Fishing3D.State.REELING and shoal.fish_left == 2)
	var fish := _rod.fish
	_reel_smart()
	_check("reeling with care lands it, held in front of the view", _rod.state == Fishing3D.State.HOLDING
		and _rod.rod.holding_fish() and fish != null and GameState.caught_species.has(fish.id))
	_rod.press()
	_check("no casting while holding a fish", _rod.state == Fishing3D.State.HOLDING)
	_look_at(_rod.basket.mouth() + Vector3(2.0, 0, 0))
	_press_e()
	_check("E while looking away does nothing", _rod.state == Fishing3D.State.HOLDING and _rod.basket.count() == 0)
	_look_at(_rod.basket.mouth())
	_check("looking down at the basket", _rod.looking_at_basket())
	_press_e()
	_check("E drops the fish in the basket", _rod.state == Fishing3D.State.IDLE and _rod.basket.count() == 1
		and not _rod.rod.holding_fish())
	_cast_and_land(shoal.pos)
	_rod.force_bite()
	_rod.hook()
	_rod.hold_override = true
	_ticks(20.0, Fishing3D.State.REELING)
	_rod.hold_override = false
	_check("holding the reel too long snaps the line", _rod.state == Fishing3D.State.IDLE and _rod.basket.count() == 1)
	_check_aim()
	_sea.boat.global_position = _sea.START
	_cast_and_land(_sea.START + Vector3(0, 0, -7.0))
	_ticks(12.0, Fishing3D.State.WAITING)
	_check("nothing bites in the pier water", _rod.state == Fishing3D.State.WAITING)
	_rod.reel_in()
	_sea.queue_free()
	GameState.reset()
	print("FISHING 3D TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


func _check_aim() -> void:
	var camera := get_viewport().get_camera_3d()
	var eye := _sea.boat.global_position + Vector3(0, 1.4, 0)
	camera.global_transform = Transform3D(Basis.IDENTITY, eye).looking_at(eye + Vector3(0, -1.0, -0.3))
	var near := FishingSpot3D.flat_distance(_sea, _rod.aim())
	camera.global_transform = Transform3D(Basis.IDENTITY, eye).looking_at(eye + Vector3(0, 0.2, -1.0))
	var far := FishingSpot3D.flat_distance(_sea, _rod.aim())
	_check("aim: looking down lands at the shortest cast, up at the longest",
		is_equal_approx(near, _rod.tuning.cast_min) and is_equal_approx(far, _rod.tuning.cast_max))


func _cast_and_land(at: Vector3) -> void:
	_rod.cast(at)
	_ticks(2.0, Fishing3D.State.CASTING)


func _reel_smart() -> void:
	for i in range(int(60.0 / STEP)):
		if _rod.state != Fishing3D.State.REELING:
			break
		_rod.hold_override = _rod.reel.tension < (0.45 if _rod.reel.running else 0.75)
		_rod.tick(STEP)
	_rod.hold_override = false


## Ticks for `seconds`, or until the state leaves `while_state` if given.
func _ticks(seconds: float, while_state: int = -1) -> void:
	for i in range(int(seconds / STEP)):
		if while_state >= 0 and _rod.state != while_state:
			return
		_rod.tick(STEP)


func _look_at(point: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	var eye := _sea.rin_figure[0].global_position + Vector3(0, FirstPersonView3D.EYE_SEA, 0)
	camera.global_transform = Transform3D(Basis.IDENTITY, eye).looking_at(point)


func _press_e() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	_rod._unhandled_input(key)


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
