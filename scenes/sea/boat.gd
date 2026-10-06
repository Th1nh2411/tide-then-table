class_name Boat
extends CharacterBody2D
## Top-down boat with car-style controls.
## W/S: throttle with inertia (drifts to a stop when released). A/D: steer.
## Spin drift adds extra rotation that builds while steering and lingers
## after release, scaled by BoatData.spin_drift.

signal boat_data_changed(data: BoatData)
## Hit an obstacle. `impact_speed` = speed straight into the surface (px/s).
signal collided(impact_speed: float)

@export var boat_data: BoatData

@export_group("Handling")
## Speed lost per second when throttle is released (water drag).
@export var drag: float = 30.0
## Reverse top speed as a fraction of max_speed.
@export var reverse_ratio: float = 0.4
## Fraction of steering kept when stopped. Above 0 so the boat can turn in place.
@export var idle_turn_ratio: float = 0.4

@export_group("Spin drift")
## Spin acceleration (deg/s²) at spin_drift = 1.
@export var spin_acceleration: float = 300.0
## Max spin speed (deg/s) at spin_drift = 1.
@export var max_spin: float = 220.0
## How fast spin fades (deg/s²) when not steering, or when counter-steering.
@export var spin_damping: float = 140.0

@export_group("Collision")
## Fraction of speed kept (reversed) after hitting an obstacle.
@export var bounce_factor: float = 0.4

## Signed forward speed in pixels/second (negative = reversing).
var speed: float = 0.0
## Scales top speed (a damaged hull is slower). Set by HullController.
var speed_multiplier: float = 1.0
## Extra angular velocity from spin drift, in degrees/second.
var _spin: float = 0.0

@onready var camera: Camera2D = $Camera2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if boat_data:
		apply_boat_data(boat_data)


## Swap to another boat type. Resets motion so stats apply cleanly.
func apply_boat_data(data: BoatData) -> void:
	boat_data = data
	speed = 0.0
	_spin = 0.0
	# New shape each time so we never mutate a shared resource.
	var shape := CircleShape2D.new()
	shape.radius = minf(data.hull_size.x, data.hull_size.y) * 0.5
	_collision.shape = shape
	queue_redraw()
	boat_data_changed.emit(data)


func _physics_process(delta: float) -> void:
	if boat_data == null:
		return
	var throttle := Input.get_axis("throttle_back", "throttle_forward")
	var steer := Input.get_axis("turn_left", "turn_right")
	_update_speed(throttle, delta)
	_update_rotation(steer, delta)
	_move(delta)


func _update_speed(throttle: float, delta: float) -> void:
	if throttle != 0.0:
		speed += throttle * boat_data.acceleration * delta
	else:
		speed = move_toward(speed, 0.0, drag * delta)
	var top := boat_data.max_speed * speed_multiplier
	speed = clampf(speed, -top * reverse_ratio, top)


func _update_rotation(steer: float, delta: float) -> void:
	# Steering is weaker at low speed, like a real hull needing water flow.
	var speed_ratio := absf(speed) / boat_data.max_speed
	var base_turn := steer * boat_data.turn_speed * lerpf(idle_turn_ratio, 1.0, speed_ratio)

	var drift := boat_data.spin_drift
	if steer == 0.0:
		_spin = move_toward(_spin, 0.0, spin_damping * delta)
	else:
		# Counter-steering also kills spin, so a spinning boat can be recovered.
		if signf(steer) != signf(_spin):
			_spin = move_toward(_spin, 0.0, spin_damping * delta)
		_spin += steer * spin_acceleration * drift * delta
	var spin_limit := max_spin * drift
	_spin = clampf(_spin, -spin_limit, spin_limit)

	rotation += deg_to_rad(base_turn + _spin) * delta


func _move(delta: float) -> void:
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	var collision := move_and_collide(velocity * delta)
	if collision:
		# Head-on hits count fully, glancing ones barely.
		collided.emit(maxf(-velocity.dot(collision.get_normal()), 0.0))
		# Small bounce: reverse part of the speed and nudge off the surface
		# so the boat doesn't stay glued to the obstacle.
		speed = -speed * bounce_factor
		position += collision.get_normal()


func _draw() -> void:
	if boat_data == null:
		return
	# Hull points toward +X (Godot's rotation 0).
	var half := boat_data.hull_size * 0.5
	var hull := PackedVector2Array([
		Vector2(half.x, 0),
		Vector2(half.x * 0.3, -half.y),
		Vector2(-half.x, -half.y),
		Vector2(-half.x, half.y),
		Vector2(half.x * 0.3, half.y),
	])
	draw_colored_polygon(hull, boat_data.color)
	# Bow marker so the heading is readable on round hulls.
	draw_circle(Vector2(half.x * 0.5, 0), 1.5, Color.WHITE)
