class_name UncannyHeavy3D
extends Node3D
## The night's one heavy effect (UncannyDirector, mùng 13-14), always after
## ~1 s of near silence (Sfx.duck):
## APPEAR_CLOSE: a drowned figure far off; every time Rin looks away it is
##   closer, the last time right beside him (~1 m). Seen there: gone.
## DASH: a figure standing dead still far away; Rin looks at it, the sound
##   drops, it sprints at him and stops dead a few metres off, then is gone.
## FLASH: one rendered frame of someone right behind him (SingleFrameFlash3D,
##   skipped when flashes are off in the settings).
## `gate` (optional) keeps it waiting until Rin is in the right place.
## Ghosts warn, never touch: no collider, no damage.

signal finished

enum Kind { APPEAR_CLOSE, DASH, FLASH }

## APPEAR_CLOSE distances from Rin, one per unseen moment.
@export var steps: Array[float] = [12.0, 7.0, 3.5, 1.1]
@export var dash_from := 13.0
@export var dash_stop := 3.0
@export var dash_seconds := 0.3
@export var look_before_dash := 0.8
@export var give_up_seconds := 10.0

var kind := Kind.APPEAR_CLOSE
var gate: Callable
## Ground height for the figure (sea: water level), NAN = Rin's feet.
var ground_y := NAN
var rig_kind := "drowned"
var _rig: PersonRig3D
var _actor: UncannyActor3D
var _step := 0
var _bearing := Vector3.ZERO
var _looked := 0.0
var _left := 0.0
var _dashed := false
var _done := false


static func start(host: Node3D, kind_: Kind, gate_: Callable = Callable()) -> UncannyHeavy3D:
	var heavy := UncannyHeavy3D.new()
	heavy.name = "UncannyHeavy"
	heavy.kind = kind_
	heavy.gate = gate_
	host.add_child(heavy)
	return heavy


func _process(delta: float) -> void:
	if _done:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if _rig == null:
		if gate.is_valid() and not bool(gate.call()):
			return
		_begin(camera)
		return
	_left -= delta
	match kind:
		Kind.APPEAR_CLOSE:
			_tick_close(camera)
		Kind.DASH:
			_tick_dash(camera, delta)
	if _left <= 0.0 and not _seen(camera):
		_end()


func _begin(camera: Camera3D) -> void:
	_left = give_up_seconds
	if kind == Kind.FLASH:
		Sfx.duck(1.6, 0.0)
		await get_tree().create_timer(1.0).timeout
		SingleFrameFlash3D.play(get_parent() as Node3D)
		_end()
		return
	var forward := _flat(-camera.global_basis.z)
	# Both start out of view: APPEAR_CLOSE behind-left, DASH off to the side.
	_bearing = forward.rotated(Vector3.UP, 2.4) if kind == Kind.APPEAR_CLOSE else forward.rotated(Vector3.UP, 1.4)
	_rig = PersonRig3D.build(self, rig_kind)
	UncannyMoves3D.ghost_body(_rig)
	_actor = UncannyActor3D.attach(_rig)
	_place(camera, steps[0] if kind == Kind.APPEAR_CLOSE else dash_from)
	_actor.freeze()


func _tick_close(camera: Camera3D) -> void:
	var seen := _seen(camera)
	if _step >= steps.size() - 1:
		if seen:
			_looked += get_process_delta_time()
			if _looked > 0.5:
				_end()
		return
	if seen:
		_looked = 1.0
		return
	if _looked <= 0.0:
		return
	# Looked at, now unseen: one step closer (the last one beside him).
	_step += 1
	_looked = 0.0
	_left = give_up_seconds
	# Just out of view: beside him at the end, further round before that.
	var side := 1.0 if _step % 2 == 0 else -1.0
	var angle := 1.75 if _step == steps.size() - 1 else 2.3
	_bearing = _flat(-camera.global_basis.z).rotated(Vector3.UP, side * angle)
	_place(camera, steps[_step])
	if _step == steps.size() - 1:
		Sfx.duck(3.0, 0.0)
		Sfx.play_at("drip", _rig.global_position + Vector3.UP * 0.3, self, 1.0, 2.0)
		_actor.stare_at(camera, 150.0, 0.0)


func _tick_dash(camera: Camera3D, delta: float) -> void:
	if _dashed:
		return
	if UnseenCheck.look_angle(camera, _actor.head_position()) < 18.0:
		_looked += delta
	if _looked >= look_before_dash:
		_dashed = true
		_left = 4.0
		Sfx.duck(2.0, 0.0)
		_actor.stare_at(camera, 150.0, 0.0)
		var to := _ground(camera) + _flat(_rig.global_position - camera.global_position) * dash_stop
		UncannyMoves3D.dash_to(_actor, to, dash_seconds, 1.0, 3.0)


func _seen(camera: Camera3D) -> bool:
	return _actor != null and not UnseenCheck.all_unseen(camera, [_rig.global_position + Vector3.UP * 0.3, _actor.head_position()] as Array[Vector3])


func _place(camera: Camera3D, distance: float) -> void:
	_rig.global_position = _ground(camera) + _bearing * distance
	UncannyMoves3D.face_dir(_rig, camera.global_position - _rig.global_position)


func _ground(camera: Camera3D) -> Vector3:
	var y := camera.global_position.y - FirstPersonView3D.EYE_RESTAURANT.y if is_nan(ground_y) else ground_y
	return Vector3(camera.global_position.x, y, camera.global_position.z)


func _flat(v: Vector3) -> Vector3:
	var f := Vector3(v.x, 0, v.z)
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD


func _end() -> void:
	if _done:
		return
	_done = true
	if _rig:
		Sfx.play("static", 0.2)
	finished.emit()
	queue_free()
