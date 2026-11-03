class_name TuGhostScare3D
extends Node3D
## Jump scare (b), once per playthrough (UncannyDirector.TU_FLAG, kept
## through resets): mùng 13 at night on the waterfront. The sound drops
## away, a slow breath and dripping water right behind Rin. When he turns
## round, ông Tư (drowned, pale) stands an arm's length away, pointing out
## to sea towards the raft; a moment later he is gone. If Rin never turns,
## he leaves unseen and tries again later that night.

## Seconds on the waterfront (facing the sea) before it starts.
@export var after_seconds := 5.0
@export var behind := 1.0
@export var seen_seconds := 1.1
@export var give_up_seconds := 9.0
@export var retry_seconds := 25.0
## Out to sea, towards the raft (village -Z is the sea).
@export var raft_direction := Vector3(0.45, 0.12, -1.0)

## Returns true while Rin is where this may happen (waterfront, not busy).
var gate: Callable
var say: Callable
var _wait := 0.0
var _ghost: Node3D
var _actor: UncannyActor3D
var _seen_for := 0.0
var _alive := 0.0
var _done := false


static func attach(host: Node3D, gate_: Callable, say_: Callable) -> TuGhostScare3D:
	if not UncannyDirector.tu_scare_due():
		return null
	var scare := TuGhostScare3D.new()
	scare.name = "TuGhostScare"
	scare.gate = gate_
	scare.say = say_
	host.add_child(scare)
	return scare


func _ready() -> void:
	_wait = after_seconds


func _process(delta: float) -> void:
	if _done:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if _ghost == null:
		if not bool(gate.call()):
			_wait = maxf(_wait, 1.0)
			return
		_wait -= delta
		if _wait <= 0.0:
			_appear(camera)
		return
	_alive += delta
	var head := _actor.head_position()
	if UnseenCheck.camera_sees(camera, head, 0.0) and UnseenCheck.look_angle(camera, head) < 30.0:
		_seen_for += delta
		if _seen_for >= seen_seconds:
			_finish(true)
	elif _seen_for > 0.0 or _alive > give_up_seconds:
		_finish(_seen_for > 0.0)


## Right behind Rin, out of view, facing him.
func _appear(camera: Camera3D) -> void:
	Sfx.duck(2.5, 0.0)
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var feet := camera.global_position - Vector3(0, FirstPersonView3D.EYE_RESTAURANT.y, 0) - forward * behind
	var material := RamFx3D.ghost(self, Vector3.ZERO, "ong_tu")
	RamFx3D.set_ghost_alpha(material, 0.9)  # close behind Rin: nearly solid
	_ghost = RamFx3D.ghost_holder(material)
	_ghost.global_position = feet
	var rig := _ghost.get_meta("rig") as PersonRig3D
	UncannyMoves3D.face_dir(rig, forward)
	UncannyMoves3D.ghost_body(rig)
	_actor = UncannyActor3D.attach(rig)
	_actor.stare_at(camera, 150.0, 0.0)
	var arm := UncannyPointArm3D.new()
	arm.direction = raft_direction.normalized()
	rig.visual().skeleton.add_child(arm)
	await get_tree().create_timer(1.0).timeout
	if _ghost and not _done:
		Sfx.play_at("breath_close", feet + Vector3.UP * 1.6, self, 1.0, 2.0)
		Sfx.play_at("drip", feet + Vector3.UP * 0.2, self, 1.0, 2.0)


func _finish(seen: bool) -> void:
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	_seen_for = 0.0
	_alive = 0.0
	if not seen:
		_wait = retry_seconds
		return
	_done = true
	GameState.set_flag(UncannyDirector.TU_FLAG)
	UncannyDirector.mark_scare()
	Sfx.play("static", 0.1)
	if say.is_valid():
		say.call("...Ông?", 2.5)
	queue_free()
