extends Node2D
## Side-by-side native-scale prototype: current 16x32 versus proposed 24x40.

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("172038"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(40, 42), "CURRENT 16x32", HORIZONTAL_ALIGNMENT_CENTER, 180, 15, Color.WHITE)
	draw_string(font, Vector2(330, 42), "PROTOTYPE 24x40", HORIZONTAL_ALIGNMENT_CENTER, 230, 15, Color.WHITE)
	var old_feet := Vector2(130, 200)
	var new_feet := Vector2(450, 200)
	draw_circle(old_feet + Vector2(0, 2), 7, Color(0, 0, 0, 0.35))
	draw_circle(new_feet + Vector2(0, 2), 10, Color(0, 0, 0, 0.35))
	draw_set_transform(old_feet, 0.0, Vector2(3, 3))
	Art.draw_person(self, "characters/rin", Vector2i.DOWN, _time, true, false, _time)
	draw_set_transform(new_feet, 0.0, Vector2(3, 3))
	Art.draw_frame(self, "characters/rin_24x40", 4, 3, Art.WALK_CYCLE[int(_time * 8.0) % 4], 0,
		Rect2(-12, -40, 24, 40))
	draw_set_transform(Vector2.ZERO)
	draw_string(font, Vector2(54, 270), "48x96 on screen", HORIZONTAL_ALIGNMENT_CENTER, 150, 12, Color("c7cfcc"))
	draw_string(font, Vector2(360, 270), "72x120 on screen", HORIZONTAL_ALIGNMENT_CENTER, 180, 12, Color("c7cfcc"))
