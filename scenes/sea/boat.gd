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
## Scales top speed while towing another boat (night events).
var tow_multiplier: float = 1.0
## Extra angular velocity from spin drift, in degrees/second.
var _spin: float = 0.0
var _cat_time: float = 0.0
## Hull side height (world px) in the 3/4 view.
@export var hull_depth: float = 3.0
## The restaurant cat rides along at the stern once adopted.
@onready var _has_cat: bool = PetCat.is_present()

@onready var camera: Camera2D = $Camera2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("boat")  # the phone map finds the boat through this
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
	var top := boat_data.max_speed * speed_multiplier * tow_multiplier
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


## 3/4 view like the restaurant: the deck turns with the boat, the hull's
## side always shows toward the bottom of the screen (local "down" follows
## -rotation), and Rin (in a conical hat) and the cat stand upright. The sea
## camera zooms x2, so Rin is 16x32 on screen like in the restaurant.
func _draw() -> void:
	if boat_data == null:
		return
	# Deck outline; the bow points toward +X (Godot's rotation 0).
	var half := boat_data.hull_size * 0.5
	var deck := PackedVector2Array([
		Vector2(half.x, 0),
		Vector2(half.x * 0.3, -half.y),
		Vector2(-half.x, -half.y),
		Vector2(-half.x, half.y),
		Vector2(half.x * 0.3, half.y),
	])
	var down := Vector2.DOWN.rotated(-rotation) * hull_depth
	draw_colored_polygon(_shifted(deck, down * 1.8), Color(0, 0, 0, 0.25))  # shadow on the water
	# Art: one top view, bow to the right, turned with the boat (ASSETS.md).
	if Art.draw(self, "sea/" + boat_data.id, Rect2(-half, boat_data.hull_size)):
		_draw_crew(half)
		return
	var side := boat_data.color.darkened(0.45)
	for k in deck.size():
		var a := deck[k]
		var b := deck[(k + 1) % deck.size()]
		draw_colored_polygon(PackedVector2Array([a, b, b + down, a + down]), side)
	draw_colored_polygon(deck, boat_data.color)
	draw_colored_polygon(_scaled(deck, 0.7), boat_data.color.darkened(0.2))  # inside the hull
	_draw_crew(half)


## Upright figures (undo the boat's rotation around their feet).
func _draw_crew(half: Vector2) -> void:
	if _has_cat:
		draw_set_transform(Vector2(-half.x * 0.55, half.y * 0.2), -rotation)
		_draw_cat()
	draw_set_transform(Vector2(-half.x * 0.1, 0), -rotation)
	_draw_rin()
	draw_set_transform(Vector2.ZERO)


## Rin standing, 8x16 world px (16x32 on screen), in a nón lá.
func _draw_rin() -> void:
	if Art.draw(self, "sea/rin_boat", Rect2(-4, -16, 8, 16)):
		return
	draw_rect(Rect2(-2, -4, 1.5, 4), Color(0.25, 0.2, 0.15))  # legs
	draw_rect(Rect2(0.5, -4, 1.5, 4), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(-2.5, -9, 5, 5.5), Color(0.2, 0.45, 0.8))  # shirt
	draw_circle(Vector2(0, -10.8), 2.2, Color(0.95, 0.8, 0.65))  # head
	draw_colored_polygon(PackedVector2Array([Vector2(-4.5, -11.5), Vector2(4.5, -11.5), Vector2(0, -15.5)]),
		Color(0.9, 0.8, 0.5))  # conical hat


## The cat sitting up, eyes glowing a little (over-bright so they show
## through the night tint).
func _draw_cat() -> void:
	if Art.draw_sheet(self, "characters/cat", Rect2(-4, -8, 8, 8), 4, 0, _cat_time, 3.0):
		return
	var fur := Color(0.95, 0.6, 0.25)
	draw_circle(Vector2(0, -2.2), 2.4, fur)  # body
	draw_circle(Vector2(0.6, -5.2), 1.7, fur)  # head
	draw_colored_polygon(PackedVector2Array([Vector2(-0.7, -6.4), Vector2(-0.3, -8), Vector2(0.4, -6.6)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(1.0, -6.6), Vector2(1.7, -8), Vector2(2.1, -6.2)]), fur)
	draw_line(Vector2(-2, -1), Vector2(-3.5, -3 + sin(_cat_time * 2.0)), fur, 1.0)  # tail
	var glow := Color(0.6, 3.0, 2.0, 0.6 + 0.4 * sin(_cat_time * 0.7))
	draw_circle(Vector2(0.1, -5.4), 0.4, glow)
	draw_circle(Vector2(1.3, -5.4), 0.4, glow)


func _shifted(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(p + offset)
	return result


func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(p * factor)
	return result


func _process(delta: float) -> void:
	_cat_time += delta
	queue_redraw()  # the side face follows the rotation
