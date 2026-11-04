class_name ProximityZone3D
extends Node
## "Thấy lạ thì đừng lại gần": a zone round an avoidable phenomenon (the
## extra person, eyes in the dark, the fog figures, the pier-head figure,
## the guest without a shadow). From ~4 m the warning (ProximityFx3D:
## heartbeat, ducked sound, dark edges + grain) grows; under ~1.5 m it
## notices Rin: a drowned / fog figure (Kind.CHASE) may chase him (Chase3D,
## from mùng 12, once a night, not where `no_chase` says so); otherwise its
## face fills the view (ProximityScare3D), or early in the loop it simply
## vanishes. Never on things Rin must approach to play. A child of the thing.
## Arms only once Rin has been outside the band (never fires on a spawn).
## Chases only push Rin landward (ChaseRules.pushes_landward); nothing with
## the `uncanny_skip` meta (or under it) is ever guarded (ChaseRules.skipped).

enum Kind { SCARE, CHASE }

const NODE_NAME := "ProximityZone"
const TUNING: ProximityTuning = preload("res://data/story/proximity_tuning.tres")

signal noticed(reaction: int)

var target: Node3D
var kind := Kind.SCARE
var actor: UncannyActor3D
## Optional: true where a chase makes no sense (on the pier): a jump scare instead.
var no_chase: Callable
## Optional: removes the thing (default: target.queue_free()).
var on_gone: Callable
var tuning := TUNING
var host: Node3D
var _armed := false
var _done := false


static func guard(target_: Node3D, kind_: Kind = Kind.SCARE, actor_: UncannyActor3D = null) -> ProximityZone3D:
	if target_ == null or ChaseRules.skipped(target_):
		return null
	var zone := ProximityZone3D.new()
	zone.name = NODE_NAME
	zone.target = target_
	zone.kind = kind_
	zone.actor = actor_
	target_.add_child(zone)
	return zone


## The guard on a thing, if any.
static func of(target_: Node) -> ProximityZone3D:
	return target_.get_node_or_null(NODE_NAME) as ProximityZone3D


func _ready() -> void:
	var node := get_parent()
	while node and node.get("player") == null:
		node = node.get_parent()
	host = node as Node3D


## Flat metres from Rin's feet to the thing (INF when unknown).
func distance() -> float:
	if host == null:
		return INF
	var player := host.get("player") as Node3D
	if player == null:
		return INF
	var d := target.global_position - player.global_position
	return Vector2(d.x, d.z).length()


func _process(_delta: float) -> void:
	if _done or host == null or UncannyDirector.bot or _busy() or not target.is_visible_in_tree() \
			or ChaseRules.skipped(target):
		return
	var d := distance()
	if d > tuning.warn_distance:
		_armed = true
		return
	if not _armed or Chase3D.running(host):
		return
	ProximityFx3D.of(host).push(ChaseRules.warning(d, tuning))
	if ChaseRules.notices(d, tuning):
		notice()


func _near_water(at: Vector3) -> bool:
	return VillageLayout3D.area(at) == "waterfront" or VillageLayout3D.on_pier(at)


func _busy() -> bool:
	return get_tree().paused or host.get("leaving") == true or host.get("waking") == true


## Rin came too close: chase, face or vanish.
func notice() -> ChaseRules.Reaction:
	_done = true
	var player := host.get("player") as Node3D
	var can_chase := kind == Kind.CHASE and UncannyDirector.chase_allowed() \
		and not (no_chase.is_valid() and bool(no_chase.call())) \
		and ChaseRules.pushes_landward(target.global_position.z, player.global_position.z, _near_water(player.global_position))
	var safe := SafeZones3D.reason(host, player.global_position, tuning) != ""
	var reaction := ChaseRules.reaction(can_chase, UncannyDirector.close_scare_allowed(), safe)
	noticed.emit(reaction)
	match reaction:
		ChaseRules.Reaction.CHASE:
			Chase3D.start(host, target, actor, tuning)
			queue_free()
			return reaction
		ChaseRules.Reaction.SCARE:
			UncannyDirector.mark_scare()
			ProximityScare3D.jump(host, tuning)
		_:
			Sfx.play("static", 0.2)
	if on_gone.is_valid():
		on_gone.call()
		queue_free()
	else:
		target.queue_free()
	return reaction
