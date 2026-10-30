extends Node
## Basket boat (thúng) rowing: pushed only during a stroke's pull, strokes
## finish once started, then the boat glides to a stop; Rin's Row pose and
## the paddle follow the stroke.

var failures: int = 0

func check(value: bool, label: String) -> void:
	print("PASS " + label if value else "FAIL " + label)
	if not value:
		failures += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var data := load("res://data/boats/thuyen_thung.tres") as BoatData
	check(data.rowed, "thúng is a rowed boat")
	check(not (load("res://data/boats/ghe_may.tres") as BoatData).rowed, "motor boat is not rowed")
	var row := RowStroke.new()
	check(row.step(0.1, 0.0, 0.0, data) == Vector2.ZERO and not row.active, "no keys, no stroke")
	var total := Vector2.ZERO
	var early := row.step(0.1, 1.0, 0.0, data)
	total += early
	check(is_zero_approx(early.x), "catch (first 0.1 s) does not push yet")
	for i in 9:
		total += row.step(0.1, 0.0, 0.0, data)  # keys released mid-stroke
	check(is_equal_approx(total.x, data.stroke_push), "one stroke adds exactly stroke_push, even after release")
	check(not row.active, "stroke ends and stops when nothing is held")
	total = Vector2.ZERO
	row = RowStroke.new()
	for i in 10:
		total += row.step(0.1, 0.0, 1.0, data)
	check(is_equal_approx(total.y, data.stroke_turn) and total.x > 0.0 and total.x < data.stroke_push * 0.5,
		"side stroke turns a full stroke_turn and only nudges forward")
	total = Vector2.ZERO
	row = RowStroke.new()
	for i in 10:
		total += row.step(0.1, -1.0, 0.0, data)
	check(total.x < 0.0 and absf(total.x) < data.stroke_push, "backstroke is weaker")
	await _scene_checks()
	get_tree().quit(1 if failures > 0 else 0)

func _scene_checks() -> void:
	GameState.reset()
	var sea := (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	sea.set_physics_process(false)
	await get_tree().process_frame
	check(sea.paddle != null, "thúng rider holds a paddle")
	sea.boat.position = SeaLayout3D.to_world(Vector2(700, 1000))
	sea._wait_controls_release = false
	Input.action_press("throttle_forward")
	var dt := 1.0 / 60.0
	for i in 6:
		sea._physics_process(dt)
	var during_catch := sea.boat.velocity.length()
	var paddle_before := sea.paddle.position
	for i in 24:
		sea._physics_process(dt)
	var paddle_mid := sea.paddle.position
	for i in 30:
		sea._physics_process(dt)
	var after_stroke := sea.boat.velocity.length()
	check(during_catch < 0.05, "boat still while the paddle reaches forward")
	check(after_stroke > 1.0, "one stroke moves the boat")
	check(paddle_mid.distance_to(paddle_before) > 0.1, "paddle moves with the stroke")
	Input.action_release("throttle_forward")
	for i in 240:
		sea._physics_process(dt)
	check(sea.boat.velocity.length() < 0.1, "boat glides to a stop without strokes")
	sea.queue_free()
