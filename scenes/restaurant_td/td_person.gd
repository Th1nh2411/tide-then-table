class_name TdPerson
extends Node2D
## A person in the top-down (3/4) room: placeholder body drawn standing on
## its position (feet), an optional carried plate, and simple path following
## for AI walkers (customers, Bảo). Children of a y-sorted node.

signal arrived

@export var body_color: Color = Color(0.2, 0.45, 0.8)
@export var hat: bool = false
@export var speed: float = 70.0
@export var label: String = ""

## Plate in hands (null = none).
var carried: TdPlate
var facing: Vector2i = Vector2i.DOWN

var _path: Array[Vector2] = []
var _walk_time: float = 0.0


func walk(points: Array[Vector2]) -> void:
	_path = points.duplicate()
	if _path.is_empty():
		arrived.emit()


func is_walking() -> bool:
	return has_path()


func has_path() -> bool:
	return not _path.is_empty()


func _process(delta: float) -> void:
	if not _path.is_empty():
		_walk_time += delta
		var target := _path[0]
		var step := target - position
		if step.length() <= speed * delta:
			position = target
			_path.remove_at(0)
			if _path.is_empty():
				arrived.emit()
		else:
			_set_facing(step)
			position += step.normalized() * speed * delta
	queue_redraw()


func _set_facing(step: Vector2) -> void:
	if absf(step.x) > absf(step.y):
		facing = Vector2i(signi(int(signf(step.x))), 0)
	else:
		facing = Vector2i(0, signi(int(signf(step.y))))


func _draw() -> void:
	var bob := absf(sin(_walk_time * 12.0)) * 1.5 if is_walking() else 0.0
	draw_set_transform(Vector2(0, -bob))
	draw_circle(Vector2(0, 1 + bob), 6.0, Color(0, 0, 0, 0.25))  # shadow
	draw_rect(Rect2(-6, -16, 12, 14), body_color)
	draw_circle(Vector2(0, -21), 6.0, Color(0.95, 0.8, 0.65))
	if hat:
		draw_rect(Rect2(-5, -31, 10, 5), Color.WHITE)
	if facing != Vector2i.UP:  # eyes unless seen from behind
		var side := float(facing.x) * 2.5
		draw_circle(Vector2(-2 + side, -21), 0.9, Color.BLACK)
		draw_circle(Vector2(2 + side, -21), 0.9, Color.BLACK)
	if carried:
		var at := Vector2(float(facing.x) * 7.0, -12 + (2.0 if facing == Vector2i.DOWN else 0.0))
		carried.draw_at(self, at)
	draw_set_transform(Vector2.ZERO)
	if label:
		draw_string(ThemeDB.fallback_font, Vector2(-12, -36), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 7,
			Color(1, 1, 1, 0.7))
