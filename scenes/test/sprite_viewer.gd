extends Node2D
## Look at person sheets in motion (F6). Not a PASS/FAIL test.
## Each row: one sheet; columns: walking down, up, left, right, busy (if the
## sheet has it), then standing down, up, left (idle sheet: breathing, blinking).
## Space stops / starts the walking columns, +/- requests zoom. The preview keeps
## integer scaling and automatically shrinks when needed so every sheet stays visible.

@export var sprites: PackedStringArray = ["characters/rin", "characters/bao", "characters/vy", "characters/guest"]
@export var zoom := 3.0

const FACINGS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
const CELL := Vector2(24, 36)
const LABEL_WIDTH := 86.0
const HEADER_HEIGHT := 30.0
const FOOTER_HEIGHT := 22.0
const PADDING := 8.0

const COLUMN_LABELS: PackedStringArray = [
	"DOWN", "UP", "LEFT", "RIGHT", "BUSY", "IDLE D", "IDLE U", "IDLE L", "WAIT", "EAT",
]

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
	var viewport_size := get_viewport_rect().size
	var preview_zoom := _fitted_zoom(viewport_size)
	var origin := Vector2(PADDING + LABEL_WIDTH, HEADER_HEIGHT)
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("577277"))
	draw_string(font, Vector2(PADDING, 18), "SPACE: pause   +/-: zoom   %d×" % int(preview_zoom), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("e8f0df"))
	for j in COLUMN_LABELS.size():
		var header_x := origin.x + (j * CELL.x + CELL.x * 0.5) * preview_zoom
		draw_string(font, Vector2(header_x - CELL.x * preview_zoom * 0.5, 27), COLUMN_LABELS[j], HORIZONTAL_ALIGNMENT_CENTER, CELL.x * preview_zoom, 8, Color("d2dfd0"))
	for i in sprites.size():
		var label_y := origin.y + (i * CELL.y + 20.0) * preview_zoom
		draw_string(font, Vector2(PADDING, label_y), sprites[i].get_file().to_upper(), HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH - PADDING, 12, Color.WHITE)
		for j in COLUMN_LABELS.size():
			var feet := (Vector2(j, i) * CELL + Vector2(12, 34)) * preview_zoom + origin
			draw_set_transform(feet, 0.0, Vector2(preview_zoom, preview_zoom))
			if j >= FACINGS.size() + 4:  # optional one-row guest waiting / eating sheets
				var seated := sprites[i] + ("_wait" if j == FACINGS.size() + 4 else "_eat")
				if Art.has(seated):
					Art.draw_frame(self, seated, 4, 1, int(_time * 4.0) % 4, 0,
						Rect2(-8, -32, 16, 32))
				continue
			var busy := j == FACINGS.size()
			var standing := j > FACINGS.size()
			var facing: Vector2i = FACINGS[j - FACINGS.size() - 1] if standing \
				else Vector2i.DOWN if busy else FACINGS[j]
			Art.draw_person(self, sprites[i], facing, _time, _walking and not busy and not standing, busy, _time)
	draw_set_transform(Vector2.ZERO)
	draw_string(font, Vector2(PADDING, viewport_size.y - 6), "Requested zoom: %d× (auto-fit may use less)" % int(zoom), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("c3d3c4"))


func _fitted_zoom(viewport_size: Vector2) -> float:
	var column_count := COLUMN_LABELS.size()
	var content_size := Vector2(column_count * CELL.x, sprites.size() * CELL.y)
	var available := viewport_size - Vector2(LABEL_WIDTH + PADDING * 2.0, HEADER_HEIGHT + FOOTER_HEIGHT + PADDING)
	var fit := floorf(minf(available.x / content_size.x, available.y / content_size.y))
	return clampf(minf(zoom, fit), 1.0, 6.0)
