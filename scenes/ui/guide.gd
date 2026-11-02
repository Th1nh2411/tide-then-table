class_name Guide
extends CanvasLayer
## First-time pointers (any day, not just day 1): the first time something
## new shows up, a pulsing ring + bouncing arrow sits on it with one short
## line ("E: rót bia"). Gone once the player does it (or after a while); each
## is shown once (story flag "tip_<id>", saved). One at a time, in the order
## the rules were added. Subclasses add rules in `_add_rules()`.
## Hidden while the game is paused, except rules made for paused screens
## (the hold window). Text stays short: the key list lives in Cài đặt (SettingsPanel).
## Look: a stepped pixel ring (ink + gold) on the target, a red arrow, and
## the words on a small yellow paper tag ("TagPanel") pinned with a push
## pin (stickers/pin.png), bobbing gently.

const FLAG_PREFIX := "tip_"

class Rule:
	extends RefCounted
	var id: String
	var text: String
	var active: Callable  # () -> bool: show now
	var target: Callable  # () -> Vector2: screen position (canvas coords)
	var done: Callable  # () -> bool: the player did it (empty = time out only)
	var while_paused: bool = false

@export var color: Color = Color("f2d98a")
@export var arrow_color: Color = Color("e0302b")
@export var ink_color: Color = Color("090a14")
## Seconds a pointer stays at most; one that disappears after this long
## counts as seen too (no nagging).
@export var max_seconds: float = 14.0
@export var seen_after_seconds: float = 4.0
@export var font_size: int = 9

var rules: Array[Rule] = []
## () -> bool: a minigame / panel covers the screen: hide, wait.
var blocked: Callable

var _current: Rule
var _shown: float = 0.0
var _time: float = 0.0
var _canvas: Control


## True only the first time it's asked for `id` (marks it seen): for hints
## inside minigames.
static func once(id: String) -> bool:
	if GameState.story_flags.has(FLAG_PREFIX + id):
		return false
	GameState.set_flag(FLAG_PREFIX + id)
	return true


static func is_seen(id: String) -> bool:
	return GameState.story_flags.has(FLAG_PREFIX + id)


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_pointer)
	add_child(_canvas)
	_add_rules()


## A pointer is on screen right now.
func is_showing() -> bool:
	return _current != null


## Drop the rules (their lambdas keep scripts alive at exit otherwise).
func _exit_tree() -> void:
	rules.clear()
	_current = null


func _add_rules() -> void:
	pass


func add(id: String, text: String, active: Callable, target: Callable, done: Callable = Callable(),
		while_paused: bool = false) -> void:
	var rule := Rule.new()
	rule.id = id
	rule.text = text
	rule.active = active
	rule.target = target
	rule.done = done
	rule.while_paused = while_paused
	rules.append(rule)


func _process(delta: float) -> void:
	_time += delta
	if _current and _current.done.is_valid() and _current.done.call():
		_finish(true)
	if blocked.is_valid() and blocked.call():
		_canvas.visible = false
		return
	var paused := get_tree().paused
	if _current:
		_shown += delta
		if _current.done.is_valid() and _current.done.call():
			_finish(true)
		elif _shown >= max_seconds:
			_finish(true)
		elif not _current.active.call():
			_finish(_shown >= seen_after_seconds)
	if _current == null:
		for rule in rules:
			if (rule.while_paused or not paused) and not is_seen(rule.id) and rule.active.call():
				_current = rule
				_shown = 0.0
				Sfx.play("pop")
				break
	_canvas.visible = _current != null and (_current.while_paused or not paused)
	_canvas.queue_redraw()


func _finish(seen: bool) -> void:
	if seen:
		GameState.set_flag(FLAG_PREFIX + _current.id)
	_current = null


func _draw_pointer() -> void:
	if _current == null:
		return
	var at: Vector2 = (_current.target.call() as Vector2).round()
	# Ring: steps between two sizes (no smooth glow), ink under gold.
	var radius := 11.0 if fmod(_time, 0.9) < 0.45 else 13.0
	_canvas.draw_arc(at, radius, 0.0, TAU, 20, ink_color, 4.0, false)
	_canvas.draw_arc(at, radius, 0.0, TAU, 20, color, 2.0, false)
	var bob := roundf(absf(sin(_time * 4.0)) * 4.0)
	var tip := at + Vector2(0, -radius - 3.0 - bob)
	var arrow := PackedVector2Array([tip, tip + Vector2(-6, -8), tip + Vector2(6, -8)])
	var outline := PackedVector2Array([tip + Vector2(0, 2), tip + Vector2(-8, -9), tip + Vector2(8, -9)])
	_canvas.draw_colored_polygon(outline, ink_color)
	_canvas.draw_colored_polygon(arrow, arrow_color)
	# Words on a pinned paper tag, swaying a little.
	var font := _canvas.get_theme_font(&"font", &"BoldLabel")
	var size := font.get_string_size(_current.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box := Rect2((tip + Vector2(-size.x * 0.5 - 6, -16 - size.y - 4)).round(), (size + Vector2(12, 8)).round())
	var screen := _canvas.get_viewport_rect().size
	box.position = box.position.clamp(Vector2(4, 6), screen - box.size - Vector2(4, 4))
	var sway := sin(_time * 2.2) * 0.03
	_canvas.draw_set_transform(box.get_center(), sway)
	var local := Rect2(-box.size * 0.5, box.size)
	var tag := _canvas.get_theme_stylebox(&"panel", &"TagPanel")
	if tag:
		_canvas.draw_style_box(tag, local)
	else:
		_canvas.draw_rect(local, color)
	_canvas.draw_string(font, local.position + Vector2(6, 4 + size.y * 0.8), _current.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink_color)
	UiStickers.draw(_canvas, "pin", Vector2(0, local.position.y + 1))
	_canvas.draw_set_transform(Vector2.ZERO)


## Screen position of a world node (works with or without a camera).
static func screen_of(node: CanvasItem, offset: Vector2 = Vector2.ZERO) -> Vector2:
	return node.get_global_transform_with_canvas() * offset


## Screen position of a world rect's top centre, drawn by `node`'s canvas.
static func screen_of_rect(node: CanvasItem, rect: Rect2) -> Vector2:
	return node.get_global_transform_with_canvas() * Vector2(rect.get_center().x, rect.position.y)


## Centre of a Control on screen.
static func control_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()
