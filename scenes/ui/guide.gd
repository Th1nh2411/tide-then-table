class_name Guide
extends CanvasLayer
## First-time pointers (any day, not just day 1): the first time something
## new shows up, a pulsing ring + bouncing arrow sits on it with one short
## line ("E: rót bia"). Gone once the player does it (or after a while); each
## is shown once (story flag "tip_<id>", saved). One at a time, in the order
## the rules were added. Subclasses add rules in `_add_rules()`.
## Hidden while the game is paused, except rules made for paused screens
## (the hold window). Text stays short: the full guide is HelpPanel.

const FLAG_PREFIX := "tip_"

class Rule:
	extends RefCounted
	var id: String
	var text: String
	var active: Callable  # () -> bool: show now
	var target: Callable  # () -> Vector2: screen position (canvas coords)
	var done: Callable  # () -> bool: the player did it (empty = time out only)
	var while_paused: bool = false

@export var color: Color = Color(1.0, 0.85, 0.3)
## Seconds a pointer stays at most; one that disappears after this long
## counts as seen too (no nagging).
@export var max_seconds: float = 14.0
@export var seen_after_seconds: float = 4.0
@export var font_size: int = 9

var rules: Array[Rule] = []

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
	var at: Vector2 = _current.target.call()
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	_canvas.draw_arc(at, 10.0 + pulse * 3.0, 0.0, TAU, 24, Color(color, 0.5 + 0.5 * pulse), 2.0)
	var tip := at + Vector2(0, -14 - absf(sin(_time * 5.0)) * 5.0)
	_canvas.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-6, -8), tip + Vector2(6, -8)]), color)
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(_current.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box := Rect2(tip + Vector2(-size.x * 0.5 - 4, -22 - size.y * 0.5), size + Vector2(8, 6))
	# Keep the label on screen.
	var screen := _canvas.get_viewport_rect().size
	box.position = box.position.clamp(Vector2(2, 2), screen - box.size - Vector2(2, 2))
	_canvas.draw_rect(box, Color(0.08, 0.08, 0.1, 0.9))
	_canvas.draw_rect(box, color, false, 1.0)
	_canvas.draw_string(font, box.position + Vector2(4, size.y), _current.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size, Color.WHITE)


## Screen position of a world node (works with or without a camera).
static func screen_of(node: CanvasItem, offset: Vector2 = Vector2.ZERO) -> Vector2:
	return node.get_global_transform_with_canvas() * offset


## Screen position of a world rect's top centre, drawn by `node`'s canvas.
static func screen_of_rect(node: CanvasItem, rect: Rect2) -> Vector2:
	return node.get_global_transform_with_canvas() * Vector2(rect.get_center().x, rect.position.y)


## Centre of a Control on screen.
static func control_center(control: Control) -> Vector2:
	return control.get_global_rect().get_center()
