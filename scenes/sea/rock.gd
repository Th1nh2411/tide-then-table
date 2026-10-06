@tool
class_name Rock
extends StaticBody2D
## Round obstacle (rock or small island). Draws itself and builds its own
## collision from `radius`, so placing one in the editor is just position + radius.

@export var radius: float = 20.0:
	set(value):
		radius = value
		_rebuild()

@export var color: Color = Color(0.45, 0.42, 0.38):
	set(value):
		color = value
		queue_redraw()

var _shape_node: CollisionShape2D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	# Setters run before the node enters the tree while loading; _ready handles that case.
	if not is_inside_tree():
		return
	if _shape_node == null:
		# Created at runtime without an owner, so it is never saved into the scene.
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape_node.shape = circle
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
