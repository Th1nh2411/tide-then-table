class_name MinigameBase
extends Control
## Shared parts of the fishing minigames: setup, result signal, update loop,
## and the shifting "wrong" colors used for aberrant fish.
## Subclasses override _update(), _draw() and the text getters.

signal completed(success: bool, perfect: bool)

## Hue cycles per second for aberrant fish colors.
@export var aberrant_flicker_speed: float = 1.5

var fish: FishData
## Above 1 widens the green zone / calms the fish (rod upgrade).
var zone_scale: float = 1.0
## How many of the fish this attempt yields (nets can hold several).
## Set before setup(); games may lower it (e.g. shellfish spilling out).
var catch_count: int = 1

var _done: bool = false
var _time: float = 0.0


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	fish = p_fish
	zone_scale = p_zone_scale


func _process(delta: float) -> void:
	if _done or fish == null:
		return
	_time += delta
	_update(delta)
	queue_redraw()


## Per-frame game logic. Override in subclasses.
func _update(_delta: float) -> void:
	pass


func get_hint() -> String:
	return ""


func get_status_text() -> String:
	return ""


func get_fail_text() -> String:
	return "Cá thoát mất..."


func _finish(success: bool, perfect: bool) -> void:
	if _done:
		return
	_done = true
	completed.emit(success, perfect)


## Regular fish: color unchanged. Aberrant fish: hue keeps drifting so the
## player notices something is off.
func _tint(base: Color) -> Color:
	if fish == null or not fish.is_aberrant:
		return base
	var hue := fmod(base.h + _time * aberrant_flicker_speed, 1.0)
	return Color.from_hsv(hue, maxf(base.s, 0.6), maxf(base.v, 0.8), base.a)


## Top-left corner that centers an area of `area_size` inside this control.
func _centered_origin(area_size: Vector2) -> Vector2:
	return ((size - area_size) * 0.5).floor()
