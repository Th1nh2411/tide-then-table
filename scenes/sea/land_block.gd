@tool
class_name LandBlock
extends StaticBody2D
## Rectangular solid area (shore, pier). Node position is the top-left corner.
## Draws itself and builds its own collision from `size`.

@export var size: Vector2 = Vector2(100, 50):
	set(value):
		size = value
		_rebuild()

@export var color: Color = Color(0.55, 0.5, 0.32):
	set(value):
		color = value
		queue_redraw()

var _shape_node: CollisionShape2D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node)
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape_node.shape = rect
	# Shapes are centered on their node, but our origin is the top-left corner.
	_shape_node.position = size * 0.5
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
