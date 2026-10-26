class_name FishFightGame
extends MinigameBase
## Simple free-form rod fight: steer the rod with A/D, hold Space to reel,
## release to calm the line. A temperament and one incident vary each catch.

signal tugged

enum Temperament { STEADY, ERRATIC, SHY, CLEVER }
enum Incident { NONE, SURGE, TURN, SECOND_WIND }

const TEMPERAMENT_NAMES: Array[String] = ["lì", "quẫy", "nhát", "khôn"]
const INCIDENT_NAMES: Array[String] = ["", "Cá đang lao! Nhả dây!", "Cá đổi hướng!", "Cá vùng lần cuối!"]

@export_group("Fight")
@export var reel_per_second: float = 0.13
@export var slip_per_second: float = 0.018
@export var rod_speed: float = 1.8
@export var line_recovery: float = 0.34
@export var base_line_gain: float = 0.055
@export var bad_alignment_gain: float = 0.32
@export var fail_seconds: float = 28.0
@export_group("Variety")
@export var turn_seconds_min: float = 1.1
@export var turn_seconds_max: float = 2.8
@export var incident_chance: float = 0.75
@export var incident_seconds_min: float = 2.5
@export var incident_seconds_max: float = 5.0
@export var surge_duration: float = 1.1
@export_group("Final yank")
@export var yank_min_chance: float = 0.05
@export var yank_max_chance: float = 0.95
@export var yank_fail_tension: float = 0.28
@export var yank_fail_slip: float = 0.10
@export var yank_spin_seconds: float = 0.75
@export var yank_spin_turns_min: int = 3
@export var yank_spin_turns_max: int = 5
## Non-zero makes standalone tests and debugging repeatable.
@export var random_seed: int = 0

var temperament: Temperament = Temperament.STEADY
var incident: Incident = Incident.NONE
var progress: float = 0.0
var tension: float = 0.18
var fish_position: float = 0.0
var rod_position: float = 0.0
var fish_direction: float = 1.0
var max_tension: float = 0.18
var yank_spinning: bool = false

var _turn_left: float = 1.0
var _incident_at: float = INF
var _incident_left: float = 0.0
var _incident_used: bool = false
var _yank_spin_elapsed: float = 0.0
var _yank_spin_from: float = -PI * 0.5
var _yank_spin_to: float = -PI * 0.5
var _yank_pointer_angle: float = -PI * 0.5
var _yank_roll: float = 0.0
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
	_reset_turn()
	if _rng.randf() < incident_chance:
		incident = _rng.randi_range(Incident.SURGE, Incident.SECOND_WIND) as Incident
		_incident_at = _rng.randf_range(incident_seconds_min, incident_seconds_max)
	custom_minimum_size = Vector2(238, 148)


func get_hint() -> String:
	return "A/D: nghiêng cần · giữ Space: kéo · nhả: hạ căng · E: thử giật cá"


func get_status_text() -> String:
	var warning := INCIDENT_NAMES[incident] if _incident_left > 0.0 else "Cá %s" % TEMPERAMENT_NAMES[temperament]
	if yank_spinning:
		warning = "Đang giật..."
	return "Kéo %d%%   Dây %d%%   · %s" % [roundi(progress * 100.0),
		roundi(tension * 100.0), warning]


func get_fail_text() -> String:
	return "Đứt dây!" if tension >= 1.0 else "Cá vùng thoát mất..."


func _update(delta: float) -> void:
	var steer := Input.get_axis("turn_left", "turn_right")
	var reeling := _cast_held()
	var yank := Input.is_action_just_pressed("interact")
	step_fight(delta, steer, reeling, yank)


## Public so the deterministic test and bot can exercise the same rules.
func step_fight(delta: float, steer: float, reeling: bool, yank: bool = false) -> void:
	if _done:
		return
	if yank_spinning:
		_update_yank_spin(delta)
		return
	_update_incident(delta)
	rod_position = clampf(rod_position + steer * rod_speed * delta, -1.0, 1.0)
	_move_fish(delta, reeling)
	var alignment := 1.0 - clampf(absf(fish_position - rod_position) * 0.75, 0.0, 1.0)
	var difficulty := 0.75 + fish.difficulty * 0.65
	if reeling:
		progress += reel_per_second * (0.45 + alignment * 0.55) * zone_scale * delta
		var surge := 0.42 if incident == Incident.SURGE and _incident_left > 0.0 else 0.0
		var shy := 0.10 if temperament == Temperament.SHY else 0.0
		tension += (base_line_gain + (1.0 - alignment) * bad_alignment_gain + surge + shy) \
			* difficulty / zone_scale * delta
	else:
		tension -= line_recovery * zone_scale * delta
		progress -= slip_per_second * difficulty * delta
	progress = clampf(progress, 0.0, 1.0)
	tension = clampf(tension, 0.0, 1.0)
	max_tension = maxf(max_tension, tension)
	if yank:
		start_yank_spin()
	if progress >= 1.0:
		_finish(true, max_tension < 0.72)
	elif tension >= 1.0 or _time >= fail_seconds:
		_finish(false, false)


## Chance is readable and continuous: getting close matters most, while good
## alignment and a calm line can make an early gamble viable.
func yank_chance() -> float:
	var alignment := 1.0 - clampf(absf(fish_position - rod_position) * 0.75, 0.0, 1.0)
	var chance := 0.05 + progress * 0.82 + alignment * 0.18 - tension * 0.32 - fish.difficulty * 0.12
	return clampf(chance * minf(zone_scale, 1.35), yank_min_chance, yank_max_chance)


## Starts a readable roulette animation. The same random roll chooses both
## the pointer's resting angle and the result, so the wheel never lies.
func start_yank_spin(roll: float = -1.0) -> void:
	if yank_spinning or _done:
		return
	_yank_roll = _rng.randf() if roll < 0.0 else clampf(roll, 0.0, 0.9999)
	_yank_spin_elapsed = 0.0
	_yank_spin_from = _yank_pointer_angle
	var turns := _rng.randi_range(yank_spin_turns_min, yank_spin_turns_max)
	_yank_spin_to = -PI * 0.5 + _yank_roll * TAU + turns * TAU
	yank_spinning = true
	Sfx.play("blip")


func _update_yank_spin(delta: float) -> void:
	_yank_spin_elapsed += delta
	var t := clampf(_yank_spin_elapsed / yank_spin_seconds, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	_yank_pointer_angle = lerpf(_yank_spin_from, _yank_spin_to, eased)
	if t >= 1.0:
		yank_spinning = false
		_yank_pointer_angle = -PI * 0.5 + _yank_roll * TAU
		attempt_yank(_yank_roll)


## `roll` is injectable for deterministic tests; gameplay leaves it at -1.
func attempt_yank(roll: float = -1.0) -> bool:
	var result := _rng.randf() if roll < 0.0 else roll
	var success := result <= yank_chance()
	if success:
		progress = 1.0
		_finish(true, max_tension < 0.72)
	else:
		progress = maxf(progress - yank_fail_slip, 0.0)
		tension = minf(tension + yank_fail_tension + fish.difficulty * 0.08, 1.0)
		fish_direction *= -1.0
		_reset_turn()
	tugged.emit()
	return success


func _move_fish(delta: float, reeling: bool) -> void:
	_turn_left -= delta
	if _turn_left <= 0.0:
		fish_direction *= -1.0
		_reset_turn()
	var speed := lerpf(0.24, 0.48, fish.difficulty)
	match temperament:
		Temperament.ERRATIC:
			speed *= 1.2
		Temperament.SHY:
			speed *= 1.25 if reeling else 0.75
		Temperament.CLEVER:
			speed *= 0.65 if _time < 2.0 else 1.25
	if incident == Incident.SURGE and _incident_left > 0.0:
		speed *= 2.2
	fish_position += fish_direction * speed * delta
	if absf(fish_position) >= 1.0:
		fish_position = clampf(fish_position, -1.0, 1.0)
		fish_direction *= -1.0


func _reset_turn() -> void:
	var scale := 1.0
	if temperament == Temperament.STEADY:
		scale = 1.45
	elif temperament == Temperament.ERRATIC:
		scale = 0.55
	_turn_left = _rng.randf_range(turn_seconds_min, turn_seconds_max) * scale


func _update_incident(delta: float) -> void:
	if not _incident_used and _time >= _incident_at:
		_incident_used = true
		_incident_left = surge_duration
		if incident == Incident.TURN:
			fish_direction *= -1.0
			_reset_turn()
		elif incident == Incident.SECOND_WIND:
			progress = maxf(progress - 0.12, 0.0)
		tugged.emit()
	if _incident_left > 0.0:
		_incident_left = maxf(_incident_left - delta, 0.0)


func _draw() -> void:
	var origin := _centered_origin(Vector2(270, 132))
	var water := Rect2(origin, Vector2(190, 88))
	draw_rect(water, Color(0.045, 0.15, 0.24))
	for i in 5:
		var y := water.position.y + 12.0 + i * 16.0
		draw_line(Vector2(water.position.x + 6.0, y), Vector2(water.end.x - 6.0, y), Color(0.2, 0.55, 0.65, 0.18), 1.0)
	var fish_x := lerpf(water.position.x + 10.0, water.end.x - 10.0, (fish_position + 1.0) * 0.5)
	var rod_x := lerpf(water.position.x + 10.0, water.end.x - 10.0, (rod_position + 1.0) * 0.5)
	var fish_color := _tint(fish.color)
	draw_circle(Vector2(fish_x, water.position.y + 49.0), 7.0, fish_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(fish_x - fish_direction * 6.0, water.position.y + 49.0),
		Vector2(fish_x - fish_direction * 13.0, water.position.y + 43.0),
		Vector2(fish_x - fish_direction * 13.0, water.position.y + 55.0)]), fish_color)
	draw_line(Vector2(rod_x, water.position.y - 4.0), Vector2(fish_x, water.position.y + 49.0),
		Color(1.0, 0.85, 0.55, 0.9), 1.0)
	draw_circle(Vector2(rod_x, water.position.y - 4.0), 4.0, Color.WHITE)
	_draw_yank_wheel(Vector2(water.end.x + 40.0, water.position.y + 44.0))
	_draw_bar(Rect2(origin.x, water.end.y + 10.0, 270.0, 8.0), progress, fish_color, "Kéo")
	_draw_bar(Rect2(origin.x, water.end.y + 32.0, 270.0, 8.0), tension,
		Color(0.35, 0.9, 0.55) if tension < 0.7 else Color(1.0, 0.3, 0.2), "Dây")


func _draw_yank_wheel(center: Vector2) -> void:
	var radius := 29.0
	var start := -PI * 0.5
	var chance := yank_chance()
	# Red base + a green arc whose angle is exactly the current success chance.
	draw_arc(center, radius, start, start + TAU, 64, Color(0.65, 0.18, 0.2), 10.0, true)
	draw_arc(center, radius, start, start + TAU * chance, maxi(3, roundi(64.0 * chance)),
		Color(0.25, 0.9, 0.48), 10.0, true)
	draw_circle(center, radius - 7.0, Color(0.07, 0.09, 0.14))
	var tip := center + Vector2.RIGHT.rotated(_yank_pointer_angle) * (radius + 2.0)
	draw_line(center, tip, Color(1.0, 0.9, 0.48), 2.0, true)
	draw_circle(center, 3.0, Color.WHITE)
	var percent := "%d%%" % roundi(chance * 100.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-12.0, 4.0), percent,
		HORIZONTAL_ALIGNMENT_CENTER, 24.0, 9, Color.WHITE)
	draw_string(ThemeDB.fallback_font, center + Vector2(-15.0, radius + 14.0),
		"E: GIẬT", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.9, 0.55))


func _draw_bar(rect: Rect2, value: float, color: Color, label: String) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -2), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	var track := Rect2(rect.position + Vector2(30, 0), Vector2(rect.size.x - 30, rect.size.y))
	draw_rect(track, Color(0.1, 0.1, 0.15))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(value, 0.0, 1.0), track.size.y)), color)
	draw_rect(track, Color(1, 1, 1, 0.5), false, 1.0)
