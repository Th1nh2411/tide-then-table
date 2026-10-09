class_name BoatLamp
extends PointLight2D
## The boat's fishing lamp: the only thing that lights the night sea (the
## DayTint keeps everything else dark). Its radius shrinks with the lamp oil,
## so a low tank also means seeing less; it sputters when nearly empty.
## Docked = lamp off (it burns no oil there either); the dock light is enough.

@export var oil: LampOil
## Lamp is off while the boat is at this dock.
@export var dock: Dock
## Energy change per second when switching on/off.
@export var fade_speed: float = 3.0
## Light radius in px with a full / empty tank.
@export var radius_full: float = 100.0
@export var radius_empty: float = 40.0
## Below this oil fraction the lamp starts to sputter.
@export var sputter_fraction: float = 0.15
@export var sputter_amount: float = 0.25

## Tonight's weather radius multiplier (rain shortens the light).
var weather_scale: float = 1.0:
	set(value):
		weather_scale = value
		_apply_radius()
var _fraction: float = 1.0
var _time: float = 0.0
var _base_energy: float = 1.0
## 0 = off, 1 = on (faded).
var _on: float = 1.0


func _ready() -> void:
	_base_energy = energy
	if oil:
		oil.oil_changed.connect(_on_oil_changed)
	_apply_radius()


func _process(delta: float) -> void:
	_time += delta
	var docked := dock != null and dock.is_boat_inside()
	_on = move_toward(_on, 0.0 if docked else 1.0, fade_speed * delta)
	var flicker := 1.0
	if _fraction < sputter_fraction:
		flicker = 1.0 - sputter_amount * absf(sin(_time * 11.0) * sin(_time * 3.7))
	energy = _base_energy * flicker * _on
	visible = _on > 0.0


func _on_oil_changed(amount: float, capacity: float) -> void:
	_fraction = amount / capacity if capacity > 0.0 else 0.0
	_apply_radius()


func _apply_radius() -> void:
	if texture == null:
		return
	var radius := lerpf(radius_empty, radius_full, _fraction) * weather_scale
	# The gradient fades out at the texture edge: scale so its half-width = radius.
	texture_scale = radius * 2.0 / texture.get_width()
