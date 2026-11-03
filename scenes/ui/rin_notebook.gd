class_name RinNotebook
extends CanvasLayer
## Rin's notebook (sổ tay), N anywhere he walks or rows (FirstPersonView3D
## opens it): the closed cover first, E / click opens it on a two-page spread
## of handwritten entries (NotebookPages: clues found at sea, the old folks'
## sayings after a wrong night). A / D (arrows) turn the pages; N / Esc
## closes. The game pauses while it is open.

signal closed

const COVER := "notebook_cover"
const HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const CLUES: LinesData = preload("res://data/story/clues.tres")
const NEWS: NewsData = preload("res://data/story/news.tres")
## The label box on the cover art (fractions of its size).
const LABEL := Rect2(0.25, 0.246, 0.536, 0.197)

var _was_paused := false
var _opened_frame := 0
var _cover: TextureRect
var _ink: NotebookSpread
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
	# Closed: the portrait cover. Open: a landscape spread over most of the screen.
	_cover = TextureRect.new()
	_cover.texture = load(HorrorMaterials.DIR + COVER + ".png") as Texture2D
	_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cover.stretch_mode = TextureRect.STRETCH_SCALE
	_cover.size = Vector2(view.y * 0.955 * 1024.0 / 1400.0, view.y * 0.955).round()
	_cover.position = ((view - _cover.size) * 0.5).round()
	add_child(_cover)
	_cover.add_child(_make_cover_label())
	_ink = NotebookSpread.new()
	_ink.size = spread_size(view)
	_ink.position = ((view - _ink.size) * 0.5).round()
	add_child(_ink)
	_pages = pages_for(_ink, GameState.story_flags)
	_ink.pages = _pages
	_show(-1)
	_was_paused = get_tree().paused
	get_tree().paused = true
	Sfx.play("flip")


## The open spread: landscape, most of the screen.
static func spread_size(view: Vector2) -> Vector2:
	return Vector2(minf(view.x * 0.93, view.y * 0.92 * 1.9), view.y * 0.92).round()


## Entries for `flags` wrapped to the spread's writing column, page by page.
static func pages_for(spread: NotebookSpread, flags: Dictionary) -> Array[Array]:
	var width := minf(spread.writing_span(0).y, spread.writing_span(1).y)
	var font_px := spread.font_size()
	var measure := func(text: String) -> float:
		return HAND.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x
	var list := NotebookPages.entries(flags, CLUES.lines, NEWS.hint)
	return NotebookPages.layout(list, width, NotebookSpread.rows(), measure)


## "SỔ TAY" written by hand in the cover's blank label.
func _make_cover_label() -> Control:
	var box := VBoxContainer.new()
	box.position = LABEL.position * _cover.size
	box.size = LABEL.size * _cover.size
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
	_cover.visible = _spread < 0
	_ink.visible = _spread >= 0
	_ink.spread = maxi(0, _spread)
	_ink.queue_redraw()


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
	elif event.is_action("turn_right") or (click and click.position.x > _ink.get_global_rect().get_center().x):
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
