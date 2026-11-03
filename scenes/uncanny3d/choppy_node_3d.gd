class_name ChoppyNode3D
extends Node
## Runs another node's _process at a few frames a second (for figures that
## have no skeleton, e.g. DarkNightFigure3D): it moves and turns in steps
## while the world around it runs smooth.

var target: Node
var fps := 7.0
var _acc := 0.0


static func wrap(node: Node, frames_per_second: float) -> ChoppyNode3D:
	var choppy := ChoppyNode3D.new()
	choppy.name = "Choppy"
	choppy.target = node
	choppy.fps = maxf(frames_per_second, 1.0)
	node.add_child(choppy)
	return choppy


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if target.is_processing():
		target.set_process(false)
	_acc += delta
	if _acc >= 1.0 / fps:
		target.call("_process", _acc)
		_acc = 0.0
