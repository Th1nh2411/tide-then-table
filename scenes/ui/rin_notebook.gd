class_name RinNotebook
extends CanvasLayer
## Rin's notebook (sổ tay), N anywhere he walks or rows (FirstPersonView3D
## opens it): the closed cover first, E / click opens it on a two-page spread
## of handwritten entries (NotebookPages: clues found at sea, the old folks'
## sayings after a wrong night). A / D (arrows) turn the pages; N / Esc
## closes. The game pauses while it is open.

signal closed

const COVER := "notebook_cover"
const PAGE := "notebook_page"
const HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const CLUES: LinesData = preload("res://data/story/clues.tres")
const NEWS: NewsData = preload("res://data/story/news.tres")
const FONT_SIZE := 11
## On the page art (fractions of its size): the label box on the cover, the
## writing area of each page, the first ruled line and the ruling.
const LABEL := Rect2(0.25, 0.246, 0.536, 0.197)
const LEFT_X := Vector2(0.095, 0.455)
const RIGHT_X := Vector2(0.55, 0.925)
const FIRST_RULE := 0.079
const RULE := 0.0297
const ROWS := 28
const PENCIL := Color("33394a")
const RED_PENCIL := Color("7a2a22")

var _was_paused := false
var _opened_frame := 0
var _book: TextureRect
var _ink: Control
var _cover_text: Control
var _pages: Array[Array] = []
var _spread := -1  # -1 = closed cover


## Opens the notebook over `owner` (does nothing if one is open already).
static func open(owner: Node) -> RinNotebook:
	if owner.get_node_or_null("RinNotebook"):
		return null
	var book := RinNotebook.new()
	book.name = "RinNotebook"
	owner.add_child(book)
	return book


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_frame = Engine.get_process_frames()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var view := get_viewport().get_visible_rect().size
	_book = TextureRect.new()
	_book.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_book.stretch_mode = TextureRect.STRETCH_SCALE
	_book.size = Vector2(view.y * 0.955 * 1024.0 / 1400.0, view.y * 0.955)
	_book.position = (view - _book.size) * 0.5
	add_child(_book)
	_cover_text = _make_cover_label()
	_book.add_child(_cover_text)
	_ink = Control.new()
	_ink.size = _book.size
	_ink.draw.connect(_draw_ink)
	_book.add_child(_ink)
	var width := (LEFT_X.y - LEFT_X.x) * _book.size.x
	var list := NotebookPages.entries(GameState.story_flags, CLUES.lines, NEWS.hint)
	_pages = NotebookPages.layout(list, width, ROWS, _measure)
	_show(-1)
	_was_paused = get_tree().paused
	get_tree().paused = true
	Sfx.play("flip")


func _measure(text: String) -> float:
	return HAND.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x


## "SỔ TAY" written by hand in the cover's blank label.
func _make_cover_label() -> Control:
	var box := VBoxContainer.new()
	box.position = LABEL.position * _book.size
	box.size = LABEL.size * _book.size
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -4)
	box.pivot_offset = box.size * 0.5
	box.rotation = deg_to_rad(-2.5)
	for pair: Array in [["SỔ TAY", 30], ["Rin", 15]]:
		var label := Label.new()
		label.text = str(pair[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", HAND)
		label.add_theme_font_size_override("font_size", int(pair[1]))
		label.add_theme_color_override("font_color", Color("1f2740"))
		box.add_child(label)
	return box


## -1 = the cover, else spread i (pages 2i, 2i + 1).
func _show(spread: int) -> void:
	_spread = clampi(spread, -1, NotebookPages.spread_count(_pages) - 1)
	var cover := _spread < 0
	_book.texture = load(HorrorMaterials.DIR + (COVER if cover else PAGE) + ".png") as Texture2D
	_cover_text.visible = cover
	_ink.visible = not cover
	_ink.queue_redraw()


func _draw_ink() -> void:
	if _spread < 0:
		return
	var many := _pages.size() > 2
	for side in 2:
		var index := _spread * 2 + side
		var span := LEFT_X if side == 0 else RIGHT_X
		var x := span.x * _ink.size.x
		if index < _pages.size():
			var rows: Array = _pages[index]
			for i in rows.size():
				var row: Dictionary = rows[i]
				_write_row(row, x, _rule_y(i), (span.y - span.x) * _ink.size.x)
		if many and index < _pages.size():
			var corner := x if side == 0 else span.y * _ink.size.x - 6.0
			_ink.draw_string(HAND, Vector2(corner, _rule_y(ROWS) + 2.0), str(index + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2, PENCIL)


func _rule_y(row: int) -> float:
	# Writing sits a hair above the ruled line.
	return (FIRST_RULE + RULE * float(row + 1)) * _ink.size.y - 1.5


func _write_row(row: Dictionary, x: float, y: float, width: float) -> void:
	var text := str(row.get("text", ""))
	if text == "":
		return
	if row.get("kind", "") == "date":
		_ink.draw_string(HAND, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, RED_PENCIL)
		var under := minf(_measure(text), width)
		_ink.draw_line(Vector2(x, y + 1.5), Vector2(x + under, y + 1.0), Color(RED_PENCIL, 0.7), 0.6)
	else:
		_ink.draw_string(HAND, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, PENCIL)


func _input(event: InputEvent) -> void:
	if Engine.get_process_frames() == _opened_frame or not event.is_pressed() or event.is_echo():
		return
	var click := event as InputEventMouseButton
	var key := event as InputEventKey
	if event.is_action("notebook") or event.is_action("pause"):
		close()
	elif _spread < 0:
		if (key and key.physical_keycode in [KEY_E, KEY_SPACE, KEY_D, KEY_RIGHT]) or (click and click.button_index == MOUSE_BUTTON_LEFT):
			_turn(0)
	elif event.is_action("turn_right") or (click and click.position.x > _book.get_global_rect().get_center().x):
		_turn(_spread + 1)
	elif event.is_action("turn_left") or click:
		_turn(_spread - 1)
	get_viewport().set_input_as_handled()


func _turn(spread: int) -> void:
	var before := _spread
	_show(spread)
	if _spread != before:
		Sfx.play("flip")


func close() -> void:
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()
