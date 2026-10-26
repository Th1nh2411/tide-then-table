class_name FishFightGame
extends MinigameBase
## One cast shows a small school. A/D moves the boat and line sideways, W/S
## raises/lowers the hook, and Space hooks the fish the player actually aims at.

signal tugged
signal rin_fainted
signal fish_hooked(size_scale: float)

enum YankResult { GREEN, YELLOW, RED }

@export_group("Free hook")
@export var school_size: int = 6
@export var boat_speed: float = 1.2
@export var hook_follow_speed: float = 1.65
@export var hook_depth_speed: float = 0.58
@export var hook_radius: float = 0.14
@export var snap_cooldown: float = 0.3
@export var fish_speed_easy: float = 0.16
@export var fish_speed_hard: float = 0.32
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

var _snap_left: float = 0.0
var _fight_time: float = 0.0
var _fall_cooldown: float = 0.0
var _max_tension: float = 0.12
var _wheel_elapsed: float = 0.0
var _wheel_from: float = -PI * 0.5
var _wheel_to: float = -PI * 0.5
var _pointer_angle: float = -PI * 0.5
var _wheel_roll: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()
	_spawn_school()
	custom_minimum_size = Vector2(310, 184)


func get_hint() -> String:
	if hooked_index < 0:
		return "A/D: đưa thuyền · W/S: nâng/hạ lưỡi · Space: móc cá"
	return "A/D: chạy theo cá · W: kéo lên · S: nhả dây · E: tất tay"


func get_status_text() -> String:
	if hooked_index < 0:
		return "Đưa lưỡi chạm con cá muốn bắt rồi bấm Space"
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
		_cast_just_pressed(), Input.is_action_just_pressed("interact"))


## Public for deterministic tests. `depth`: -1 raises, +1 lowers the hook.
func step_fight(delta: float, steer: float, depth: float, snap: bool = false,
		yank: bool = false) -> void:
	if _done:
		return
	if yank_spinning:
		_update_wheel(delta)
		return
	_snap_left = maxf(_snap_left - delta, 0.0)
	boat_position = clampf(boat_position + steer * boat_speed * delta, -1.0, 1.0)
	_update_school(delta)
	if hooked_index < 0:
		_move_free_hook(delta, depth)
		if snap and _snap_left <= 0.0:
			_try_hook()
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


func _update_school(delta: float) -> void:
	for i in school.size():
		var entry: Dictionary = school[i]
		var pos: Vector2 = entry["pos"]
		var direction: float = entry["dir"]
		var speed: float = entry["speed"]
		# A hooked fish fights harder when it is large, but still obeys the same
		# simple movement as every other fish—there are no hidden states.
		if i == hooked_index:
			speed *= 1.0 + float(entry["size"]) * 0.35
		pos.x += direction * speed * delta
		if absf(pos.x) >= 1.0:
			pos.x = clampf(pos.x, -1.0, 1.0)
			entry["dir"] = -direction
		entry["pos"] = pos


func _move_free_hook(delta: float, depth: float) -> void:
	hook_position.x = move_toward(hook_position.x, boat_position, hook_follow_speed * delta)
	hook_position.y = clampf(hook_position.y + depth * hook_depth_speed * delta, 0.05, 1.0)


func _try_hook() -> void:
	_snap_left = snap_cooldown
	var nearest := -1
	var nearest_distance := INF
	for i in school.size():
		var pos: Vector2 = school[i]["pos"]
		var distance := hook_position.distance_to(pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = i
	if nearest < 0 or nearest_distance > hook_radius:
		# A miss flicks the hook upward so repeated tapping is not optimal.
		hook_position.y = maxf(hook_position.y - 0.08, 0.05)
		Sfx.play("blip")
		return
	hooked_index = nearest
	hook_position = school[nearest]["pos"]
	var size_scale: float = school[nearest]["size"]
	fish_hooked.emit(size_scale)
	tugged.emit()
	Sfx.play("bite")


func _haul_hooked_fish(delta: float, depth: float) -> void:
	var entry: Dictionary = school[hooked_index]
	var pos: Vector2 = entry["pos"]
	var reeling := depth < -0.05
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
	tugged.emit()
	return result


func _draw() -> void:
	var origin := _centered_origin(Vector2(310, 172))
	var arena := Rect2(origin, Vector2(235, 122))
	draw_rect(arena, Color(0.035, 0.14, 0.24))
	for i in 5:
		var y := arena.position.y + 18.0 + i * 23.0
		draw_line(Vector2(arena.position.x + 4, y), Vector2(arena.end.x - 4, y), Color(0.2, 0.55, 0.65, 0.16))
	var boat_x := lerpf(arena.position.x + 14.0, arena.end.x - 14.0, (boat_position + 1.0) * 0.5)
	var boat_pos := Vector2(boat_x, arena.position.y + 13.0)
	var hook_pos := _to_screen(hook_position, arena)
	draw_line(boat_pos, hook_pos, Color(1.0, 0.86, 0.55, 0.9), 1.0)
	_draw_boat(boat_pos)
	for i in school.size():
		_draw_fish(_to_screen(school[i]["pos"], arena), school[i], i == hooked_index)
	draw_circle(hook_pos, 3.0, Color.WHITE)
	draw_arc(hook_pos, 6.0, 0.0, TAU, 16, Color(1.0, 0.85, 0.35), 1.0)
	_draw_wheel(Vector2(arena.end.x + 38.0, arena.position.y + 52.0))
	_draw_bar(Rect2(origin.x, arena.end.y + 8.0, 145.0, 7.0), progress, _tint(fish.color), "Kéo")
	_draw_bar(Rect2(origin.x + 158.0, arena.end.y + 8.0, 145.0, 7.0), tension, Color(1.0, 0.55, 0.2), "Dây")
	_draw_balance(Rect2(origin.x, arena.end.y + 28.0, 145.0, 7.0))
	_draw_bar(Rect2(origin.x + 158.0, arena.end.y + 28.0, 145.0, 7.0), stun, Color(0.75, 0.4, 1.0), "Choáng")


func _to_screen(pos: Vector2, arena: Rect2) -> Vector2:
	return Vector2(lerpf(arena.position.x + 10.0, arena.end.x - 10.0, (pos.x + 1.0) * 0.5),
		lerpf(arena.position.y + 25.0, arena.end.y - 8.0, pos.y))


func _draw_boat(pos: Vector2) -> void:
	draw_set_transform(pos, balance * 0.16)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -6), Vector2(13, -6), Vector2(19, 0),
		Vector2(12, 7), Vector2(-15, 7), Vector2(-20, 0)]), Color(0.55, 0.3, 0.16))
	draw_circle(Vector2(balance * 7.0, -7.0), 4.0, Color(0.95, 0.72, 0.42))
	draw_set_transform(Vector2.ZERO)


func _draw_fish(pos: Vector2, entry: Dictionary, hooked: bool) -> void:
	var scale: float = entry["size"]
	var direction: float = entry["dir"]
	var color := _tint(fish.color).lightened(0.2) if hooked else _tint(fish.color)
	draw_set_transform(pos, 0.0, Vector2.ONE * scale)
	draw_circle(Vector2.ZERO, 5.0, color)
	draw_colored_polygon(PackedVector2Array([Vector2(-direction * 4.0, 0),
		Vector2(-direction * 10.0, 5.0), Vector2(-direction * 10.0, -5.0)]), color)
	draw_set_transform(Vector2.ZERO)


func _draw_wheel(center: Vector2) -> void:
	var radius := 28.0
	var start := -PI * 0.5
	var green := yank_green_chance()
	var yellow := yank_yellow_chance()
	draw_arc(center, radius, start, start + TAU, 64, Color(0.65, 0.16, 0.2), 9.0, true)
	if hooked_index >= 0:
		draw_arc(center, radius, start + TAU * green, start + TAU * (green + yellow), 24,
			Color(1.0, 0.72, 0.2), 9.0, true)
		draw_arc(center, radius, start, start + TAU * green, maxi(3, roundi(64.0 * green)),
			Color(0.25, 0.9, 0.48), 9.0, true)
	draw_circle(center, radius - 6.0, Color(0.07, 0.09, 0.14))
	draw_line(center, center + Vector2.RIGHT.rotated(_pointer_angle) * (radius + 2.0), Color.WHITE, 2.0, true)
	draw_circle(center, 3.0, Color.WHITE)
	draw_string(ThemeDB.fallback_font, center + Vector2(-12, 4), "%d%%" % roundi(green * 100.0),
		HORIZONTAL_ALIGNMENT_CENTER, 24.0, 9, Color.WHITE)
	draw_string(ThemeDB.fallback_font, center + Vector2(-16, radius + 14), "E: TẤT TAY",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.9, 0.55))


func _draw_balance(rect: Rect2) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -2), "Nghiêng", HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	var track := Rect2(rect.position + Vector2(34, 0), Vector2(rect.size.x - 34, rect.size.y))
	draw_rect(track, Color(0.12, 0.12, 0.18))
	var center_x := track.position.x + track.size.x * 0.5
	draw_line(Vector2(center_x, track.position.y), Vector2(center_x, track.end.y), Color.WHITE, 1.0)
	draw_circle(Vector2(center_x + balance * track.size.x * 0.47, track.position.y + track.size.y * 0.5), 3.0,
		Color(0.3, 1.0, 0.65) if absf(balance) < 0.8 else Color(1.0, 0.25, 0.2))
	draw_rect(track, Color(1, 1, 1, 0.45), false, 1.0)


func _draw_bar(rect: Rect2, value: float, color: Color, label: String) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	var track := Rect2(rect.position + Vector2(34, 0), Vector2(rect.size.x - 34, rect.size.y))
	draw_rect(track, Color(0.1, 0.1, 0.15))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(value, 0.0, 1.0), track.size.y)), color)
	draw_rect(track, Color(1, 1, 1, 0.45), false, 1.0)
