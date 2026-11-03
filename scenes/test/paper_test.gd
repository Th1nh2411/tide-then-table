extends Node
## Standalone test for the papers (run with F6): every newspaper page (with
## and without each "Người già dặn" hint), every clue as a letter and as a
## diary page, the kiêng note and Rin's notebook with every entry fit their
## paper areas with the real fonts at 640x360 (the canvas_items base for
## 1280x720 / 1920x1080) and at those window sizes; the fonts have every glyph.

const CLUES: LinesData = preload("res://data/story/clues.tres")
const NEWS: NewsData = preload("res://data/story/news.tres")
const KIENG: NoteData = preload("res://data/story/kieng_note.tres")
const VIEWS: Array[Vector2] = [Vector2(640, 360), Vector2(1280, 720), Vector2(1920, 1080)]

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _hints() -> Array[String]:
	var out: Array[String] = [NEWS.calm_missed_hint]
	for omen in OmenPicker.CATALOG.omens:
		if omen.missed_hint != "" and not out.has(omen.missed_hint):
			out.append(omen.missed_hint)
	return out


func _run() -> void:
	SaveSystem.autosave_off = true
	_check("stretch keeps a 640x360 canvas", str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items"
		and int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 640)
	var printed := NEWS.title + " " + " ".join(NEWS.pages) + " " + " ".join(_hints())
	_check("newsprint serif has every glyph", PaperFit.missing_glyphs(PaperLayout.SERIF, printed) == ""
		and PaperFit.missing_glyphs(PaperLayout.SERIF_BOLD, printed) == "")
	var hand := " ".join(CLUES.lines) + KIENG.title + KIENG.body() + "SỔ TAY Rin 0123456789 " \
		+ NotebookPages.EMPTY + NotebookPages.ELDERS + " ".join(_hints())
	for day in 7:
		hand += LoopCalendar.date_text(day + 1)
	var lacking := PaperFit.missing_glyphs(PaperLayout.HAND, hand)
	_check("handwriting has every glyph" + ("" if lacking == "" else " (missing " + lacking + ")"), lacking == "")
	for view in VIEWS:
		_papers(view)
		_notebook(view)
	_check("box squeezes rather than clips", not bool(PaperFit.box(PaperLayout.SERIF, "chữ ".repeat(80),
		Vector2(60, 20), 12, 8)["fits"]))
	print("PAPER TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


func _papers(view: Vector2) -> void:
	var tag := " at %dx%d" % [view.x, view.y]
	var bad: Array[String] = []
	for page in NEWS.pages:
		_fits("newspaper", NEWS.title, page, "", view, bad)
		for hint in _hints():
			_fits("newspaper", NEWS.title, page, hint, view, bad)
	_check("every news page and hint fits" + tag, bad.is_empty())
	bad.clear()
	for clue in CLUES.lines:
		_fits("letter", "", clue, "", view, bad)
		_fits("diary", "", clue, "", view, bad)
	_check("every clue fits a letter and a diary page" + tag, bad.is_empty())
	bad.clear()
	_fits("note", KIENG.title, KIENG.body(), "", view, bad)
	_check("the kiêng note fits" + tag, bad.is_empty())


## Lays out one paper; anything that does not fit is added to `bad`.
func _fits(kind: String, title: String, body: String, aside: String, view: Vector2, bad: Array[String]) -> void:
	var paper := PaperLayout.paper_size(kind, view)
	var inside := paper.x <= view.x and paper.y <= view.y
	var result := PaperLayout.layout(kind, title, body, aside, paper)
	var ok := bool(result["fits"]) and inside
	for item: Dictionary in result["items"]:
		var font: Font = item["font"]
		var pos: Vector2 = item["pos"]
		var size: int = item["size"]
		var wide := font.get_string_size(str(item["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		ok = ok and wide <= float(item["width"]) + 0.01 and pos.x >= 0.0 \
			and pos.x + float(item["width"]) <= paper.x and pos.y - font.get_ascent(size) >= 0.0 \
			and pos.y + font.get_descent(size) <= paper.y
	if not ok:
		bad.append(kind + ": " + body.left(30))
		print("  does not fit: ", kind, " / ", body.left(40), " / ", aside.left(20))


func _notebook(view: Vector2) -> void:
	var tag := " at %dx%d" % [view.x, view.y]
	var spread := NotebookSpread.new()
	spread.size = RinNotebook.spread_size(view)
	var page := spread.page_size()
	_check("the open notebook is a landscape spread over most of the screen" + tag,
		spread.size.x > spread.size.y * 1.6 and spread.size.x >= view.x * 0.85 and page.x > page.y * 0.8)
	var flags := {}
	for day in CLUES.lines.size():
		flags["note_clue_%d" % (day + 1)] = true
	flags["note_missed_calm"] = true
	for omen in OmenPicker.CATALOG.omens:
		flags["note_missed_" + omen.id] = true
	var pages := RinNotebook.pages_for(spread, flags)
	var font_px := spread.font_size()
	var ok := PaperLayout.HAND.get_ascent(font_px) <= spread.rule_step() * 1.1  # one line per rule
	for side in 2:
		var width := spread.writing_span(side).y
		for rows: Array in pages:
			ok = ok and rows.size() <= NotebookSpread.rows()
			for row: Dictionary in rows:
				ok = ok and PaperLayout.HAND.get_string_size(str(row["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x <= width
	_check("every notebook entry sits within its page's rules (%d pages)%s" % [pages.size(), tag], ok and pages.size() >= 2)
	spread.free()


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
