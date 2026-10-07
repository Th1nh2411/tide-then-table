class_name CutsceneActor
extends Node2D
## A character placed by a cutscene (placeholder drawing by `kind`: "rin",
## "cat", "crate"). Walks with a small bob, faces left/right and shows emote
## bubbles (! ? ... heart note) over its head. Runs while the tree is paused.

@export var kind: String = "rin"

var _facing: float = 1.0
var _walking: bool = false
var _time: float = 0.0
var _emote: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 5


func face(direction: String) -> void:
	_facing = -1.0 if direction == "left" else 1.0


## Walks to `target` in `seconds` (await it).
func walk_to(target: Vector2, seconds: float) -> void:
	if target.x != position.x:
		_facing = signf(target.x - position.x)
	_walking = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "position", target, maxf(seconds, 0.01))
	await tween.finished
	_walking = false


## Shows an emote bubble for `seconds`.
func emote(kind_name: String, seconds: float) -> void:
	_emote = kind_name
	await get_tree().create_timer(seconds, true).timeout
	if _emote == kind_name:
		_emote = ""


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := absf(sin(_time * 10.0)) * 1.5 if _walking else 0.0
	draw_set_transform(Vector2(0, -bob), 0.0, Vector2(_facing, 1.0))
	match kind:
		"rin":
			_draw_person(Color(0.2, 0.45, 0.8))
		"cat":
			_draw_cat()
		"crate":
			_draw_crate()
	draw_set_transform(Vector2.ZERO)
	if _emote:
		_draw_emote()


func _draw_person(shirt: Color) -> void:
	draw_rect(Rect2(-4, -14, 8, 10), shirt)
	draw_rect(Rect2(-3, -4, 2, 4), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(1, -4, 2, 4), Color(0.25, 0.2, 0.15))
	draw_circle(Vector2(0, -18), 4.0, Color(0.95, 0.8, 0.65))
	draw_circle(Vector2(2, -19), 0.8, Color.BLACK)


## A fat orange cat, side view, facing right.
func _draw_cat() -> void:
	var fur := Color(0.95, 0.6, 0.25)
	draw_circle(Vector2(0, -5), 6.0, fur)  # round body
	draw_circle(Vector2(6, -9), 3.5, fur)  # head
	draw_colored_polygon(PackedVector2Array([Vector2(4, -12), Vector2(5, -15), Vector2(7, -12)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(7, -12), Vector2(9, -15), Vector2(9, -11)]), fur)
	draw_line(Vector2(-6, -6), Vector2(-10, -12 + sin(_time * 3.0) * 2.0), fur, 2.0)  # tail
	draw_circle(Vector2(7.5, -9.5), 0.8, Color(0.2, 0.9, 0.6))  # eye (a bit too bright...)


func _draw_crate() -> void:
	draw_rect(Rect2(-9, -8, 18, 8), Color(0.55, 0.4, 0.22))
	var colors: Array[Color] = [Color(0.45, 0.6, 0.75), Color(1.0, 0.55, 0.45), Color(0.85, 0.8, 0.95)]
	for i in 3:
		draw_rect(Rect2(-7 + i * 5, -11, 4, 3), colors[i])


func _draw_emote() -> void:
	var at := Vector2(-6, -36 if kind == "rin" else -26)
	draw_rect(Rect2(at, Vector2(12, 10)), Color(1, 1, 1, 0.95))
	draw_colored_polygon(PackedVector2Array([at + Vector2(3, 10), at + Vector2(7, 10), at + Vector2(4, 13)]),
		Color(1, 1, 1, 0.95))
	var center := at + Vector2(6, 5)
	match _emote:
		"heart":
			var red := Color(0.9, 0.2, 0.3)
			draw_circle(center + Vector2(-1.5, -1), 1.8, red)
			draw_circle(center + Vector2(1.5, -1), 1.8, red)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-3.2, -0.5), center + Vector2(3.2, -0.5),
				center + Vector2(0, 3)]), red)
		"note":
			draw_circle(center + Vector2(-1, 2), 1.5, Color.BLACK)
			draw_line(center + Vector2(0.4, 2), center + Vector2(0.4, -3), Color.BLACK, 1.0)
			draw_line(center + Vector2(0.4, -3), center + Vector2(2.5, -2), Color.BLACK, 1.0)
		_:
			draw_string(ThemeDB.fallback_font, at + Vector2(2, 9), _emote, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
				Color(0.15, 0.15, 0.15))
