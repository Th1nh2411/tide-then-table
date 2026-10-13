class_name JellyfishBloom
extends Area2D
## Night event: a drifting swarm of glowing jellyfish. Pretty (lights up the
## dark sea) but driving through it tangles the propeller: small hull damage
## every few seconds while inside.

@export var hull: HullController
@export var hud: SeaHud
@export var radius: float = 60.0
@export var damage: float = 3.0
@export var damage_interval: float = 1.5
@export var drift: Vector2 = Vector2(6, -3)
@export var glow_color: Color = Color(0.5, 1.0, 0.95)
## Over-bright so the blobs show through the night tint.
@export var glow: float = 3.0
@export var blob_count: int = 14

var _boat_inside: bool = false
var _tick: float = 0.0
var _time: float = 0.0
var _blobs: Array[Vector3] = []


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	add_child(PointOfInterest.make_lamp(glow_color, radius * 1.4, 0.7))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in blob_count:
		var at := Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf() * radius * 0.9
		_blobs.append(Vector3(at.x, at.y, rng.randf() * TAU))
	body_entered.connect(func(body: Node2D) -> void: _boat_inside = _boat_inside or body is Boat)
	body_exited.connect(func(body: Node2D) -> void: _boat_inside = _boat_inside and not body is Boat)


func _process(delta: float) -> void:
	_time += delta
	position += drift * delta
	queue_redraw()
	if not _boat_inside:
		_tick = 0.0
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = damage_interval
		hull.apply_damage(damage)
		hud.flash_message("Sứa quấn chân vịt rồi! Phải thoát khỏi đàn sứa.", 1.5)


func _draw() -> void:
	for blob in _blobs:
		var pulse := 0.5 + 0.5 * sin(_time * 2.0 + blob.z)
		var color := Color(glow_color.r * glow, glow_color.g * glow, glow_color.b * glow, 0.25 + 0.35 * pulse)
		var at := Vector2(blob.x, blob.y) + Vector2(sin(_time + blob.z), cos(_time * 0.7 + blob.z)) * 3.0
		draw_circle(at, 2.5 + pulse * 1.5, color)
