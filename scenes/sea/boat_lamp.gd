class_name BoatLamp
extends PointLight2D
## The boat's fishing lamp: the only thing that lights the night sea (the
## DayTint keeps everything else dark). Its radius shrinks with the lamp oil,
## so a low tank also means seeing less; it sputters when nearly empty.

@export var oil: LampOil
## Light radius in px with a full / empty tank.
@export var radius_full: float = 150.0
@export var radius_empty: float = 55.0
## Below this oil fraction the lamp starts to sputter.
@export var sputter_fraction: float = 0.15
@export var sputter_amount: float = 0.25

var _fraction: float = 1.0
var _time: float = 0.0
var _base_energy: float = 1.0


func _ready() -> void:
	_base_energy = energy
	if oil:
		oil.oil_changed.connect(_on_oil_changed)
	_apply_radius()


func _process(delta: float) -> void:
	_time += delta
	if _fraction < sputter_fraction:
		energy = _base_energy * (1.0 - sputter_amount * absf(sin(_time * 11.0) * sin(_time * 3.7)))
	else:
		energy = _base_energy


func _on_oil_changed(amount: float, capacity: float) -> void:
	_fraction = amount / capacity if capacity > 0.0 else 0.0
	_apply_radius()


func _apply_radius() -> void:
	if texture == null:
		return
	var radius := lerpf(radius_empty, radius_full, _fraction)
	# The gradient fades out at the texture edge: scale so its half-width = radius.
	texture_scale = radius * 2.0 / texture.get_width()
