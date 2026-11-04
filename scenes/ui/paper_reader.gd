class_name PaperReader
extends CanvasLayer
## Reading something up close (horror build): the morning paper, a letter from
## a bottle, a diary page, the kiêng note. The paper art (assets/textures/horror/)
## fills most of the screen; PaperLayout fits the words onto it with real
## fonts (newsprint serif, handwriting on the ruled lines). The game pauses
## while it is open. E / Esc / click puts it down.
## Usage: `await PaperReader.read(owner, kind, title, body, aside)`; `aside` is
## a short pasted-on note lower on the newspaper.

signal closed

var _was_paused := false
var _layout: Dictionary = {}
var _ink: Control
## Pen strokes drawn under the words: point pairs in paper fractions (a sketch map).
var strokes := PackedVector2Array()


static func read(owner: Node, kind: String, title: String, body: String, aside: String = "") -> void:
	var reader := PaperReader.new()
	owner.add_child(reader)
	reader._open(kind, title, body, aside)
	await reader.closed


## The same, with a hand-drawn sketch (`strokes`: line segments as point pairs, paper fractions).
static func read_sketch(owner: Node, kind: String, title: String, body: String, strokes_: PackedVector2Array) -> void:
	var reader := PaperReader.new()
	reader.strokes = strokes_
	owner.add_child(reader)
	reader._open(kind, title, body)
	await reader.closed


func _open(kind: String, title: String, body: String, aside: String = "") -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var view := get_viewport().get_visible_rect().size
	var paper := TextureRect.new()
	paper.texture = load(HorrorMaterials.DIR + str(PaperLayout.spec(kind)["texture"]) + ".png") as Texture2D
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.size = PaperLayout.paper_size(kind, view)
	paper.position = ((view - paper.size) * 0.5).round()
	add_child(paper)
	_layout = PaperLayout.layout(kind, title, body, aside, paper.size)
	_ink = Control.new()
	_ink.size = paper.size
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.draw.connect(_draw_ink)
	paper.add_child(_ink)
	_was_paused = get_tree().paused
	get_tree().paused = true
	Sfx.play("flip")


func _draw_ink() -> void:
	for i in range(0, strokes.size() - 1, 2):
		_ink.draw_line(strokes[i] * _ink.size, strokes[i + 1] * _ink.size, PaperLayout.HAND_INK, maxf(1.0, _ink.size.x * 0.004))
	for paste: Dictionary in _layout.get("boxes", []):
		var rect: Rect2 = paste["rect"]
		_ink.draw_rect(rect, paste["color"])
		_ink.draw_rect(rect, Color(PaperLayout.PRINT_INK, 0.5), false, 1.0)
	for item: Dictionary in _layout.get("items", []):
		var font: Font = item["font"]
		var pos: Vector2 = item["pos"]
		font.draw_string(_ink.get_canvas_item(), pos, str(item["text"]), item["align"],
			float(item["width"]), int(item["size"]), item["color"])


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	var click := event as InputEventMouseButton
	var done := (key and key.pressed and not key.echo and key.physical_keycode in [KEY_E, KEY_ESCAPE, KEY_SPACE]) \
		or (click and click.pressed)
	if not done:
		return
	get_viewport().set_input_as_handled()
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()
