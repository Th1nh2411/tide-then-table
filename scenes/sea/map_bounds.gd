class_name MapBounds
extends StaticBody2D
## Invisible walls on all four map edges. Also the single source of truth
## for map size (camera limits read it from here).

@export var map_size: Vector2i = Vector2i(1920, 1280)


func _ready() -> void:
	# WorldBoundaryShape2D blocks everything on the opposite side of its normal.
	var walls := [
		[Vector2.DOWN, Vector2(0, 0)],              # top edge
		[Vector2.UP, Vector2(0, map_size.y)],       # bottom edge
		[Vector2.RIGHT, Vector2(0, 0)],             # left edge
		[Vector2.LEFT, Vector2(map_size.x, 0)],     # right edge
	]
	for wall in walls:
		var shape := WorldBoundaryShape2D.new()
		shape.normal = wall[0]
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = wall[1]
		add_child(collision)
