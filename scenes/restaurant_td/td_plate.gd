class_name TdPlate
extends RefCounted
## A cooked dish in the top-down prototype (on a counter or in someone's hands).

var dish: DishData
var multiplier: float = 1.0


func _init(p_dish: DishData = null, p_multiplier: float = 1.0) -> void:
	dish = p_dish
	multiplier = p_multiplier


## Draws the plate centred at `at` on `canvas`.
func draw_at(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_circle(at, 5.0, Color.WHITE)
	canvas.draw_circle(at + Vector2(0, -1), 3.2, dish.color)
