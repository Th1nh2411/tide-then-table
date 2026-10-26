class_name CutsceneActor
extends Node2D
## A character placed by a cutscene (placeholder drawing by `kind`: "rin",
## "bao", "vy", "co_nam" (the grocer), "guest" (a customer), "cat", "crate",
## "rin_bed" = Rin lying under a blanket, phone lit, "glow" = the strange
## light in the fog, over-bright so it shows through the night tint). Walks with a small bob, faces left/right and shows emote
## bubbles (! ? ... heart note) over its head. Runs while the tree is paused.

@export var kind: String = "rin"
## Drawn art (Art: "characters/<kind>", "sea/rin_bed"...) size factor; the
## placeholder ignores it.
@export var art_scale: float = 1.0
## Restaurant actors join its Y-sort layer instead of forcing foreground Z.
var y_sorted: bool = false

## Scene speed for every actor (CutsceneEffects.slow): bobbing, glows, emotes.
static var speed: float = 1.0

var _facing: float = 1.0
var _walking: bool = false
var _time: float = 0.0
var _emote: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 0 if y_sorted else 5


func face(direction: String) -> void:
	_facing = -1.0 if direction == "left" else 1.0


## Walks to `target` in `seconds` (await it).
func walk_to(target: Vector2, seconds: float) -> void:
	await walk_path([target], seconds)


## Walks a collision-safe polyline in the same total time as move_to.
func walk_path(points: Array[Vector2], seconds: float) -> void:
	if points.is_empty():
		return
	var total_distance := 0.0
	var previous := position
	for point in points:
		total_distance += previous.distance_to(point)
		previous = point
	if total_distance <= 0.01:
		position = points[-1]
		return
	_walking = true
	for target in points:
		var distance := position.distance_to(target)
		if distance <= 0.01:
			continue
		if target.x != position.x:
			_facing = signf(target.x - position.x)
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(self, "position", target, maxf(seconds * distance / total_distance, 0.01))
		await tween.finished
	_walking = false

## Shows an emote bubble for `seconds`.
func emote(kind_name: String, seconds: float) -> void:
	_emote = kind_name
	await get_tree().create_timer(seconds, true).timeout
	if _emote == kind_name:
		_emote = ""


func _process(delta: float) -> void:
	_time += delta * speed
	queue_redraw()


func _draw() -> void:
	var bob := absf(sin(_time * 10.0)) * 1.5 if _walking else 0.0
	if _draw_art():
		draw_set_transform(Vector2.ZERO)
		if _emote:
			_draw_emote()
		return
	draw_set_transform(Vector2(0, -bob), 0.0, Vector2(_facing, 1.0))
	match kind:
		"rin":
			_draw_person(Color(0.2, 0.45, 0.8))
		"bao":
			_draw_person(Color(0.85, 0.5, 0.2))
		"vy":
			_draw_person(Color(0.9, 0.45, 0.55), Color(0.12, 0.1, 0.1))
		"co_nam":
			_draw_person(Color(0.35, 0.6, 0.4), Color(0.55, 0.55, 0.55))
		"guest":
			_draw_person(Color(0.5, 0.5, 0.6))
		"cat":
			_draw_cat()
		"crate":
			_draw_crate()
		"rin_bed":
			_draw_lying()
		"rin_faint":
			_draw_fainted()
		"glow":
			_draw_glow()
	draw_set_transform(Vector2.ZERO)
	if _emote:
		_draw_emote()


## The kind's PNG if there is one: people use their restaurant sheet, the
## cat its sheet, others one picture ("characters/crate", "characters/rin_bed",
## "characters/glow"). Sheets animate the walk themselves, so no bob here.
func _draw_art() -> bool:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * art_scale)
	var facing := Vector2i(int(_facing), 0)
	match kind:
		"rin", "bao", "vy", "co_nam", "guest":
			return Art.draw_person(self, "characters/" + kind, facing, _time, _walking, false, _time)
		"cat":
			return Art.draw_sheet(self, "characters/cat", Rect2(-12, -24, 24, 24), 8, 1 if _walking else 0,
				_time, 6.0 if _walking else 3.0, _facing < 0.0)
		"crate":
			return Art.draw(self, "characters/crate", Rect2(-10, -14, 20, 14))
		"rin_bed":
			return Art.draw(self, "characters/rin_bed", Rect2(-16, -16, 32, 16))
		"rin_faint":
			return Art.draw(self, "characters/rin_faint", Rect2(-16, -10, 32, 10))
		"glow":
			return Art.draw_sheet(self, "characters/glow", Rect2(-40, -40, 80, 80), 4, 0, _time, 3.0)
	return false


## `long_hair`: transparent = short hair; else hair down the back (women).
func _draw_person(shirt: Color, long_hair: Color = Color.TRANSPARENT) -> void:
	if long_hair.a > 0.0:
		draw_rect(Rect2(-5, -21, 6, 11), long_hair)
	draw_rect(Rect2(-4, -14, 8, 10), shirt)
	draw_rect(Rect2(-3, -4, 2, 4), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(1, -4, 2, 4), Color(0.25, 0.2, 0.15))
	draw_circle(Vector2(0, -18), 4.0, Color(0.95, 0.8, 0.65))
	if long_hair.a > 0.0:
		draw_rect(Rect2(-4, -23, 8, 3), long_hair)
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


## Rin in bed, scrolling his phone (head on the left, blanket over him).
func _draw_lying() -> void:
	draw_circle(Vector2(-11, -5), 4.0, Color(0.95, 0.8, 0.65))
	draw_rect(Rect2(-14, -9, 6, 3), Color(0.15, 0.12, 0.1))  # hair
	draw_rect(Rect2(-7, -8, 20, 7), Color(0.55, 0.6, 0.75))  # blanket
	draw_rect(Rect2(-7, -8, 20, 2), Color(0.65, 0.7, 0.85))
	var glow := 0.7 + 0.3 * sin(_time * 5.0)
	draw_rect(Rect2(-8, -11, 3, 4), Color(0.6, 0.85, 1.0, glow))  # phone
	draw_circle(Vector2(-10, -6), 6.0, Color(0.6, 0.85, 1.0, 0.12 * glow))


## Rin passed out on his side, the mark on his hand glowing.
func _draw_fainted() -> void:
	draw_rect(Rect2(-9, -6, 14, 5), Color(0.2, 0.45, 0.8))  # body
	draw_rect(Rect2(5, -5, 6, 3), Color(0.25, 0.2, 0.15))  # legs
	draw_circle(Vector2(-11, -4), 3.5, Color(0.95, 0.8, 0.65))
	draw_circle(Vector2(-3, -1), 1.6, Color(0.5, 3.0, 2.6, 0.5 + 0.4 * sin(_time * 2.0)))  # the hand


## A slow "breathing" glow (colours above 1 survive the night tint).
func _draw_glow() -> void:
	var breath := 0.5 + 0.5 * sin(_time * 1.6)
	for i in 4:
		var radius := 40.0 - i * 9.0 + breath * 6.0
		draw_circle(Vector2.ZERO, radius, Color(0.3, 3.0, 2.6, 0.08 + 0.06 * i + 0.08 * breath))


func _draw_crate() -> void:
	draw_rect(Rect2(-9, -8, 18, 8), Color(0.55, 0.4, 0.22))
	var colors: Array[Color] = [Color(0.45, 0.6, 0.75), Color(1.0, 0.55, 0.45), Color(0.85, 0.8, 0.95)]
	for i in 3:
		draw_rect(Rect2(-7 + i * 5, -11, 4, 3), colors[i])


func _draw_emote() -> void:
	var at := Vector2(-6, -26 if kind in ["cat", "crate"] else -36)
	if kind == "rin_bed":
		at = Vector2(-17, -24)
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
