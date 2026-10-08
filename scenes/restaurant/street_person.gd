class_name StreetPerson
extends Node2D
## A person on the street restaurant (top-down 3/4): placeholder body drawn
## standing on its position (feet, 16x32 like Stardew), an optional carried
## plate, and path following for walkers (`walk()` + `arrived`). Lives in a
## y-sorted layer. Base of Rin (RinChef), Bảo (Waiter) and Customer.

signal arrived

@export var body_color: Color = Color(0.2, 0.45, 0.8)
@export var speed: float = 70.0
@export var label: String = ""
@export var hat: bool = false
@export var apron: bool = false
@export var tie: bool = false

## Plate in hands (null = none).
var carried: DishShelf.Plate
var facing: Vector2i = Vector2i.DOWN

var _path: Array[Vector2] = []
var _walk_time: float = 0.0


func walk(points: Array[Vector2]) -> void:
	_path = points.duplicate()
	if _path.is_empty():
		arrived.emit()


## Walks the path and waits until there (returns at once when already there).
func walk_and_wait(points: Array[Vector2]) -> void:
	walk(points)
	if has_path():
		await arrived


func has_path() -> bool:
	return not _path.is_empty()


func is_walking() -> bool:
	return has_path()


func talk_position() -> Vector2:
	return position


func _process(delta: float) -> void:
	_follow_path(delta)
	queue_redraw()


func _follow_path(delta: float) -> void:
	if _path.is_empty():
		return
	_walk_time += delta
	var step := _path[0] - position
	if step.length() <= speed * delta:
		position = _path[0]
		_path.remove_at(0)
		if _path.is_empty():
			_walk_time = 0.0
			arrived.emit()
	else:
		_set_facing(step)
		position += step.normalized() * speed * delta


func _set_facing(step: Vector2) -> void:
	if absf(step.x) > absf(step.y):
		facing = Vector2i(int(signf(step.x)), 0)
	else:
		facing = Vector2i(0, int(signf(step.y)))


func _draw() -> void:
	var bob := absf(sin(_walk_time * 12.0)) * 1.5 if is_walking() else 0.0
	draw_circle(Vector2(0, 1), 6.0, Color(0, 0, 0, 0.25))  # shadow
	draw_set_transform(Vector2(0, -bob))
	draw_rect(Rect2(-6, -16, 12, 14), body_color)
	if apron:
		draw_rect(Rect2(-4, -10, 8, 8), Color(0.95, 0.9, 0.8))
	if tie:
		draw_rect(Rect2(-1, -15, 2, 7), Color(0.6, 0.15, 0.15))
	draw_circle(Vector2(0, -21), 6.0, Color(0.95, 0.8, 0.65))
	if hat:
		draw_rect(Rect2(-5, -31, 10, 5), Color.WHITE)
	if facing != Vector2i.UP:  # eyes unless seen from behind
		var side := float(facing.x) * 2.5
		draw_circle(Vector2(-2 + side, -21), 0.9, Color.BLACK)
		draw_circle(Vector2(2 + side, -21), 0.9, Color.BLACK)
	if carried:
		StreetProps.draw_plate(self, carried, Vector2(float(facing.x) * 7.0, -12 + (2.0 if facing == Vector2i.DOWN else 0.0)))
	draw_set_transform(Vector2.ZERO)
	if label:
		draw_string(ThemeDB.fallback_font, Vector2(-12, -36), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 7,
			Color(1, 1, 1, 0.7))
