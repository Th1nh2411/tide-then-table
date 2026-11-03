class_name UnseenTrick3D
extends Node3D
## Does something only while Rin can't see it (UnseenCheck): waits until
## every watched point (where the thing is now and where it goes) has been
## out of view for `unseen_seconds`, then calls `act` once per step. With
## `seen_first` it also waits for Rin to have looked at the thing once, so
## the change is noticed. `steps` > 1 repeats (a figure closer each look).
## Frees itself after the last step.

signal acted(step: int)

var act: Callable
## Returns the points to keep out of view for a step: func(step) -> Array[Vector3].
var points: Callable
var steps := 1
var unseen_seconds := 0.6
var seen_first := true
## Optional: only act while this returns true.
var gate: Callable
var step := 0
var _seen := false
var _unseen_for := 0.0


static func watch(host: Node, act_: Callable, points_: Callable, steps_: int = 1, seen_first_: bool = true) -> UnseenTrick3D:
	var trick := UnseenTrick3D.new()
	trick.name = "UnseenTrick"
	trick.act = act_
	trick.points = points_
	trick.steps = steps_
	trick.seen_first = seen_first_
	host.add_child(trick)
	return trick


func _process(delta: float) -> void:
	if step >= steps:
		queue_free()
		return
	if gate.is_valid() and not bool(gate.call()):
		_unseen_for = 0.0
		return
	var camera := get_viewport().get_camera_3d()
	var watched: Array[Vector3] = []
	watched.assign(points.call(step))
	if UnseenCheck.all_unseen(camera, watched):
		_unseen_for += delta
	else:
		_seen = true
		_unseen_for = 0.0
	if (_seen or not seen_first) and _unseen_for >= unseen_seconds:
		act.call(step)
		acted.emit(step)
		step += 1
		_seen = false
		_unseen_for = 0.0
