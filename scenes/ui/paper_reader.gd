class_name PaperReader
extends CanvasLayer
## Reading something up close (horror build): the morning paper, a letter from
## a bottle, a diary page. The paper art (assets/textures/horror/) fills most of
## the screen with the words written on it; the game pauses while it is open.
## E / Esc / click puts it down. Usage: `await PaperReader.read(owner, kind, title, body)`;
## `aside` is a short boxed line printed lower on the page (kinds with "aside_at").

signal closed

const KINDS := {
	"newspaper": {"texture": "newspaper_front", "title_at": Rect2(0.07, 0.03, 0.66, 0.06),
		"body_at": Rect2(0.065, 0.105, 0.87, 0.125), "ink": Color("1d1a17"), "size": 10,
		"aside_at": Rect2(0.06, 0.745, 0.88, 0.13), "aside_ink": Color("5a1c18")},
	"letter": {"texture": "paper_letter_old", "title_at": Rect2(0.14, 0.12, 0.72, 0.08),
		"body_at": Rect2(0.14, 0.24, 0.72, 0.6), "ink": Color("2b3550"), "size": 13},
	"diary": {"texture": "paper_diary_page", "title_at": Rect2(0.16, 0.1, 0.7, 0.06),
		"body_at": Rect2(0.16, 0.2, 0.7, 0.6), "ink": Color("27324a"), "size": 12},
	# A handwritten note on the same page, more lines in smaller writing.
	"note": {"texture": "paper_diary_page", "title_at": Rect2(0.13, 0.07, 0.75, 0.06),
		"body_at": Rect2(0.13, 0.16, 0.76, 0.78), "ink": Color("27324a"), "size": 10},
}

var _was_paused := false


static func read(owner: Node, kind: String, title: String, body: String, aside: String = "") -> void:
	var reader := PaperReader.new()
	owner.add_child(reader)
	reader._open(kind, title, body, aside)
	await reader.closed


func _open(kind: String, title: String, body: String, aside: String = "") -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var spec: Dictionary = KINDS.get(kind, KINDS["letter"])
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var texture := load(HorrorMaterials.DIR + str(spec["texture"]) + ".png") as Texture2D
	var view := get_viewport().get_visible_rect().size
	var height := view.y * 0.9
	var width := height * texture.get_width() / float(texture.get_height())
	var paper := TextureRect.new()
	paper.texture = texture
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.size = Vector2(width, height)
	paper.position = (view - paper.size) * 0.5
	add_child(paper)
	_words(paper, title, spec["title_at"], spec["ink"], int(spec["size"]) + 3, true)
	_words(paper, body, spec["body_at"], spec["ink"], int(spec["size"]), false)
	if aside != "" and spec.has("aside_at"):
		var area: Rect2 = spec["aside_at"]
		var box := ColorRect.new()
		box.color = Color(0.86, 0.82, 0.72, 0.94)
		box.position = area.position * paper.size
		box.size = area.size * paper.size
		paper.add_child(box)
		var inner := Rect2(area.position + Vector2(0.02, 0.012), area.size - Vector2(0.04, 0.024))
		_words(paper, aside, inner, spec["aside_ink"], int(spec["size"]), false)
	_was_paused = get_tree().paused
	get_tree().paused = true
	Sfx.play("flip")


func _words(paper: Control, text: String, area: Rect2, ink: Color, font_size: int, bold: bool) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", ink)
	label.add_theme_font_size_override("font_size", font_size)
	if bold:
		label.theme_type_variation = &"TitleLabel"
		label.add_theme_color_override("font_color", ink)
	label.position = area.position * paper.size
	label.size = area.size * paper.size
	paper.add_child(label)


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
