class_name FishFightGame
extends MinigameBase
## One cast shows a small school. A/D moves the boat, W/S raises/lowers the
## hook, and a fish bites by itself after the hook stays close long enough.
## Full screen; FishFightView draws it (this script is the rules only).

signal tugged
signal rin_fainted
signal fish_hooked(size_scale: float)
signal yanked(result: YankResult)
## The boat hit the side of the screen hard (splash, shake).
signal boat_bumped
## Two fish knocked into each other this step (`at` in arena units).
signal fish_bumped(at: Vector2)

enum YankResult { GREEN, YELLOW, RED }

@export_group("Free hook")
@export var school_size: int = 6
## Boat: top speed, push from A/D and water drag (it glides, then stops).
@export var boat_speed: float = 0.85
@export var boat_accel: float = 4.0
@export var boat_drag: float = 2.5
## Hook depth: top speed, push from W/S, drag, and the bait's slow sink.
@export var hook_depth_speed: float = 0.42
@export var hook_accel: float = 3.0
@export var hook_drag: float = 4.0
@export var hook_sink: float = 0.03
@export var hook_radius: float = 0.14
@export var bite_seconds: float = 0.35
## Spring and drag use normalized arena units. Together they make the line
## lag, overshoot, and settle instead of being glued to the moving boat.
@export var line_spring: float = 12.0
@export var line_drag: float = 3.0
@export var line_max_sway: float = 0.38
@export var fish_speed_easy: float = 0.12
@export var fish_speed_hard: float = 0.25
## How fast fish swing round (units/s²) and drift up and down (units/s).
@export var fish_turn_accel: float = 0.5
@export var fish_drift: float = 0.03
@export_group("Haul")
@export var reel_speed: float = 0.13
@export var give_slack_speed: float = 0.1
@export var tension_recovery: float = 0.28
@export var base_tension_gain: float = 0.04
@export var bad_angle_gain: float = 0.3
@export var fail_seconds: float = 30.0
@export_group("Balance")
@export var balance_speed: float = 1.6
@export var edge_stun_per_second: float = 0.15
@export var fall_stun: float = 0.16
@export_group("Yank wheel")
@export var yank_min_green: float = 0.05
@export var yank_max_green: float = 0.84
@export var yank_spin_seconds: float = 0.75
@export var yank_spin_turns: Vector2i = Vector2i(3, 5)
@export var random_seed: int = 0

var boat_position: float = 0.0
var hook_position: Vector2 = Vector2(0.0, 0.08)
var progress: float = 0.0
var tension: float = 0.12
var balance: float = 0.0
var stun: float = 0.0
var hooked_index: int = -1
var yank_spinning: bool = false
var school: Array[Dictionary] = []
## W held during the fight (reel clicks).
var reeling: bool = false
## FishData.Zone of the spot: picks the sea backdrop.
var zone: int = 0
## BoatData id of Rin's boat (how the fishing screen draws it).
var boat_id: String = "thuyen_thung"

var _hook_velocity_x: float = 0.0
var _hook_velocity_y: float = 0.0
var _boat_velocity: float = 0.0
var _bite_candidate: int = -1
var _bite_elapsed: float = 0.0
var _fight_time: float = 0.0
var _fall_cooldown: float = 0.0
var _max_tension: float = 0.12
var _wheel_elapsed: float = 0.0
var _wheel_from: float = -PI * 0.5
var _wheel_to: float = -PI * 0.5
var _pointer_angle: float = -PI * 0.5
var _wheel_roll: float = 0.0
var _rng := RandomNumberGenerator.new()
var _view := FishFightView.new(self)
var _feel := FishFightFeel.new(self)


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()
	_spawn_school()
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Keeps animating after the result (the fish lands in the boat).
func _process(delta: float) -> void:
	_view.tick(delta)
	_feel.tick(delta)
	if _feel.hitstop > 0.0:  # the bite freezes the fight for a few frames
		_feel.hitstop -= delta
		queue_redraw()
		return
	super(delta)
	if _done:
		_time += delta
		queue_redraw()


func _finish(success: bool, perfect: bool) -> void:
	if not _done:
		_feel.on_finish(success)
		if success and hooked_index >= 0:
			_view.land()
	super(success, perfect)


func _exit_tree() -> void:
	_feel.stop()


func get_hint() -> String:
	if hooked_index < 0:
		return "A/D: đưa thuyền · W/S: nâng/hạ lưỡi · Giữ lưỡi gần cá để cá tự cắn"
	return "A/D: chạy theo cá · W: kéo lên · S: nhả dây · E: tất tay"


func get_status_text() -> String:
	if hooked_index < 0:
		if _bite_candidate >= 0:
			return "Cá đang ngửi mồi... %d%%" % roundi(bite_progress() * 100.0)
		return "Đưa lưỡi câu lại gần con cá muốn bắt"
	var text := "Kéo %d%%  Dây %d%%  Choáng %d%%" % [roundi(progress * 100.0),
		roundi(tension * 100.0), roundi(stun * 100.0)]
	return text + (" · Đang giật tất tay..." if yank_spinning else "")


func get_fail_text() -> String:
	if stun >= 1.0:
		return "Rin bất tỉnh!"
	return "Đứt dây!" if tension >= 1.0 else "Cá vùng thoát mất..."


func _update(delta: float) -> void:
	var depth_axis := Input.get_axis("throttle_forward", "throttle_back")
	step_fight(delta, Input.get_axis("turn_left", "turn_right"), depth_axis,
		false, Input.is_action_just_pressed("interact"))


## Public for deterministic tests. `depth`: -1 raises, +1 lowers the hook.
## `_manual_hook` is retained for call-site compatibility but intentionally
## ignored: pressing the old hook button can never catch a fish.
func step_fight(delta: float, steer: float, depth: float, _manual_hook: bool = false,
		yank: bool = false) -> void:
	if _done:
		return
	if yank_spinning:
		_update_wheel(delta)
		return
	_move_boat(delta, steer)
	var bumps := FishSchoolPhysics.step(school, hooked_index, delta, _time, fish_turn_accel, fish_drift)
	if not bumps.is_empty():
		fish_bumped.emit(bumps[0])
	if hooked_index < 0:
		_move_free_hook(delta, depth)
		_update_auto_bite(delta)
	else:
		_fight_time += delta
		_haul_hooked_fish(delta, depth)
		_update_balance(delta, depth < -0.05)
		if yank:
			start_yank_spin()
	_check_result()


func _spawn_school() -> void:
	school.clear()
	for i in school_size:
		var size_scale := _rng.randf_range(0.78, 1.28)
		school.append({
			"pos": Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(0.25, 0.95)),
			"speed": _rng.randf_range(fish_speed_easy, lerpf(fish_speed_easy, fish_speed_hard, fish.difficulty)),
			"dir": -1.0 if _rng.randf() < 0.5 else 1.0,
			"size": size_scale,
			"phase": _rng.randf_range(0.0, TAU),
		})
		school[i]["vx"] = float(school[i]["dir"]) * float(school[i]["speed"])


## Glides with inertia; hitting the side of the screen bounces it back.
func _move_boat(delta: float, steer: float) -> void:
	_boat_velocity += steer * boat_accel * delta
	_boat_velocity = clampf(_boat_velocity * exp(-boat_drag * delta), -boat_speed, boat_speed)
	boat_position += _boat_velocity * delta
	if absf(boat_position) >= 1.0:
		boat_position = clampf(boat_position, -1.0, 1.0)
		if absf(_boat_velocity) > 0.3:
			boat_bumped.emit()
		_boat_velocity *= -0.3


func _move_free_hook(delta: float, depth: float) -> void:
	# Weighted bait: W/S push it, water drags it, it sinks slowly on its own.
	var push := depth * hook_accel if absf(depth) > 0.05 else hook_sink
	_hook_velocity_y = clampf((_hook_velocity_y + push * delta) * exp(-hook_drag * delta),
		-hook_depth_speed, hook_depth_speed)
	hook_position.y += _hook_velocity_y * delta
	if hook_position.y < 0.05 or hook_position.y > 1.0:
		hook_position.y = clampf(hook_position.y, 0.05, 1.0)
		_hook_velocity_y = 0.0
	# A fish brushing past knocks the hook along.
	_hook_velocity_x += FishSchoolPhysics.hook_nudge(school, hook_position) * delta * 6.0
	# Damped spring pendulum: moving the boat pulls the line, while inertia lets
	# the hook trail behind and swing past the resting point when the boat stops.
	_hook_velocity_x += (boat_position - hook_position.x) * line_spring * delta
	_hook_velocity_x *= exp(-line_drag * delta)
	hook_position.x += _hook_velocity_x * delta
	var max_sway := lerpf(line_max_sway * 0.35, line_max_sway, hook_position.y)
	var limited_x := clampf(hook_position.x, boat_position - max_sway, boat_position + max_sway)
	if not is_equal_approx(limited_x, hook_position.x):
		hook_position.x = limited_x
		_hook_velocity_x *= -0.2
	hook_position.x = clampf(hook_position.x, -1.0, 1.0)


func _update_auto_bite(delta: float) -> void:
	var nearest := -1
	var nearest_distance := INF
	for i in school.size():
		var pos: Vector2 = school[i]["pos"]
		var distance := hook_position.distance_to(pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = i
	if nearest < 0 or nearest_distance > hook_radius:
		_bite_candidate = -1
		_bite_elapsed = 0.0
		return
	if nearest != _bite_candidate:
		_bite_candidate = nearest
		_bite_elapsed = 0.0
	# A long frame may place the hook inside the radius only at its end; cap the
	# contribution so a hitch cannot turn that single sample into an instant bite.
	_bite_elapsed += minf(delta, 0.05)
	if _bite_elapsed < bite_seconds:
		return
	_hook_fish(nearest)


func _hook_fish(index: int) -> void:
	hooked_index = index
	hook_position = school[index]["pos"]
	_hook_velocity_x = 0.0
	_hook_velocity_y = 0.0
	var size_scale: float = school[index]["size"]
	fish_hooked.emit(size_scale)
	tugged.emit()
	Sfx.play("bite")


func bite_progress() -> float:
	return clampf(_bite_elapsed / maxf(bite_seconds, 0.001), 0.0, 1.0) if _bite_candidate >= 0 else 0.0


func _haul_hooked_fish(delta: float, depth: float) -> void:
	var entry: Dictionary = school[hooked_index]
	var pos: Vector2 = entry["pos"]
	reeling = depth < -0.05
	if reeling:
		pos.y -= reel_speed * zone_scale * delta
		var pull := 1.0 + float(entry["size"]) * 0.35
		tension += (base_tension_gain + (1.0 - alignment()) * bad_angle_gain) * pull / zone_scale * delta
	elif depth > 0.05:
		pos.y = minf(pos.y + give_slack_speed * delta, 1.0)
		tension -= tension_recovery * zone_scale * delta
	else:
		tension -= tension_recovery * 0.45 * zone_scale * delta
	entry["pos"] = pos
	hook_position = pos
	progress = 1.0 - pos.y


func alignment() -> float:
	if hooked_index < 0:
		return 1.0
	var fish_x: float = (school[hooked_index]["pos"] as Vector2).x
	return 1.0 - clampf(absf(fish_x - boat_position) * 0.65, 0.0, 1.0)


func _update_balance(delta: float, reeling: bool) -> void:
	_fall_cooldown = maxf(_fall_cooldown - delta, 0.0)
	var fish_x: float = (school[hooked_index]["pos"] as Vector2).x
	var pull := (fish_x - boat_position) * (1.2 if reeling else 0.55)
	balance = move_toward(balance, clampf(pull, -1.1, 1.1), balance_speed * delta)
	if absf(balance) > 0.8:
		stun += edge_stun_per_second * delta
	if absf(balance) >= 0.98 and _fall_cooldown <= 0.0:
		stun += fall_stun
		var entry: Dictionary = school[hooked_index]
		var pos: Vector2 = entry["pos"]
		pos.y = minf(pos.y + 0.07, 1.0)
		entry["pos"] = pos
		balance *= 0.45
		_fall_cooldown = 0.8
		tugged.emit()


func _check_result() -> void:
	progress = clampf(progress, 0.0, 1.0)
	tension = clampf(tension, 0.0, 1.0)
	stun = clampf(stun, 0.0, 1.0)
	_max_tension = maxf(_max_tension, tension)
	if stun >= 1.0:
		rin_fainted.emit()
		_finish(false, false)
	elif hooked_index >= 0 and progress >= 0.96:
		_finish(true, _max_tension < 0.65 and stun < 0.45)
	elif tension >= 1.0 or (hooked_index >= 0 and _fight_time >= fail_seconds):
		_finish(false, false)


func yank_green_chance() -> float:
	if hooked_index < 0:
		return 0.0
	var size_scale: float = school[hooked_index]["size"]
	var chance := 0.06 + progress * 0.66 + alignment() * 0.2 - tension * 0.24 \
		- absf(balance) * 0.16 - stun * 0.2 - (size_scale - 1.0) * 0.12
	return clampf(chance * minf(zone_scale, 1.3), yank_min_green, yank_max_green)


func yank_yellow_chance() -> float:
	return minf(0.2 + progress * 0.1, 0.32) if hooked_index >= 0 else 0.0


func start_yank_spin(roll: float = -1.0) -> void:
	if yank_spinning or _done or hooked_index < 0:
		return
	_wheel_roll = _rng.randf() if roll < 0.0 else clampf(roll, 0.0, 0.9999)
	_wheel_elapsed = 0.0
	_wheel_from = _pointer_angle
	var turns := _rng.randi_range(yank_spin_turns.x, yank_spin_turns.y)
	_wheel_to = -PI * 0.5 + _wheel_roll * TAU + turns * TAU
	yank_spinning = true
	Sfx.play("blip")


func _update_wheel(delta: float) -> void:
	_wheel_elapsed += delta
	var t := clampf(_wheel_elapsed / yank_spin_seconds, 0.0, 1.0)
	_pointer_angle = lerpf(_wheel_from, _wheel_to, 1.0 - pow(1.0 - t, 3.0))
	if t >= 1.0:
		yank_spinning = false
		_pointer_angle = -PI * 0.5 + _wheel_roll * TAU
		resolve_yank(_wheel_roll)
		_check_result()


func resolve_yank(roll: float) -> YankResult:
	var result := YankResult.RED
	if roll <= yank_green_chance():
		result = YankResult.GREEN
		progress = 1.0
		_finish(true, _max_tension < 0.65 and stun < 0.45)
	elif roll <= yank_green_chance() + yank_yellow_chance():
		result = YankResult.YELLOW
		var entry: Dictionary = school[hooked_index]
		var pos: Vector2 = entry["pos"]
		pos.y = maxf(pos.y - 0.16, 0.0)
		entry["pos"] = pos
		progress = 1.0 - pos.y
		stun += 0.1
		balance += float(entry["dir"]) * 0.18
	else:
		var entry: Dictionary = school[hooked_index]
		var pos: Vector2 = entry["pos"]
		pos.y = minf(pos.y + 0.12, 1.0)
		entry["pos"] = pos
		progress = 1.0 - pos.y
		tension += 0.22
		stun += 0.24
		balance += float(entry["dir"]) * 0.4
	yanked.emit(result)
	tugged.emit()
	return result


func _draw() -> void:
	_view.draw()
