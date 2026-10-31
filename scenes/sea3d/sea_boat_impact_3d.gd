class_name SeaBoatImpact3D
extends RefCounted
## What a collision does to the 3D boat beyond hull damage: it bounces off
## (the part of the velocity into the obstacle flips and shrinks, the rest
## loses some speed to friction), a glancing hit spins it, the hull rocks on
## a spring and settles, the camera shakes, water splashes at the contact
## point, and it thuds. Owned by SeaScene3D (`sea.impact`).

## Fraction of the speed into the obstacle that comes back / speed kept along it.
const RESTITUTION := 0.4
const FRICTION := 0.75
## Spin (rad/s) per m/s of a glancing hit.
const SPIN := 0.35
## Hull rocking spring (stiffness, damping) and kick (rad/s per m/s).
const ROCK_STIFFNESS := 60.0
const ROCK_DAMPING := 5.0
const ROCK_KICK := 0.3
const ROCK_MAX := 0.3
const EFFECT_COOLDOWN := 0.25

## Extra roll (x) / pitch (y) of the hull from hits, and their velocity.
var rock := Vector2.ZERO
var _rock_velocity := Vector2.ZERO
var _shake_left: float = 0.0
var _shake_power: float = 0.0
var _cooldown: float = 0.0


## Bounces `before_velocity` off the collision; effects scale with speed.
func hit(sea: SeaScene3D, collision: KinematicCollision3D, before_velocity: Vector3, forward: Vector3) -> void:
	var boat := sea.boat
	var normal := collision.get_normal()
	normal.y = 0.0
	if normal.length_squared() < 0.0001:
		return
	normal = normal.normalized()
	var into := before_velocity.dot(normal)
	if into >= 0.0:
		return
	var along := before_velocity - normal * into
	boat.velocity = along * FRICTION - normal * into * RESTITUTION
	var speed := -into
	# Hitting with one side of the bow turns the boat away.
	sea.yaw_velocity += clampf(forward.cross(normal).y * speed * SPIN, -1.5, 1.5)
	var local := normal.rotated(Vector3.UP, -boat.rotation.y)
	_rock_velocity += Vector2(local.x, -local.z) * speed * ROCK_KICK
	if _cooldown > 0.0 or speed < 0.4:
		return
	_cooldown = EFFECT_COOLDOWN
	_shake_power = minf(speed * 0.035, 0.22)
	_shake_left = 0.35
	_splash(sea, collision.get_position(), speed)
	Sfx.play("bump" if speed > 1.0 else "flop")
	if speed > 1.5:
		Sfx.play("splash")


## Springs the rocking back, adds it to the hull's bob, shakes the camera.
## Call after SeaWorldBuilder3D.animate has set the visual and camera.
func apply(sea: SeaScene3D, delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_rock_velocity += (-rock * ROCK_STIFFNESS - _rock_velocity * ROCK_DAMPING) * delta
	rock = (rock + _rock_velocity * delta).clamp(-Vector2.ONE * ROCK_MAX, Vector2.ONE * ROCK_MAX)
	sea.boat_visual.rotation.z += rock.x
	sea.boat_visual.rotation.x += rock.y
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		var power := _shake_power * _shake_left / 0.35
		sea.camera.position += Vector3(randf_range(-power, power), randf_range(-power, power) * 0.6, 0.0)


## A burst of bright droplets at the contact point (glow through the night).
func _splash(sea: SeaScene3D, at: Vector3, speed: float) -> void:
	var drops := CPUParticles3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.85, 0.95, 1.0) * 2.5
	mesh.material = material
	drops.mesh = mesh
	drops.amount = clampi(roundi(speed * 6.0), 6, 24)
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.lifetime = 0.7
	drops.direction = Vector3.UP
	drops.spread = 55.0
	drops.initial_velocity_min = 1.5
	drops.initial_velocity_max = 2.0 + speed * 0.6
	drops.gravity = Vector3(0, -9.8, 0)
	drops.position = Vector3(at.x, 0.15, at.z)
	sea.add_child(drops)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)
