@tool
class_name Rock
extends StaticBody2D
## Round obstacle (rock or small island). Draws itself and builds its own
## collision from `radius`, so placing one in the editor is just position + radius.
## `submerged` rocks (đá ngầm) are only drawn where a light shines (boat lamp,
## dock, places), so in the dark they are invisible until you are close.

@export var radius: float = 20.0:
	set(value):
		radius = value
		_rebuild()

@export var color: Color = Color(0.45, 0.42, 0.38):
	set(value):
		color = value
		queue_redraw()

@export var submerged: bool = false:
	set(value):
		submerged = value
		_apply_material()

var _shape_node: CollisionShape2D


func _ready() -> void:
	_rebuild()
	_apply_material()


func _apply_material() -> void:
	if submerged:
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_LIGHT_ONLY
		material = mat
	else:
		material = null


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
	if submerged:
		# Pale foam ring: the water breaking over the rock.
		draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 16, Color(0.9, 0.95, 1.0, 0.7), 1.5)
