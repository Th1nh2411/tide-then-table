class_name DayTint
extends CanvasModulate
## Tints the sea by time of night: deep blue night -> pink/orange dawn as the
## lamp oil runs low (DayClock time is driven by oil). HUD is unaffected.

@export var night_color: Color = Color(0.42, 0.48, 0.75)
@export var dawn_color: Color = Color(1.0, 0.78, 0.7)
@export var day_color: Color = Color.WHITE
## Night colour holds until this hour, then fades to dawn by dawn_hour.
@export var dawn_start_hour: float = 4.0
@export var dawn_hour: float = 6.0
@export var full_day_hour: float = 7.0


func _ready() -> void:
	DayClock.time_changed.connect(_on_time_changed)
	_on_time_changed(DayClock.current_minutes)


func _on_time_changed(minutes: float) -> void:
	var hour := minutes / 60.0
	if hour <= dawn_start_hour:
		color = night_color
	elif hour <= dawn_hour:
		color = night_color.lerp(dawn_color, inverse_lerp(dawn_start_hour, dawn_hour, hour))
	else:
		color = dawn_color.lerp(day_color, clampf(inverse_lerp(dawn_hour, full_day_hour, hour), 0.0, 1.0))
