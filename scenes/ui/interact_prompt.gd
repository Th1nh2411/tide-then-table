class_name InteractPrompt
extends Control
## The one interaction prompt of the horror build: no box, small, dim
## off-white handwriting just under the crosshair, the key as a tiny glyph in
## a thin border + one lowercase verb ("[E] đọc"). Fades in when something
## is in reach, fades out when not; a faint flicker and a few grain specks
## keep it from looking like game UI. `steady` = no fade / flicker (the key
## list in Cài đặt), sized to its text and drawn at its own top-left.
## Hidden while the tree is paused (menus, papers, the notebook).

const HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const INK := Color(0.86, 0.83, 0.76)
const FADE_IN := 3.0  # alpha per second
const FADE_OUT := 6.0

@export var color: Color = INK
@export var peak_alpha: float = 0.72
@export var verb_size: int = 12
@export var key_size: int = 9
## Screen point as a fraction of the rect + pixels (just under the crosshair).
@export var anchor_point: Vector2 = Vector2(0.5, 0.5)
@export var offset_px: Vector2 = Vector2(0, 26)
@export var steady: bool = false
## A faint dark copy under the words (off on light pages).
@export var shadow: bool = true

## What is asked for now; "" = nothing (the last words fade out).
var verb := ""
var key := ""
var _drawn_verb := ""
var _drawn_key := ""
var _alpha := 0.0
var _clock := 0.0
var _dip := 0.0  # seconds left of a flicker dip
var _next_dip := 2.5
var _specks := PackedVector2Array()
var _speck_clock := 0.0
var _rng := RandomNumberGenerator.new()


func _init(verb_: String = "", key_: String = "E", steady_: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	steady = steady_
	if steady:
		set_text(verb_, key_)


func _ready() -> void:
	if not steady:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		process_mode = Node.PROCESS_MODE_ALWAYS  # fades out under a pause / a paper
	_rng.randomize()


## Shows `verb` with `key` (fades in); "" hides it (fades out).
func set_text(verb_: String, key_: String = "E") -> void:
	if verb_ == "":
		verb = ""
		key = ""
		return
	_apply(verb_, key_)


## Only the key glyph ("[phím bất kỳ]").
func show_key(key_: String) -> void:
	_apply("", key_)


func _apply(verb_: String, key_: String) -> void:
	if key_ == "" or (verb_ == verb and key_ == key):
		return
	verb = verb_
	key = key_
	_drawn_verb = verb_
	_drawn_key = key_
	if steady:
		_alpha = 1.0
		custom_minimum_size = _measure() + Vector2(2, 2)
	queue_redraw()


func clear() -> void:
	set_text("")


## True once it is readable (tests / bots).
func shown() -> bool:
	return key != "" and _alpha > 0.3


func _process(delta: float) -> void:
	if steady:
		return
	_clock += delta
	var target := 1.0 if key != "" and not get_tree().paused else 0.0
	var was := _alpha
	_alpha = move_toward(_alpha, target, delta * (FADE_IN if target > _alpha else FADE_OUT))
	if was > 0.0 and _alpha <= 0.0:
		queue_redraw()  # one last empty draw, or the faint last frame stays on screen
	_next_dip -= delta
	if _next_dip <= 0.0:
		_dip = _rng.randf_range(0.04, 0.09)
		_next_dip = _rng.randf_range(1.8, 5.0)
	_dip = maxf(_dip - delta, 0.0)
	_speck_clock -= delta
	if _speck_clock <= 0.0:
		_speck_clock = 0.09
		_roll_specks()
	if _alpha > 0.0 or key != "":
		queue_redraw()


func _roll_specks() -> void:
	_specks.clear()
	var area := _measure()
	for i in range(7):
		_specks.append(Vector2(_rng.randf() * area.x, _rng.randf() * area.y).floor())


## Key glyph box + gap + verb.
func _measure() -> Vector2:
	var key_w := HAND.get_string_size(_drawn_key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x + 8.0
	var verb_w := HAND.get_string_size(_drawn_verb, HORIZONTAL_ALIGNMENT_LEFT, -1, verb_size).x if _drawn_verb != "" else 0.0
	return Vector2(key_w + (5.0 + verb_w if verb_w > 0.0 else 0.0), float(verb_size) + 4.0)


func _draw() -> void:
	if _alpha <= 0.0 or _drawn_key == "":
		return
	var flicker := 1.0 if steady else (0.45 if _dip > 0.0 else 0.93 + 0.07 * sin(_clock * 23.0) * sin(_clock * 7.1))
	var a := _alpha * peak_alpha * flicker
	var area := _measure()
	var origin := Vector2.ZERO
	if not steady:
		origin = (size * anchor_point + offset_px - Vector2(area.x * 0.5, 0)).round()
	var ink := Color(color, a)
	var shade := Color(0, 0, 0, a * 0.55 if shadow else 0.0)
	# Key glyph: thin border, the letters' x-height centred in it.
	var key_w := HAND.get_string_size(_drawn_key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
	var box_h := float(key_size) + 4.0
	var box := Rect2((origin + Vector2(0, (area.y - box_h) * 0.5 + 1.0)).round(), Vector2(roundf(key_w + 8.0), box_h))
	if shadow:
		draw_rect(Rect2(box.position + Vector2.ONE, box.size), shade, false, 1.0)
	draw_rect(box, Color(color, a * 0.6), false, 1.0)
	var key_at := (box.position + Vector2(4.0, (box_h + float(key_size) * 0.62) * 0.5)).round()
	draw_string(HAND, key_at, _drawn_key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size, Color(color, a * 0.85))
	if _drawn_verb != "":
		var verb_at := Vector2(box.end.x + 5.0, box.position.y + (box_h + float(verb_size) * 0.62) * 0.5).round()
		if shadow:
			draw_string(HAND, verb_at + Vector2.ONE, _drawn_verb, HORIZONTAL_ALIGNMENT_LEFT, -1, verb_size, shade)
		draw_string(HAND, verb_at, _drawn_verb, HORIZONTAL_ALIGNMENT_LEFT, -1, verb_size, ink)
	if steady:
		return
	# PS1-ish grain: a few specks of the ink colour over the words.
	for speck in _specks:
		draw_rect(Rect2(origin + speck, Vector2.ONE), Color(color, a * 0.35))
