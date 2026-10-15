class_name RinChef
extends StreetPerson
## Rin on the street restaurant (the player): WASD walks (sliding along
## solid cells), he faces the last direction moved, and E acts on the cell
## in front of him (`front_cell()`, Overcooked style) — the restaurant scene
## decides what that does (plate table, tables, or talking). `walk()` moves
## him on his own (e.g. to the stove before cooking). Shift dashes: a short
## burst the way he's walking (or facing), stopped by solid cells like
## walking, with a cooldown; speed lines while dashing, dust when it ends.

signal interacted(cell: Vector2i)

@export var radius: float = 6.0
@export var dash_speed: float = 330.0
@export var dash_seconds: float = 0.14
@export var dash_cooldown: float = 0.45

@export var room: StreetRoom
## False while a panel is open, cooking, cleaning or walking on his own.
var active: bool = false
## The shop is serving (the kitchen and tables work).
var kitchen_open: bool = false
## Groceries in his bag, not in the fridge yet (set by the restaurant).
var carrying_goods: bool = false

var _dash_left: float = 0.0
var _dash_cool: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _dust: Array[Dictionary] = []  # {"at": Vector2 (room), "age": float}


func _ready() -> void:
	hat = true
	label = "Rin"
	speed = 95.0


func front_cell() -> Vector2i:
	return room.grid.to_cell(position) + facing


func cell() -> Vector2i:
	return room.grid.to_cell(position)


func _process(delta: float) -> void:
	if WavePower.rin_unslowed:  # Nhịp Sóng: the street is slowed, Rin isn't
		delta /= maxf(Engine.time_scale, 0.001)
	_dash_cool -= delta
	for puff in _dust:
		puff["age"] = float(puff["age"]) + delta
	_dust.assign(_dust.filter(func(puff: Dictionary) -> bool: return float(puff["age"]) < 0.35))
	if has_path():
		_dash_left = 0.0
		super(delta)
		return
	if _dash_left > 0.0:
		_dash_left -= delta
		var step := _dash_dir * dash_speed * delta
		_try_move(Vector2(step.x, 0))
		_try_move(Vector2(0, step.y))
		_walk_time += delta
		if _dash_left <= 0.0:
			for k in 3:
				_dust.append({"at": position + Vector2(randf_range(-5, 5), randf_range(-1, 2)), "age": k * 0.04})
	elif active:
		var input := _input_dir()
		if input != Vector2.ZERO:
			_set_facing(input)
			var step := input.normalized() * speed * delta
			_try_move(Vector2(step.x, 0))
			_try_move(Vector2(0, step.y))
			_walk_time += delta
		else:
			_walk_time = 0.0
	queue_redraw()


func is_walking() -> bool:
	return _walk_time > 0.0 or has_path()


func is_dashing() -> bool:
	return _dash_left > 0.0


func _input_dir() -> Vector2:
	return Vector2(Input.get_axis("turn_left", "turn_right"), Input.get_axis("throttle_forward", "throttle_back"))


func _dash() -> void:
	var dir := _input_dir()
	_dash_dir = dir.normalized() if dir != Vector2.ZERO else Vector2(facing)
	_set_facing(_dash_dir)
	_dash_left = dash_seconds
	_dash_cool = dash_cooldown


func _draw() -> void:
	for puff in _dust:  # dust where the dash ended
		var age: float = puff["age"]
		var at: Vector2 = puff["at"]
		draw_circle(at - position, 2.0 + age * 10.0, Color(0.85, 0.82, 0.75, 0.6 * (1.0 - age / 0.35)))
	if is_dashing():  # speed lines behind him
		for k in 3:
			var side := Vector2(-_dash_dir.y, _dash_dir.x) * (k - 1) * 5.0
			var from := -_dash_dir * 8.0 + side + Vector2(0, -12)
			draw_line(from, from - _dash_dir * 12.0, Color(1, 1, 1, 0.6), 1.0)
	super()
	if carrying_goods:  # a green plastic shopping bag in his hand
		var side := -7.0 if facing.x >= 0 else 7.0
		draw_rect(Rect2(side - 3, -13, 6, 7), Color(0.3, 0.7, 0.35))
		draw_line(Vector2(side - 2, -13), Vector2(side, -16), Color(0.3, 0.7, 0.35), 1.0)
		draw_line(Vector2(side + 2, -13), Vector2(side, -16), Color(0.3, 0.7, 0.35), 1.0)
		draw_rect(Rect2(side - 2, -14, 4, 2), Color(0.35, 0.65, 0.25))  # greens sticking out


func _try_move(step: Vector2) -> void:
	var next := position + step
	for corner: Vector2 in [Vector2(-radius, -radius * 0.5), Vector2(radius, -radius * 0.5),
			Vector2(-radius, radius * 0.5), Vector2(radius, radius * 0.5)]:
		if not room.grid.is_walkable(room.grid.to_cell(next + corner)):
			return
	position = next


func _unhandled_input(event: InputEvent) -> void:
	if not active or has_path():
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit(front_cell())
	elif event.is_action_pressed("dash") and _dash_cool <= 0.0:
		get_viewport().set_input_as_handled()
		_dash()
