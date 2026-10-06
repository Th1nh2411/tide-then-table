extends Node
## In-game time of day. Autoloaded as `DayClock`.
## The sea day runs from `day_start_hour` to `shop_open_hour` in
## `real_seconds_per_sea_day` real seconds. The clock keeps ticking past opening
## time (player is late) until `latest_return_hour`, when the boat is towed home.
## Stops automatically while the tree is paused (e.g. hold UI in Phase 5).

signal time_changed(minutes: float)
## Fired once when the clock hits latest_return_hour. Sea scene tows the boat.
signal return_deadline_reached

@export var day_start_hour: int = 6
@export var warning_hour: int = 17
@export var shop_open_hour: int = 18
@export var latest_return_hour: int = 21
## Real seconds for the trip from day_start_hour to shop_open_hour.
@export var real_seconds_per_sea_day: float = 240.0
## Fraction of the selling shift lost per hour of being late.
@export var shift_loss_per_late_hour: float = 0.25

## Current in-game time in minutes since midnight (6:00 = 360).
var current_minutes: float = 6 * 60

## When false the clock does not advance (menus, restaurant, etc.).
var running: bool = false

var _deadline_fired: bool = false


func _process(delta: float) -> void:
	if not running:
		return
	current_minutes += delta * _game_minutes_per_second()
	if current_minutes >= latest_return_hour * 60:
		current_minutes = latest_return_hour * 60
		running = false
	time_changed.emit(current_minutes)
	if not running and not _deadline_fired:
		_deadline_fired = true
		return_deadline_reached.emit()


## Reset to the morning and start ticking.
func start_day() -> void:
	current_minutes = day_start_hour * 60
	_deadline_fired = false
	running = true
	time_changed.emit(current_minutes)


func stop() -> void:
	running = false


## Skip time forward (fishing costs time in Phase 3).
func advance(minutes: float) -> void:
	current_minutes = minf(current_minutes + minutes, latest_return_hour * 60)
	time_changed.emit(current_minutes)


func is_warning_time() -> bool:
	return current_minutes >= warning_hour * 60


func is_late() -> bool:
	return current_minutes > shop_open_hour * 60


## 1.0 when back by opening time, minus shift_loss_per_late_hour per late hour
## (pro-rated by the minute), down to the minimum at latest_return_hour.
func get_shift_ratio() -> float:
	var max_late_hours := float(latest_return_hour - shop_open_hour)
	var late_hours := clampf((current_minutes - shop_open_hour * 60) / 60.0, 0.0, max_late_hours)
	return 1.0 - late_hours * shift_loss_per_late_hour


func get_hour() -> int:
	return int(current_minutes) / 60


func get_minute() -> int:
	return int(current_minutes) % 60


## Formatted "HH:MM" for HUD display.
func get_time_text() -> String:
	return format_minutes(current_minutes)


static func format_minutes(minutes: float) -> String:
	return "%02d:%02d" % [int(minutes) / 60, int(minutes) % 60]


func _game_minutes_per_second() -> float:
	return (shop_open_hour - day_start_hour) * 60.0 / real_seconds_per_sea_day
