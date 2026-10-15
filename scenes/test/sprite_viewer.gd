extends Node2D
## Look at person sheets in motion (F6). Not a PASS/FAIL test.
## Each row: one sheet; columns: down, up, left, right, busy (if the sheet has it).
## Space toggles walking, +/- zoom.

@export var sprites: PackedStringArray = ["characters/rin", "characters/bao", "characters/vy"]
@export var zoom := 3.0

const FACINGS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
const CELL := Vector2(24, 36)

var _time := 0.0
var _walking := true


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_SPACE:
			_walking = not _walking
		KEY_EQUAL, KEY_KP_ADD:
			zoom = minf(zoom + 1.0, 6.0)
		KEY_MINUS, KEY_KP_SUBTRACT:
			zoom = maxf(zoom - 1.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("577277"))
	for i in sprites.size():
		for j in FACINGS.size() + 1:
			var busy := j == FACINGS.size()
			var facing: Vector2i = Vector2i.DOWN if busy else FACINGS[j]
			var feet := (Vector2(j, i) * CELL + Vector2(12, 34)) * zoom + Vector2(8, 4)
			draw_set_transform(feet, 0.0, Vector2(zoom, zoom))
			Art.draw_person(self, sprites[i], facing, _time, _walking and not busy, busy, _time)
	draw_set_transform(Vector2.ZERO)
