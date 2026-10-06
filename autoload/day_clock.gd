extends Node
## Time of day for display and atmosphere. Autoloaded as `DayClock`.
## There is no ticking clock limiting the player (Dave the Diver style):
## - At sea the time is derived from lamp oil used (LampOil): full tank =
##   midnight, empty tank = dawn.
## - In the restaurant it follows the shift progress (opening -> closing).
## A day: night trip (0:00-6:00) -> rest (6:00-15:00) -> restaurant (15:00-24:00).

signal time_changed(minutes: float)

@export var night_start_hour: int = 0
@export var dawn_hour: int = 6
@export var shop_open_hour: int = 15
@export var shop_close_hour: int = 24

## Current displayed time in minutes since midnight.
var current_minutes: float = 0.0

## True while a night trip is in progress (oil burns, boat may move).
var running: bool = false


## Start of the night trip.
func start_night() -> void:
	running = true
	set_progress(0.0, night_start_hour, dawn_hour)


func stop() -> void:
	running = false


## Sets the time to `progress` (0..1) of the way from `from_hour` to `to_hour`.
func set_progress(progress: float, from_hour: int, to_hour: int) -> void:
	current_minutes = lerpf(from_hour * 60.0, to_hour * 60.0, clampf(progress, 0.0, 1.0))
	time_changed.emit(current_minutes)


func get_hour() -> int:
	return int(current_minutes) / 60


func get_minute() -> int:
	return int(current_minutes) % 60


## Formatted "HH:MM" for HUD display.
func get_time_text() -> String:
	return format_minutes(current_minutes)


static func format_minutes(minutes: float) -> String:
	return "%02d:%02d" % [int(minutes) / 60, int(minutes) % 60]
