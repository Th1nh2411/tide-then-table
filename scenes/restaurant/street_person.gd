class_name StreetPerson
extends Node2D
## A person on the street restaurant (top-down 3/4): placeholder body drawn
## standing on its position (feet, 16x32 like Stardew), an optional carried
## plate, and path following for walkers (`walk()` + `arrived`). Lives in a
## y-sorted layer. Base of Rin (RinChef), Bảo (ChefBao) and Customer.

signal arrived

@export var body_color: Color = Color(0.2, 0.45, 0.8)
@export var speed: float = 70.0
@export var label: String = ""
@export var hat: bool = false
@export var apron: bool = false
@export var tie: bool = false
## Sprite sheet under assets/sprites (e.g. "characters/rin", see Art); the
## placeholder body is drawn while the PNG doesn't exist.
@export var sprite: String = ""

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
	facing = facing_for(step, facing)


## 4-way facing for a move. Near-diagonal moves keep the current facing when
## it is one of the two axes (no flip-flopping), else face sideways.
static func facing_for(step: Vector2, current: Vector2i) -> Vector2i:
	var side := Vector2i(int(signf(step.x)), 0)
	var vertical := Vector2i(0, int(signf(step.y)))
	var ax := absf(step.x)
	var ay := absf(step.y)
	if ax == 0.0 and ay == 0.0:
		return current
	if minf(ax, ay) >= 0.5 * maxf(ax, ay):  # roughly diagonal
		if current == side or current == vertical:
			return current
		return side
	return side if ax > ay else vertical


func _draw() -> void:
	var bob := 0.0  # placeholder bob; sheets have their own walk frames
	if is_walking() and not Art.has(sprite_name()):
		bob = absf(sin(_walk_time * 12.0)) * 1.5
	var pose_offset := pose_draw_offset()
	draw_circle(pose_offset + Vector2(0, 1), 6.0, Color(0, 0, 0, 0.25))  # shadow
	draw_set_transform(pose_offset + Vector2(0, -bob))
	var now := Time.get_ticks_msec() * 0.001
	var busy_sprite := busy_sprite_name()
	var drawn := false
	if is_busy_pose() and busy_sprite != "" and Art.has(busy_sprite):
		drawn = Art.draw_sheet(self, busy_sprite, Rect2(-8, -32, 16, 32), 4, 0, now, 4.0)
	else:
		# When facing away, the carried plate belongs behind the torso/arms.
		if carried and facing == Vector2i.UP:
			StreetProps.draw_plate(self, carried, carried_plate_position())
		drawn = Art.draw_person(self, sprite_name(), facing, _walk_time, is_walking(), is_busy_pose(), now)
	if not drawn:
		_draw_placeholder_body()
	if carried and facing != Vector2i.UP:
		StreetProps.draw_plate(self, carried, carried_plate_position())
	draw_set_transform(Vector2.ZERO)
	if label:
		draw_string(ThemeDB.fallback_font, Vector2(-12, -36), label, HORIZONTAL_ALIGNMENT_CENTER, 24, 7,
			Color(1, 1, 1, 0.7))


## Which sheet to draw (subclasses pick by who they are).
func sprite_name() -> String:
	return sprite


func carried_plate_position() -> Vector2:
	if facing == Vector2i.DOWN:
		return Vector2(0, -13)
	if facing == Vector2i.UP:
		return Vector2(0, -17)
	return Vector2(float(facing.x) * 7.0, -14)


## True while sitting / cooking: the sheet's "busy" row.
func is_busy_pose() -> bool:
	return false


## Visual-only pose adjustment. Keep the node/pathfinding position unchanged.
func pose_draw_offset() -> Vector2:
	return Vector2.ZERO


## Optional one-row (4 x 16x32) sheet used instead of the main sheet's busy
## row. Subclasses can switch this by state; an absent asset falls back safely.
func busy_sprite_name() -> String:
	return ""


func has_busy_sprite() -> bool:
	var name := busy_sprite_name()
	return name != "" and Art.has(name)


func _draw_placeholder_body() -> void:
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
