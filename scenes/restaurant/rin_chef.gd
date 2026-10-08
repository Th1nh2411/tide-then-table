class_name RinChef
extends StreetPerson
## Rin on the street restaurant (the player): WASD walks (sliding along
## solid cells), she faces the last direction moved, and E acts on the cell
## in front of her (`front_cell()`, Overcooked style) — the restaurant scene
## decides what that does (plate table, tables, or talking). `walk()` moves
## her on her own (e.g. to the stove before cooking).

signal interacted(cell: Vector2i)

@export var radius: float = 6.0

@export var room: StreetRoom
## False while a panel is open, cooking, cleaning or walking on her own.
var active: bool = false
## The shop is serving (the kitchen and tables work).
var kitchen_open: bool = false


func _ready() -> void:
	hat = true
	label = "Rin"
	speed = 95.0


func front_cell() -> Vector2i:
	return room.grid.to_cell(position) + facing


func cell() -> Vector2i:
	return room.grid.to_cell(position)


func _process(delta: float) -> void:
	if has_path():
		super(delta)
		return
	if active:
		var input := Vector2(Input.get_axis("turn_left", "turn_right"),
			Input.get_axis("throttle_forward", "throttle_back"))
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


func _try_move(step: Vector2) -> void:
	var next := position + step
	for corner: Vector2 in [Vector2(-radius, -radius * 0.5), Vector2(radius, -radius * 0.5),
			Vector2(-radius, radius * 0.5), Vector2(radius, radius * 0.5)]:
		if not room.grid.is_walkable(room.grid.to_cell(next + corner)):
			return
	position = next


func _unhandled_input(event: InputEvent) -> void:
	if active and not has_path() and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interacted.emit(front_cell())
