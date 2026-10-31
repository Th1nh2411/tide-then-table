class_name RinMover3D
extends RefCounted
## Rin's walking in the 3D restaurant: WASD relative to the camera, carry
## speed, Shift runs while stamina lasts (StaminaBar3D over his head), Space
## rolls (dash) with a cooldown, Nhịp Sóng keeps his real-time speed, and
## inputs released when the window loses focus.
## Speeds are the host's exports (walk_speed, carry_speed, run_*, stamina_*, roll_*).

var host: Node3D
var dash_left: float = 0.0
var focus_lost: bool = false
## 0..1; empty = winded until it refills to stamina_resume.
var stamina: float = 1.0
var winded: bool = false
var _rest_clock: float = 0.0
var _bar := StaminaBar3D.new()
var _dash_cooldown: float = 0.0
var _dash_direction := Vector3.ZERO
var _time_scale := 1.0


func _init(owner: Node3D) -> void:
	host = owner
	host.add_child(_bar)


## Stands still (paused, modal open or window unfocused).
func stop(delta: float) -> void:
	host.player.velocity = Vector3.ZERO
	host.body.drive_ground_motion(Vector3.ZERO, delta, false)
	_bar.visible = false


func move(delta: float) -> void:
	var player: CharacterBody3D = host.player
	var body: PersonRig3D = host.body
	var axes := Input.get_vector("turn_left", "turn_right", "throttle_forward", "throttle_back")
	var rin_scale := 1.0 / maxf(Engine.time_scale, 0.001) if WavePower.rin_unslowed else 1.0
	# Keep acceleration and momentum in real-time units when Wave Power slows the world.
	player.velocity *= rin_scale / _time_scale
	_time_scale = rin_scale
	var camera: Camera3D = host.demo_camera
	var right := camera.global_basis.x
	right.y = 0.0
	var forward := camera.global_basis.z
	forward.y = 0.0
	var direction: Vector3 = (right.normalized() * axes.x + forward.normalized() * axes.y).limit_length(1.0)
	_dash_cooldown = maxf(_dash_cooldown - delta * rin_scale, 0.0)
	if Input.is_action_just_pressed("dash") and _dash_cooldown <= 0.0 and direction.length_squared() > 0.01:
		dash_left = host.roll_seconds
		_dash_cooldown = host.roll_seconds + host.roll_cooldown
		_dash_direction = direction.normalized()
		player.rotation.y = atan2(_dash_direction.x, _dash_direction.z)
		body.play_once("CharacterArmature|Roll", host.roll_seconds)
	if dash_left > 0.0:
		dash_left = maxf(dash_left - delta * rin_scale, 0.0)
		# Fast through the tumble, easing off as he gets up.
		var t := dash_left / maxf(host.roll_seconds, 0.01)
		player.velocity = _dash_direction * host.roll_speed * lerpf(0.5, 1.2, t) * rin_scale
	else:
		var speed: float = host.carry_speed if host.carrying_table >= 0 else host.walk_speed
		if _run_stamina(delta * rin_scale, direction.length_squared() > 0.01):
			speed *= host.run_speed / host.walk_speed
		var desired := direction * speed * rin_scale
		# Dash ends at walking/running speed, rather than coasting several extra metres.
		player.velocity = player.velocity.limit_length(speed * rin_scale)
		player.velocity = player.velocity.move_toward(desired,
			(20.0 if axes.length_squared() > .01 else 28.0) * delta * rin_scale * rin_scale)
	var before := player.global_position
	player.move_and_slide()
	var moved := player.global_position - before
	host.step_clock += delta * rin_scale
	if moved.length_squared() > 0.000001:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(moved.x, moved.z), 1.0 - exp(-16.0 * delta * rin_scale))
	body.set_carrying(host.carrying_table >= 0)
	body.drive_ground_motion(moved, delta, false)
	_bar.show_at(host.demo_camera, player.global_position, stamina)


## Drains while Shift is held and Rin moves, refills after a short rest.
## True while he runs.
func _run_stamina(delta: float, moving: bool) -> bool:
	if winded and stamina >= host.stamina_resume:
		winded = false
	var running := moving and Input.is_action_pressed("sprint") and not winded
	if running:
		stamina = maxf(stamina - delta / host.stamina_seconds, 0.0)
		_rest_clock = 0.0
		if stamina <= 0.0:
			winded = true
	else:
		_rest_clock += delta
		if _rest_clock >= host.stamina_rest_delay:
			stamina = minf(stamina + delta / host.stamina_refill_seconds, 1.0)
	return running


## Window focus out: drop held keys so Rin doesn't keep walking.
func on_focus(focused: bool) -> void:
	focus_lost = not focused
	if focus_lost:
		dash_left = 0.0
		for action: String in ["turn_left", "turn_right", "throttle_forward", "throttle_back", "dash", "sprint"]:
			Input.action_release(action)
