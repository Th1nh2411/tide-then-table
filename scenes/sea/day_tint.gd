class_name DayTint
extends CanvasModulate
## Tints the sea by time of day: neutral -> orange toward opening time,
## then -> dusk blue while the player is late. HUD (CanvasLayer) is unaffected.

@export var day_color: Color = Color.WHITE
@export var sunset_color: Color = Color(1.0, 0.72, 0.5)
@export var night_color: Color = Color(0.45, 0.45, 0.7)
@export var sunset_start_hour: float = 14.0
@export var sunset_hour: float = 18.0
@export var night_hour: float = 21.0


func _ready() -> void:
	DayClock.time_changed.connect(_on_time_changed)
	_on_time_changed(DayClock.current_minutes)


func _on_time_changed(minutes: float) -> void:
	var hour := minutes / 60.0
	if hour <= sunset_start_hour:
		color = day_color
	elif hour <= sunset_hour:
		color = day_color.lerp(sunset_color, inverse_lerp(sunset_start_hour, sunset_hour, hour))
	else:
		var t := clampf(inverse_lerp(sunset_hour, night_hour, hour), 0.0, 1.0)
		color = sunset_color.lerp(night_color, t)
