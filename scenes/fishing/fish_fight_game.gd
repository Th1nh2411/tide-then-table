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

var _turn_left: float = 1.0
var _incident_at: float = INF
var _incident_left: float = 0.0
var _incident_used: bool = false
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
	return "A/D: nghiêng cần · giữ Space: kéo · nhả: hạ căng · E: giật mạnh khi gần"


func get_status_text() -> String:
	var warning := INCIDENT_NAMES[incident] if _incident_left > 0.0 else "Cá %s" % TEMPERAMENT_NAMES[temperament]
	return "Kéo %d%%   Dây %d%%   · %s" % [roundi(progress * 100.0), roundi(tension * 100.0), warning]


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
	if yank and progress >= 0.78:
		if alignment >= 0.68 and tension <= 0.64:
			progress = 1.0
		else:
			tension = minf(tension + 0.38, 1.0)
		tugged.emit()
	if progress >= 1.0:
		_finish(true, max_tension < 0.72)
	elif tension >= 1.0 or _time >= fail_seconds:
		_finish(false, false)


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
	var water := Rect2(_centered_origin(Vector2(220, 88)), Vector2(220, 88))
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
	_draw_bar(Rect2(water.position.x, water.end.y + 10.0, water.size.x, 8.0), progress, fish_color, "Kéo")
	_draw_bar(Rect2(water.position.x, water.end.y + 32.0, water.size.x, 8.0), tension,
		Color(0.35, 0.9, 0.55) if tension < 0.7 else Color(1.0, 0.3, 0.2), "Dây")


func _draw_bar(rect: Rect2, value: float, color: Color, label: String) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -2), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	var track := Rect2(rect.position + Vector2(30, 0), Vector2(rect.size.x - 30, rect.size.y))
	draw_rect(track, Color(0.1, 0.1, 0.15))
	draw_rect(Rect2(track.position, Vector2(track.size.x * clampf(value, 0.0, 1.0), track.size.y)), color)
	draw_rect(track, Color(1, 1, 1, 0.5), false, 1.0)
