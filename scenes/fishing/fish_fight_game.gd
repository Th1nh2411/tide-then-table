class_name FishFightGame
extends MinigameBase
## Arcade fishing rodeo. A/D moves the boat into line with the fish; Space
## reels or gives slack. Reading a telegraphed dash creates a counter window.

signal tugged
signal rin_fainted

enum Temperament { STEADY, ERRATIC, SHY, CLEVER }
enum Attack { DASH, DIVE, FEINT }
enum AttackPhase { WAIT, TELEGRAPH, ACTIVE, COUNTER }
enum YankResult { GREEN, YELLOW, RED }

const TEMPERAMENT_NAMES: Array[String] = ["lì", "quẫy", "nhát", "khôn"]
const ATTACK_NAMES: Array[String] = ["LAO NGANG", "LẶN SÂU", "GIẢ MỆT"]

@export_group("Rodeo")
@export var reel_per_second: float = 0.12
@export var slip_per_second: float = 0.014
@export var boat_speed: float = 1.25
@export var fish_speed_easy: float = 0.22
@export var fish_speed_hard: float = 0.42
@export var tension_recovery: float = 0.3
@export var base_tension_gain: float = 0.045
@export var bad_angle_gain: float = 0.28
@export var fail_seconds: float = 32.0
@export_group("Attacks")
@export var attack_wait: Vector2 = Vector2(1.8, 3.4)
@export var telegraph_seconds: float = 0.7
@export var attack_seconds: float = 0.8
@export var counter_seconds: float = 0.65
@export var counter_pull: float = 0.14
@export var missed_attack_stun: float = 0.14
@export_group("Balance")
@export var balance_speed: float = 1.7
@export var edge_stun_per_second: float = 0.16
@export var fall_stun: float = 0.16
@export_group("Yank wheel")
@export var yank_min_green: float = 0.05
@export var yank_max_green: float = 0.82
@export var yank_spin_seconds: float = 0.75
@export var yank_spin_turns: Vector2i = Vector2i(3, 5)
@export var random_seed: int = 0

var temperament: Temperament = Temperament.STEADY
var attack: Attack = Attack.DASH
var attack_phase: AttackPhase = AttackPhase.WAIT
var progress: float = 0.0
var tension: float = 0.16
var balance: float = 0.0
var stun: float = 0.0
var combo: int = 0
var fish_position: float = 0.0
var boat_position: float = 0.0
var fish_direction: float = 1.0
var yank_spinning: bool = false

var _phase_left: float = 1.0
var _turn_left: float = 1.0
var _released_for_attack: bool = false
var _fall_cooldown: float = 0.0
var _max_tension: float = 0.16
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
	temperament = _rng.randi_range(0, Temperament.size() - 1) as Temperament
	fish_position = _rng.randf_range(-0.65, 0.65)
	fish_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	_schedule_attack()
	_reset_turn()
	custom_minimum_size = Vector2(300, 176)


func get_hint() -> String:
	return "A/D: chạy theo cá · Space: kéo/nhả · nhả lúc cá lao, kéo lại để phản đòn · E: tất tay"


func get_status_text() -> String:
	var action := "Cá %s · Combo x%d" % [TEMPERAMENT_NAMES[temperament], combo]
	if attack_phase == AttackPhase.TELEGRAPH:
		action = "%s! NHẢ DÂY" % ATTACK_NAMES[attack]
	elif attack_phase == AttackPhase.ACTIVE:
		action = "%s!" % ATTACK_NAMES[attack]
	elif attack_phase == AttackPhase.COUNTER:
		action = "KÉO NGAY: PHẢN ĐÒN!"
	elif yank_spinning:
		action = "Đang giật tất tay..."
	return "Kéo %d%%  Dây %d%%  Choáng %d%% · %s" % [roundi(progress * 100.0),
		roundi(tension * 100.0), roundi(stun * 100.0), action]


func get_fail_text() -> String:
	if stun >= 1.0:
		return "Rin bất tỉnh!"
	return "Đứt dây!" if tension >= 1.0 else "Cá vùng thoát mất..."


func _update(delta: float) -> void:
	step_fight(delta, Input.get_axis("turn_left", "turn_right"), _cast_held(),
		Input.is_action_just_pressed("interact"))


## Public for the deterministic player simulation in fish_fight_test.
func step_fight(delta: float, steer: float, reeling: bool, yank: bool = false) -> void:
	if _done:
		return
	if yank_spinning:
		_update_wheel(delta)
		return
	boat_position = clampf(boat_position + steer * boat_speed * delta, -1.0, 1.0)
	_update_attack(delta, reeling)
	_move_fish(delta, reeling)
	_apply_line(delta, reeling)
	_update_balance(delta, reeling)
	if yank:
		start_yank_spin()
	progress = clampf(progress, 0.0, 1.0)
	tension = clampf(tension, 0.0, 1.0)
	stun = clampf(stun, 0.0, 1.0)
	_max_tension = maxf(_max_tension, tension)
	if stun >= 1.0:
		rin_fainted.emit()
		_finish(false, false)
	elif progress >= 1.0:
		_finish(true, _max_tension < 0.7 and stun < 0.5)
	elif tension >= 1.0 or _time >= fail_seconds:
		_finish(false, false)


func alignment() -> float:
	return 1.0 - clampf(absf(fish_position - boat_position) * 0.65, 0.0, 1.0)


func _apply_line(delta: float, reeling: bool) -> void:
	var difficulty := 0.75 + fish.difficulty * 0.65
	if reeling:
		if attack_phase == AttackPhase.COUNTER:
			progress += counter_pull + combo * 0.01
			tension = maxf(tension - 0.16, 0.0)
			stun = maxf(stun - 0.04, 0.0)
			combo += 1
			attack_phase = AttackPhase.WAIT
			_schedule_attack()
			tugged.emit()
		progress += reel_per_second * (0.4 + alignment() * 0.6) * zone_scale * delta
		var attack_gain := 0.42 if attack_phase == AttackPhase.ACTIVE else 0.0
		tension += (base_tension_gain + (1.0 - alignment()) * bad_angle_gain + attack_gain) \
			* difficulty / zone_scale * delta
	else:
		tension -= tension_recovery * zone_scale * delta
		progress -= slip_per_second * difficulty * delta


func _update_balance(delta: float, reeling: bool) -> void:
	_fall_cooldown = maxf(_fall_cooldown - delta, 0.0)
	var pull := (fish_position - boat_position) * (1.15 if reeling else 0.55)
	if attack_phase == AttackPhase.ACTIVE:
		pull *= 1.8
	balance = move_toward(balance, clampf(pull, -1.1, 1.1), balance_speed * delta)
	if absf(balance) > 0.78:
		stun += edge_stun_per_second * delta
	if absf(balance) >= 0.98 and _fall_cooldown <= 0.0:
		stun += fall_stun
		progress = maxf(progress - 0.07, 0.0)
		balance *= 0.45
		combo = 0
		_fall_cooldown = 0.8
		tugged.emit()


func _update_attack(delta: float, reeling: bool) -> void:
	_phase_left -= delta
	if (attack_phase == AttackPhase.TELEGRAPH or attack_phase == AttackPhase.ACTIVE) and not reeling:
		_released_for_attack = true
	if _phase_left > 0.0:
		return
	match attack_phase:
		AttackPhase.WAIT:
			attack = _rng.randi_range(0, Attack.size() - 1) as Attack
			attack_phase = AttackPhase.TELEGRAPH
			_phase_left = telegraph_seconds
			_released_for_attack = false
			tugged.emit()
		AttackPhase.TELEGRAPH:
			attack_phase = AttackPhase.ACTIVE
			_phase_left = attack_seconds * (1.2 if attack == Attack.DIVE else 1.0)
			if attack == Attack.FEINT:
				fish_direction *= -1.0
		AttackPhase.ACTIVE:
			if _released_for_attack:
				attack_phase = AttackPhase.COUNTER
				_phase_left = counter_seconds
			else:
				stun += missed_attack_stun + fish.difficulty * 0.08
				balance += fish_direction * 0.35
				combo = 0
				attack_phase = AttackPhase.WAIT
				_schedule_attack()
		AttackPhase.COUNTER:
			attack_phase = AttackPhase.WAIT
			_schedule_attack()


func _move_fish(delta: float, reeling: bool) -> void:
	_turn_left -= delta
	if _turn_left <= 0.0:
		fish_direction *= -1.0
		_reset_turn()
	var speed := lerpf(fish_speed_easy, fish_speed_hard, fish.difficulty)
	if temperament == Temperament.ERRATIC:
		speed *= 1.25
	elif temperament == Temperament.SHY:
		speed *= 1.3 if reeling else 0.7
	elif temperament == Temperament.CLEVER and attack_phase == AttackPhase.TELEGRAPH:
		speed *= 0.35
	if attack_phase == AttackPhase.ACTIVE:
		speed *= 2.1 if attack != Attack.DIVE else 1.3
	fish_position += fish_direction * speed * delta
	if absf(fish_position) >= 1.0:
		fish_position = clampf(fish_position, -1.0, 1.0)
		fish_direction *= -1.0


func _schedule_attack() -> void:
	_phase_left = _rng.randf_range(attack_wait.x, attack_wait.y)


func _reset_turn() -> void:
	var scale := 1.4 if temperament == Temperament.STEADY else 0.6 if temperament == Temperament.ERRATIC else 1.0
	_turn_left = _rng.randf_range(1.0, 2.5) * scale


func yank_green_chance() -> float:
	var chance := 0.04 + progress * 0.58 + alignment() * 0.18 + combo * 0.055 \
		- tension * 0.22 - absf(balance) * 0.16 - stun * 0.2 - fish.difficulty * 0.08
	return clampf(chance * minf(zone_scale, 1.3), yank_min_green, yank_max_green)


func yank_yellow_chance() -> float:
	return minf(0.2 + progress * 0.08 + combo * 0.015, 0.34)


func start_yank_spin(roll: float = -1.0) -> void:
	if yank_spinning or _done:
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


func resolve_yank(roll: float) -> YankResult:
	var result := YankResult.RED
	if roll <= yank_green_chance():
		result = YankResult.GREEN
		progress = 1.0
		_finish(true, _max_tension < 0.7 and stun < 0.5)
	elif roll <= yank_green_chance() + yank_yellow_chance():
		result = YankResult.YELLOW
		progress += 0.16
		stun += 0.1
		balance += fish_direction * 0.18
	else:
		progress -= 0.12
		tension += 0.22
		stun += 0.24
		balance += fish_direction * 0.42
		combo = 0
	tugged.emit()
	return result


func _draw() -> void:
	var origin := _centered_origin(Vector2(300, 164))
	var arena := Rect2(origin, Vector2(225, 112))
	draw_rect(arena, Color(0.035, 0.14, 0.24))
	for i in 5:
		var y := arena.position.y + 14.0 + i * 21.0
		draw_line(Vector2(arena.position.x + 4.0, y), Vector2(arena.end.x - 4.0, y), Color(0.2, 0.55, 0.65, 0.16))
	var boat_x := lerpf(arena.position.x + 15.0, arena.end.x - 15.0, (boat_position + 1.0) * 0.5)
	var fish_x := lerpf(arena.position.x + 12.0, arena.end.x - 12.0, (fish_position + 1.0) * 0.5)
	var boat_pos := Vector2(boat_x, arena.position.y + 22.0)
	var fish_pos := Vector2(fish_x, arena.position.y + 82.0 + (12.0 if attack == Attack.DIVE and attack_phase == AttackPhase.ACTIVE else 0.0))
	draw_line(boat_pos, fish_pos, Color(1.0, 0.86, 0.55, 0.85), 1.0)
	_draw_boat(boat_pos)
	_draw_fish(fish_pos)
	if attack_phase == AttackPhase.TELEGRAPH:
		draw_line(fish_pos, fish_pos + Vector2(fish_direction * 28.0, 0), Color(1.0, 0.35, 0.2), 3.0)
		draw_string(ThemeDB.fallback_font, fish_pos + Vector2(-22, -12), ATTACK_NAMES[attack],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.75, 0.3))
	_draw_wheel(Vector2(arena.end.x + 38.0, arena.position.y + 49.0))
	_draw_bar(Rect2(origin.x, arena.end.y + 8.0, 145.0, 7.0), progress, _tint(fish.color), "Kéo")
	_draw_bar(Rect2(origin.x + 155.0, arena.end.y + 8.0, 145.0, 7.0), tension, Color(1.0, 0.55, 0.2), "Dây")
	_draw_balance(Rect2(origin.x, arena.end.y + 28.0, 145.0, 7.0))
	_draw_bar(Rect2(origin.x + 155.0, arena.end.y + 28.0, 145.0, 7.0), stun, Color(0.75, 0.4, 1.0), "Choáng")


func _draw_boat(pos: Vector2) -> void:
	draw_set_transform(pos, balance * 0.16)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -6), Vector2(13, -6), Vector2(19, 0),
		Vector2(12, 7), Vector2(-15, 7), Vector2(-20, 0)]), Color(0.55, 0.3, 0.16))
	draw_circle(Vector2(balance * 7.0, -7.0), 4.0, Color(0.95, 0.72, 0.42))
	draw_set_transform(Vector2.ZERO)


func _draw_fish(pos: Vector2) -> void:
	var color := _tint(fish.color)
	draw_circle(pos, 7.0, color)
	draw_colored_polygon(PackedVector2Array([pos - Vector2(fish_direction * 6.0, 0),
		pos - Vector2(fish_direction * 13.0, 6.0), pos - Vector2(fish_direction * 13.0, -6.0)]), color)


func _draw_wheel(center: Vector2) -> void:
	var radius := 28.0
	var start := -PI * 0.5
	var green := yank_green_chance()
	var yellow := yank_yellow_chance()
	draw_arc(center, radius, start, start + TAU, 64, Color(0.65, 0.16, 0.2), 9.0, true)
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
		Color(0.3, 1.0, 0.65) if absf(balance) < 0.78 else Color(1.0, 0.25, 0.2))
	draw_rect(track, Color(1, 1, 1, 0.45), false, 1.0)


func _draw_bar(rect: Rect2, value: float, color: Color, label: String) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	var track := Rect2(rect.position + Vector2(34, 0), Vector2(rect.size.x - 34, rect.size.y))
	draw_rect(track, Color(0.1, 0.1, 0.15))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(value, 0.0, 1.0), track.size.y)), color)
	draw_rect(track, Color(1, 1, 1, 0.45), false, 1.0)
