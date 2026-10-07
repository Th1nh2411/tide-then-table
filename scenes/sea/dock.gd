class_name Dock
extends Area2D
## Docking zone next to the pier. While the boat is inside, `interact`
## requests ending the sea day, and the lamp burns no oil (LampOil checks
## is_boat_inside). A lamp post lights the dock at night (PointLight2D child
## "Light" shows through the night tint; it flickers a little).

signal boat_entered
signal boat_exited
signal docking_requested

@export var post_offset: Vector2 = Vector2(-30.0, -40.0)
@export var post_color: Color = Color(0.3, 0.22, 0.15)
@export var bulb_color: Color = Color(1.0, 0.85, 0.5)
@export var flicker_amount: float = 0.08

var _boat_inside: bool = false
var _time: float = 0.0
var _base_energy: float = 1.0

@onready var _light: PointLight2D = get_node_or_null("Light")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _light:
		_light.position = post_offset
		_base_energy = _light.energy


func is_boat_inside() -> bool:
	return _boat_inside


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta
	_light.energy = _base_energy * (1.0 + flicker_amount * sin(_time * 7.0) * sin(_time * 2.3))


func _draw() -> void:
	draw_line(post_offset + Vector2(0, 14), post_offset, post_color, 2.0)
	draw_circle(post_offset, 3.0, bulb_color)


func _unhandled_input(event: InputEvent) -> void:
	if _boat_inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		docking_requested.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is Boat:
		_boat_inside = true
		boat_entered.emit()


func _on_body_exited(body: Node2D) -> void:
	if body is Boat:
		_boat_inside = false
		boat_exited.emit()
