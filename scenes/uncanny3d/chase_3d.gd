class_name Chase3D
extends Node3D
## A drowned / fog figure that noticed Rin comes after him (ProximityZone3D
## starts it; never spontaneous, at most one a night, UncannyDirector).
## It moves only while he is not looking and dashes when he turns away
## (ChaseRules.Runner); frozen and staring while he looks. Walking, he is
## caught; running (Shift) he gets away. It ends when he reaches a safe
## place (SafeZones3D), outlasts it (10-20 s) or leaves it far behind: the
## figure is gone the next time he looks, and the next morning wet steps
## lead up to his door. Caught: ProximityScare3D.caught (face, reset).

signal ended(caught: bool)

const NODE_NAME := "Chase"
## Set on the chasing body: its owner (fog signs, pier trick) leaves it alone.
const META := "chasing"
## Normal flag: the morning after an escape shows wet steps outside the door.
const TRACE_FLAG := "chase_trace"
const TUNING: ProximityTuning = preload("res://data/story/proximity_tuning.tres")
const FADE_SECONDS := 2.0

var host: Node3D
var body: Node3D
var actor: UncannyActor3D
var tuning := TUNING
var seconds := 14.0
var elapsed := 0.0
## False in tests: being caught sets the reset flag but does not reload.
var reload := true
var runner: ChaseRules.Runner
var _wait := 0.0
var _dash: Tween
var _over := false
var _caught := false
var _fading := 0.0


static func start(host_: Node3D, body_: Node3D, actor_: UncannyActor3D = null, t: ProximityTuning = TUNING) -> Chase3D:
	UncannyDirector.mark_chase()
	var chase := Chase3D.new()
	chase.name = NODE_NAME
	chase.host = host_
	chase.body = body_
	chase.actor = actor_
	chase.tuning = t
	chase.runner = ChaseRules.Runner.new(t)
	chase.seconds = ChaseRules.chase_seconds(LoopCalendar.loops(), GameState.day, t)
	chase._wait = t.start_wait
	body_.set_meta(META, true)
	host_.add_child(chase)
	return chase


## A chase is running in this scene.
static func running(host_: Node) -> bool:
	return host_ != null and host_.get_node_or_null(NODE_NAME) != null


func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	if actor and camera:
		actor.stare_at(camera, 150.0, 0.0)
	Sfx.duck(0.8, 0.0)
	Sfx.play("static", 0.2)


func _process(delta: float) -> void:
	if not is_instance_valid(body) or host == null:
		queue_free()
		return
	var camera := get_viewport().get_camera_3d()
	if _over:
		if not _caught:
			_fade_out(camera, delta)
		return
	var rin := (host.get("player") as Node3D).global_position
	var to := Vector3(rin.x - body.global_position.x, 0, rin.z - body.global_position.z)
	var gap := to.length()
	ProximityFx3D.of(host).push(lerpf(1.0, 0.45, clampf((gap - tuning.catch_distance) / 8.0, 0.0, 1.0)))
	if gap <= tuning.catch_distance:
		_finish(true)
		return
	elapsed += delta
	if elapsed >= seconds or gap > tuning.lose_distance or SafeZones3D.reason(host, rin, tuning) != "":
		_finish(false)
		return
	if _wait > 0.0:
		_wait -= delta
		return
	if _dash and _dash.is_running():
		return
	var step := runner.step(_seen(camera), delta)
	var move := minf(float(step["move"]), gap)
	UncannyMoves3D.face_dir(body, to)
	if move <= 0.0:
		_walk(0.0)
		if actor:
			actor.freeze()
		return
	var target := body.global_position + to.normalized() * move
	target.y = lerpf(body.global_position.y, rin.y, 0.2)
	if bool(step["dash"]):
		_dash_to(target)
	else:
		if actor:
			actor.release()
		body.global_position = target
		_walk(tuning.unseen_speed)


func _seen(camera: Camera3D) -> bool:
	var head := actor.head_position() if actor else body.global_position + Vector3.UP * 1.55
	return not UnseenCheck.all_unseen(camera, [body.global_position + Vector3.UP * 0.3, head] as Array[Vector3])


func _dash_to(target: Vector3) -> void:
	Sfx.play_at("drip", body.global_position + Vector3.UP * 0.3, host, 1.4, 3.0)
	if actor:
		_dash = UncannyMoves3D.dash_to(actor, target, tuning.dash_seconds, 0.0, 0.15)
		return
	_dash = body.create_tween()
	_dash.tween_property(body, "global_position", target, tuning.dash_seconds).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


func _walk(speed: float) -> void:
	if body is PersonRig3D:
		(body as PersonRig3D).set_walking(speed, elapsed)


func _finish(caught: bool) -> void:
	_over = true
	_caught = caught
	if _dash:
		_dash.kill()
	_walk(0.0)
	ended.emit(caught)
	if caught:
		ProximityScare3D.caught(host, reload, tuning)
		return
	GameState.set_flag(TRACE_FLAG)
	Sfx.play("static", 0.2)


## Gone into the fog the next time Rin isn't looking (or soon anyway).
func _fade_out(camera: Camera3D, delta: float) -> void:
	_fading += delta
	if _fading >= FADE_SECONDS or not _seen(camera):
		body.queue_free()
		queue_free()


## The morning after an escape: wet steps from the sea up to Rin's door.
static func leave_trace(room: Node3D) -> void:
	if not GameState.has_flag(TRACE_FLAG):
		return
	GameState.story_flags.erase(TRACE_FLAG)
	var door := VillageLayout3D.room_point(BedroomBuilder3D.DOOR)
	var prints := WetFootprints3D.build(room, door + Vector3(0.1, 0, -3.4), door + Vector3(0, 0, -0.75))
	prints.name = "ChaseFootprints"
