class_name Dock
extends Area2D
## Docking zone next to the pier. While the boat is inside, `interact`
## requests ending the sea day.

signal boat_entered
signal boat_exited
signal docking_requested

var _boat_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


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
