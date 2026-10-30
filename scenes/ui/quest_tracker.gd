class_name QuestTracker
extends CanvasLayer
## Quest note (sea and restaurant), from QuestLog: a small paper note pinned
## under the top HUD, a bit crooked. Not hovered: faded, one short line (the
## next main step) + a fish sticker with how many fish orders. Hovered: clear,
## the whole main quest (done steps ticked) and every order. Never takes
## clicks (the hover is checked by hand), so the game under it works.
## `hidden_when` hides it while a full panel owns the screen.

@export var catalog: FishCatalog
@export var origin: Vector2 = Vector2(6, 22)
@export var width: float = 190.0
## Width while folded (one short line).
@export var folded_width: float = 150.0
@export var faded_alpha: float = 0.85
@export var fade_speed: float = 8.0
@export var refresh_seconds: float = 0.5
@export var font_size: int = 8

const INK := Color("090a14")
const RED := Color("a53030")
const GREEN := Color("25562e")
const SEA := Color("253a5e")

## () -> bool: hide now (menu planning, market, receipt...).
var hidden_when: Callable
var _panel: PanelContainer
var _box: VBoxContainer
var _refresh_left: float = 0.0
var _last: String = ""
var _hovered: bool = false


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.theme_type_variation = &"PaperPanel"
	_panel.position = origin
	_panel.custom_minimum_size = Vector2.ZERO
	UiFx.tilt(_panel, -0.8)
	add_child(_panel)
	var note := _panel.get_theme_stylebox("panel").duplicate() as StyleBox
	note.content_margin_left = 6
	note.content_margin_top = 5
	note.content_margin_right = 8
	note.content_margin_bottom = 7
	_panel.add_theme_stylebox_override("panel", note)
	_box = VBoxContainer.new()
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 1)
	_panel.add_child(_box)
	_panel.modulate.a = faded_alpha
	_panel.draw.connect(func() -> void:  # red push pin on the top edge
		_panel.draw_rect(Rect2(10, -2, 5, 5), INK)
		_panel.draw_rect(Rect2(11, -1, 3, 3), Color("cf573c")))
	_rebuild()


func _process(delta: float) -> void:
	_panel.visible = not (hidden_when.is_valid() and hidden_when.call())
	var hovered := _panel.visible and _panel.get_global_rect().has_point(_panel.get_global_mouse_position())
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
		_add_label(_next_step(main), INK, "anchor")
		if not sides.is_empty():
			_add_label("%d" % sides.size(), SEA, "fish")
		_panel.reset_size()
		return
	_add_label(str(main["title"]), RED, "anchor", &"HeadingLabel")
	for step: Dictionary in main["steps"]:
		var done: bool = step["done"]
		_add_label(str(step["text"]), GREEN if done else INK, "check" if done else "")
	if not sides.is_empty():
		for line in sides:
			_add_label(line, SEA, "fish")
	_panel.reset_size()


func _next_step(main: Dictionary) -> String:
	for step: Dictionary in main["steps"]:
		if not step["done"]:
			return str(step["text"])
	return str(main["title"])


func _add_label(text: String, color: Color, icon: String = "", variation: StringName = &"InkLabel") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(row)
	var mark: Control = UiIcons.make(icon, 8, RED if icon == "anchor" else color) if icon != "" else Control.new()
	mark.custom_minimum_size = Vector2(8, 8)
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(mark)
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _hovered or text.length() > 28:  # one short line folded: fit the text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2((width if _hovered else folded_width) - 26, 0)
	label.add_theme_font_size_override("font_size", font_size + (1 if variation == &"HeadingLabel" else 0))
	label.add_theme_color_override("font_color", color)
	row.add_child(label)
