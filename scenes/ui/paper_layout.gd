class_name PaperLayout
extends RefCounted
## Where the words go on each paper PaperReader shows (pure apart from the
## fonts): areas are fractions of the paper art, measured on the PNGs.
## Printed papers fit a box; handwritten ones sit on the paper's own ruling.
## `layout()` returns {"items": [{text, pos (baseline), width, align, size,
## font, color}], "boxes": [{rect, color}], "fits": bool}.

const SERIF: FontFile = preload("res://assets/fonts/OldStandard-Regular.ttf")
const SERIF_BOLD: FontFile = preload("res://assets/fonts/OldStandard-Bold.ttf")
const HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
## Newsprint black and pencil / ballpoint brown, both a little faded.
const PRINT_INK := Color(0.1, 0.085, 0.075, 0.93)
const HAND_INK := Color(0.2, 0.13, 0.08, 0.86)
const MASTHEAD_INK := Color("ecdfc2")
const ASIDE_PAPER := Color(0.87, 0.83, 0.72, 0.96)

const KINDS := {
	"newspaper": {"texture": "newspaper_front", "aspect": 1024.0 / 1400.0,
		"masthead": Rect2(0.07, 0.048, 0.625, 0.078), "headline": Rect2(0.07, 0.158, 0.86, 0.106),
		"aside": Rect2(0.05, 0.728, 0.9, 0.16)},
	# Ruled papers: first rule used and ruling (fractions of the height),
	# rules, writing span (fractions of the width). The top rules under the
	# folded corner / burnt edge are left blank.
	"letter": {"texture": "paper_letter_old", "aspect": 1.0,
		"first_rule": 212.0 / 1024.0, "rule": 48.9 / 1024.0, "rows": 15, "span": Vector2(0.12, 0.86)},
	"diary": {"texture": "paper_diary_page", "aspect": 1024.0 / 1400.0,
		"first_rule": 314.0 / 1400.0, "rule": 50.8 / 1400.0, "rows": 18, "span": Vector2(0.155, 0.84)},
}


static func spec(kind: String) -> Dictionary:
	# The kiêng note is written on the same torn page as the diary.
	return KINDS.get("diary" if kind == "note" else kind, KINDS["letter"])


## Paper size on a `view`-sized screen: as tall as fits, keeping its shape.
static func paper_size(kind: String, view: Vector2) -> Vector2:
	var aspect: float = spec(kind)["aspect"]
	var height := minf(view.y * 0.95, view.x * 0.92 / aspect)
	return Vector2(height * aspect, height)


static func layout(kind: String, title: String, body: String, aside: String, paper: Vector2) -> Dictionary:
	var out := {"items": [], "boxes": [], "fits": true}
	var s := spec(kind)
	if s.has("masthead"):
		_printed(out, s, title, body, aside, paper)
	else:
		_handwritten(out, s, title, body, paper)
	return out


static func _printed(out: Dictionary, s: Dictionary, title: String, body: String, aside: String, paper: Vector2) -> void:
	var mast := _scaled(s["masthead"], paper)
	_fill(out, SERIF_BOLD, title, mast, 24, 9, MASTHEAD_INK, HORIZONTAL_ALIGNMENT_CENTER, 1.0)
	var head := _scaled(s["headline"], paper)
	_fill(out, SERIF_BOLD, body, head, 17, 7, PRINT_INK, HORIZONTAL_ALIGNMENT_CENTER, 0.98)
	if aside == "":
		return
	var paste := _scaled(s["aside"], paper)
	(out["boxes"] as Array).append({"rect": paste, "color": ASIDE_PAPER})
	_fill(out, SERIF, aside, paste.grow(-paper.x * 0.025), 14, 7, PRINT_INK, HORIZONTAL_ALIGNMENT_LEFT, 1.0)


## Words fitted into `area`, centred vertically.
static func _fill(out: Dictionary, font: Font, text: String, area: Rect2, top: int, low: int,
		ink: Color, align: HorizontalAlignment, spacing: float) -> void:
	if text == "":
		return
	var fit := PaperFit.box(font, text, area.size, top, low, spacing)
	out["fits"] = bool(out["fits"]) and bool(fit["fits"])
	var size: int = fit["size"]
	var y := area.position.y + (area.size.y - PaperFit.height_of(font, fit)) * 0.5 + font.get_ascent(size)
	for line: String in fit["lines"]:
		_add(out, line, Vector2(area.position.x, y), area.size.x, align, size, font, ink)
		y += float(fit["step"])


## Title and body on the paper's ruled lines, the title on its own rule.
static func _handwritten(out: Dictionary, s: Dictionary, title: String, body: String, paper: Vector2) -> void:
	var span: Vector2 = s["span"]
	var left := span.x * paper.x
	var width := (span.y - span.x) * paper.x
	var rule: float = float(s["rule"]) * paper.y
	var rows: int = s["rows"]
	var text := body if title == "" else title + "\n" + body
	var fit := PaperFit.ruled(HAND, text, width, rows, floori(rule * 0.88), maxi(6, floori(rule * 0.6)))
	out["fits"] = fit["fits"]
	var lines: Array = fit["lines"]
	var step := rule if fit["fits"] else rule * float(rows) / float(lines.size())
	var size: int = fit["size"]
	var y: float = float(s["first_rule"]) * paper.y - rule * 0.1
	var title_rows := 0 if title == "" else PaperFit.wrap_lines(HAND, title, width, size).size()
	for i in lines.size():
		var line: String = lines[i]
		var align := HORIZONTAL_ALIGNMENT_CENTER if i < title_rows else HORIZONTAL_ALIGNMENT_LEFT
		_add(out, line, Vector2(left, y), width, align, size, HAND, HAND_INK)
		y += step


static func _add(out: Dictionary, text: String, pos: Vector2, width: float, align: HorizontalAlignment,
		size: int, font: Font, ink: Color) -> void:
	if text == "":
		return
	(out["items"] as Array).append({"text": text, "pos": pos, "width": width, "align": align,
		"size": size, "font": font, "color": ink})


static func _scaled(area: Rect2, paper: Vector2) -> Rect2:
	return Rect2(area.position * paper, area.size * paper)
