class_name PaperFit
extends RefCounted
## Fits words into a box with a real font (papers, notebook, Label3D signs):
## wraps by measured width, then shrinks the size one step at a time until
## every line fits. Never clips: when even the smallest size is too big the
## result says "fits": false and the caller squeezes the line spacing.


## Word wrap at `size`; "\n" starts a new line, "\n\n" leaves a blank one.
static func wrap_lines(font: Font, text: String, width: float, size: int) -> Array[String]:
	var measure := func(words: String) -> float:
		return font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lines: Array[String] = []
	for paragraph in text.split("\n"):
		if paragraph.strip_edges() == "":
			lines.append("")
		else:
			lines.append_array(NotebookPages.wrap_text(paragraph, width, measure))
	return lines


static func widest(font: Font, lines: Array[String], size: int) -> float:
	var most := 0.0
	for line in lines:
		most = maxf(most, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return most


## Free text in a box: {"size", "lines", "step" (baseline to baseline),
## "fits"}. `spacing` scales the font's line height.
static func box(font: Font, text: String, area: Vector2, max_size: int, min_size: int,
		spacing: float = 1.0) -> Dictionary:
	var lines: Array[String] = []
	for size in range(max_size, min_size - 1, -1):
		lines = wrap_lines(font, text, area.x, size)
		var step := font.get_height(size) * spacing
		var tall := step * float(lines.size() - 1) + font.get_height(size)
		if tall <= area.y and widest(font, lines, size) <= area.x:
			return {"size": size, "lines": lines, "step": step, "fits": true}
	var squeezed := (area.y - font.get_height(min_size)) / float(maxi(1, lines.size() - 1))
	return {"size": min_size, "lines": lines, "step": squeezed, "fits": false}


## Writing on ruled lines: one line per rule, `rows` rules. Same result keys
## ("step" is left to the caller: the ruling).
static func ruled(font: Font, text: String, width: float, rows: int, max_size: int,
		min_size: int) -> Dictionary:
	var lines: Array[String] = []
	for size in range(max_size, min_size - 1, -1):
		lines = wrap_lines(font, text, width, size)
		if lines.size() <= rows and widest(font, lines, size) <= width:
			return {"size": size, "lines": lines, "fits": true}
	return {"size": min_size, "lines": lines, "fits": false}


## Height of `lines` drawn by `box` (top of the first to bottom of the last).
static func height_of(font: Font, fit: Dictionary) -> float:
	var lines: Array = fit["lines"]
	var size: int = fit["size"]
	var step: float = fit["step"]
	return step * float(lines.size() - 1) + font.get_height(size)


## For a Label3D (e.g. the date on the room calendar): wraps its text into
## `box` (world units) and picks the largest font_size from `max_size` down
## that fits; returns that size ("fits" fails = `min_size`).
static func fit_label3d(label: Label3D, box_size: Vector2, max_size: int, min_size: int = 8) -> int:
	var font: Font = label.font if label.font else ThemeDB.fallback_font
	var pixels := box_size / label.pixel_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = pixels.x
	var fit := box(font, label.text, pixels, max_size, min_size)
	label.font_size = int(fit["size"])
	return label.font_size


## Every character of `text` the font lacks (spaces and line breaks skipped).
static func missing_glyphs(font: FontFile, text: String) -> String:
	var missing := ""
	for i in text.length():
		var code := text.unicode_at(i)
		if code <= 32 or font.has_char(code) or missing.contains(char(code)):
			continue
		missing += char(code)
	return missing
