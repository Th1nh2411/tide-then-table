class_name RhythmGame
extends MinigameBase
## Rod fight as a rhythm game (piano tiles): every tug of the fish is a note
## falling down one of 2-4 lanes (A S D F); press the lane's key when it
## reaches the line, keep it down for long notes. Hits fill the reel ("Kéo"),
## misses and wrong keys wear the line ("Dây"). Full reel = caught (no miss =
## perfect); line gone = snapped; tune over with the reel short = it got away.
## The tune comes from RhythmChart (fish difficulty, size, rod). Game time is
## `_time`, so Nhịp Sóng (Engine.time_scale) slows the notes too.

## Emitted on every hit (the fishing overlay jolts the fish picture).
signal tugged

const KEYS: Array[Key] = [KEY_A, KEY_S, KEY_D, KEY_F]
const KEY_NAMES: Array[String] = ["A", "S", "D", "F"]
const LANE_COLORS: Array[Color] = [Color(0.45, 0.8, 1.0), Color(0.5, 1.0, 0.6), Color(1.0, 0.85, 0.4),
	Color(1.0, 0.55, 0.65)]
## Pentatonic steps per lane: hits play a little tune.
const LANE_NOTES: Array[float] = [0.0, 2.0, 4.0, 7.0]

## Notes in the tune, easy -> hard fish (see RhythmChart for the rest).
@export var notes_easy: int = 14
@export var notes_hard: int = 28
@export var lane_width: float = 22.0
@export var area_height: float = 150.0
## Seconds a note takes to fall to the line, easy -> hard fish.
@export var approach_easy: float = 1.5
@export var approach_hard: float = 1.05
## Hit window (± seconds) easy -> hard fish; the rod's zone_scale widens it.
@export var window_easy: float = 0.16
@export var window_hard: float = 0.1
## Share of the tune's notes needed to fill the reel.
@export var need_ratio: float = 0.7
## Misses the line takes, easy -> hard fish.
@export var misses_easy: float = 8.0
@export var misses_hard: float = 5.0
## A key pressed with no note there costs this share of a miss.
@export var wrong_key_cost: float = 0.3

var notes: Array[Dictionary] = []
var lanes: int = 2
var progress: float = 0.0
var line: float = 1.0
var misses: int = 0

var _window: float = 0.12
var _approach: float = 1.3
var _per_unit: float = 0.1
var _miss_cost: float = 0.2
var _held: Array[bool] = [false, false, false, false]
var _flash: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _flash_good: Array[bool] = [true, true, true, true]
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	_rng.randomize()
	var d := fish.difficulty
	var tuning := RhythmChart.DEFAULTS.duplicate()
	tuning["notes_easy"] = notes_easy
	tuning["notes_hard"] = notes_hard
	notes = RhythmChart.build(d, fish.is_aberrant, zone_scale, _rng, tuning)
	for note in notes:
		note["state"] = 0  # 0 waiting, 1 holding, 2 done, 3 missed
	lanes = RhythmChart.lane_count(d)
	_window = lerpf(window_easy, window_hard, d) * zone_scale
	_approach = lerpf(approach_easy, approach_hard, d)
	_per_unit = 1.0 / maxf(notes.size() * need_ratio, 1.0)
	_miss_cost = 1.0 / lerpf(misses_easy, misses_hard, d)
	custom_minimum_size = Vector2(lanes * lane_width + 70, area_height + 24)


func get_hint() -> String:
	return "%s: bấm khi nốt chạm vạch · nốt dài: giữ" % " ".join(KEY_NAMES.slice(0, lanes))


func get_status_text() -> String:
	return "Kéo %d%%   Dây %d%%" % [roundi(minf(progress, 1.0) * 100), roundi(maxf(line, 0.0) * 100)]


func get_fail_text() -> String:
	return "Đứt dây!" if line <= 0.0 else "Cá giật mạnh quá, thoát mất..."


func _update(delta: float) -> void:
	for lane in lanes:
		_flash[lane] = maxf(_flash[lane] - delta * 4.0, 0.0)
		var down := Input.is_physical_key_pressed(KEYS[lane])
		if down and not _held[lane]:
			press(lane)
		elif not down and _held[lane]:
			release(lane)
		_held[lane] = down
	advance()


## A key went down (the sim / tests call these directly).
func press(lane: int) -> void:
	for note in notes:
		if note["state"] == 0 and note["lane"] == lane and absf(float(note["t"]) - _time) <= _window:
			var hold: float = note["hold"]
			note["state"] = 1 if hold > 0.0 else 2
			progress += _per_unit * (0.5 if hold > 0.0 else 1.0)
			_show(lane, true)
			Sfx.play_note("pluck", LANE_NOTES[lane] + (12.0 if hold > 0.0 else 0.0))
			tugged.emit()
			return
	line -= _miss_cost * wrong_key_cost
	_show(lane, false)


func release(lane: int) -> void:
	for note in notes:
		if note["state"] == 1 and note["lane"] == lane:
			var end: float = float(note["t"]) + float(note["hold"])
			if _time >= end - _window:
				_complete_hold(note)
			else:  # let go too early: the fish pulls line out
				note["state"] = 3
				misses += 1
				line -= _miss_cost * 0.5
				_show(lane, false)


## Late notes become misses, held notes finish; then win / lose checks.
func advance() -> void:
	var open := false
	for note in notes:
		var t: float = note["t"]
		if note["state"] == 0:
			if _time > t + _window:
				note["state"] = 3
				misses += 1
				line -= _miss_cost
				_show(int(note["lane"]), false)
			else:
				open = true
		elif note["state"] == 1:
			if _time >= t + float(note["hold"]):
				_complete_hold(note)
			else:
				open = true
	if progress >= 1.0 - 0.0001:
		_finish(true, misses == 0)
	elif line <= 0.0:
		_finish(false, false)
	elif not open:
		_finish(false, false)  # the tune is over and the reel isn't full


func _complete_hold(note: Dictionary) -> void:
	note["state"] = 2
	progress += _per_unit * 0.5
	_show(int(note["lane"]), true)


func _show(lane: int, good: bool) -> void:
	_flash[lane] = 1.0
	_flash_good[lane] = good
	if not good:
		Sfx.play("blip", 0.0)


func _draw() -> void:
	var area := Vector2(lanes * lane_width, area_height)
	var origin := _centered_origin(Vector2(area.x + 60, area.y))
	var hit_y := origin.y + area.y - 20.0
	var fall := hit_y - origin.y
	draw_rect(Rect2(origin, area), Color(0.1, 0.1, 0.16))
	for lane in lanes:
		var x := origin.x + lane * lane_width
		var color := LANE_COLORS[lane]
		draw_rect(Rect2(x, origin.y, lane_width, area.y), Color(color, 0.06))
		if _flash[lane] > 0.0:
			var flash := Color(0.4, 1.0, 0.5) if _flash_good[lane] else Color(1.0, 0.3, 0.25)
			draw_rect(Rect2(x, hit_y - 6, lane_width, 12), Color(flash, 0.6 * _flash[lane]))
		draw_string(ThemeDB.fallback_font, Vector2(x + lane_width * 0.5 - 4, origin.y + area.y - 4),
			KEY_NAMES[lane], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(color, 0.9 if _held[lane] else 0.55))
	for note in notes:
		var state: int = note["state"]
		if state == 2 and float(note["hold"]) <= 0.0:
			continue
		var lane: int = note["lane"]
		var head_y := hit_y - (float(note["t"]) - _time) / _approach * fall
		var tail_y := hit_y - (float(note["t"]) + float(note["hold"]) - _time) / _approach * fall
		if tail_y > hit_y + 14.0 or head_y < origin.y - 8.0:
			continue
		var color := _tint(LANE_COLORS[lane])
		if state == 3:
			color = Color(0.45, 0.45, 0.5, 0.5)
		var x := origin.x + lane * lane_width
		if float(note["hold"]) > 0.0:
			var top := maxf(tail_y, origin.y)
			var bottom := minf(head_y, hit_y) if state == 1 else head_y
			draw_rect(Rect2(x + lane_width * 0.5 - 3, top, 6, maxf(bottom - top, 0.0)), Color(color, 0.7))
		if state != 1 and state != 2:
			draw_rect(Rect2(x + 2, clampf(head_y, origin.y, hit_y + 12) - 4, lane_width - 4, 8), color)
	draw_line(Vector2(origin.x, hit_y), Vector2(origin.x + area.x, hit_y), Color(1, 1, 1, 0.85), 2.0)
	draw_rect(Rect2(origin, area), Color(1, 1, 1, 0.5), false, 1.0)
	_draw_meter(Vector2(origin.x + area.x + 14, origin.y), progress, _tint(fish.color), "Kéo")
	_draw_meter(Vector2(origin.x + area.x + 40, origin.y), line, Color(1.0, 0.6, 0.2), "Dây")


## Vertical meter filling from the bottom, with a small label underneath.
func _draw_meter(pos: Vector2, value: float, color: Color, label: String) -> void:
	var meter_size := Vector2(10, area_height)
	draw_rect(Rect2(pos, meter_size), Color(0.12, 0.12, 0.18))
	var fill := clampf(value, 0.0, 1.0) * meter_size.y
	draw_rect(Rect2(pos.x, pos.y + meter_size.y - fill, meter_size.x, fill), color)
	draw_rect(Rect2(pos, meter_size), Color(1, 1, 1, 0.6), false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-6, meter_size.y + 12), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
