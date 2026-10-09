class_name QuestTracker
extends CanvasLayer
## Floating quest box (sea and restaurant), from QuestLog. Not hovered: faded,
## one short line (the next main step) + how many fish orders. Hovered:
## clear, the whole main quest (done steps ticked) and every order. Never
## takes clicks (the hover is checked by hand), so the game under it works.

@export var catalog: FishCatalog
@export var origin: Vector2 = Vector2(6, 22)
@export var width: float = 190.0
## Width while folded (one short line).
@export var folded_width: float = 150.0
@export var faded_alpha: float = 0.35
@export var fade_speed: float = 8.0
@export var refresh_seconds: float = 0.5
@export var font_size: int = 8

var _panel: PanelContainer
var _box: VBoxContainer
var _refresh_left: float = 0.0
var _last: String = ""
var _hovered: bool = false


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = origin
	_panel.custom_minimum_size = Vector2.ZERO
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.85)
	style.border_color = Color(1.0, 0.85, 0.3, 0.6)
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 1)
	_panel.add_child(_box)
	_panel.modulate.a = faded_alpha
	_rebuild()


func _process(delta: float) -> void:
	var hovered := _panel.get_global_rect().has_point(_panel.get_global_mouse_position())
	_panel.modulate.a = move_toward(_panel.modulate.a, 1.0 if hovered else faded_alpha, fade_speed * delta)
	_refresh_left -= delta
	if hovered != _hovered or _refresh_left <= 0.0:
		_hovered = hovered
		_refresh_left = refresh_seconds
		_rebuild()


func _rebuild() -> void:
	var main := QuestLog.main_quest()
	var sides := QuestLog.side_quests(catalog) if catalog else PackedStringArray()
	var key := str(main) + str(sides) + str(_hovered)
	if key == _last:
		return
	_last = key
	for child in _box.get_children():
		child.queue_free()
	if not _hovered:
		_add_label("> " + _next_step(main), Color(1.0, 0.85, 0.3))
		if not sides.is_empty():
			_add_label("+ %d đơn đặt cá" % sides.size(), Color(0.6, 0.85, 1.0))
		_panel.reset_size()
		return
	_add_label("NHIỆM VỤ CHÍNH: %s" % main["title"], Color(1.0, 0.85, 0.3))
	for step: Dictionary in main["steps"]:
		var done: bool = step["done"]
		_add_label(("  [x] " if done else "  [ ] ") + str(step["text"]),
			Color(0.6, 0.85, 0.6) if done else Color.WHITE)
	if not sides.is_empty():
		_add_label("NHIỆM VỤ PHỤ: đơn đặt cá", Color(0.6, 0.85, 1.0))
		for line in sides:
			_add_label("  " + line, Color.WHITE)
	_panel.reset_size()


func _next_step(main: Dictionary) -> String:
	for step: Dictionary in main["steps"]:
		if not step["done"]:
			return str(step["text"])
	return str(main["title"])


func _add_label(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2((width if _hovered else folded_width) - 8, 0)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_box.add_child(label)
