class_name SubtitleTricks
extends RefCounted
## Subtitles that are a little wrong (pure): a line repeated word for word,
## Rin called by his grandfather's name, a line that nobody in the scene
## says. Shown through the normal subtitle path ("Bảo: ..." lines), at most
## once per loop (UncannyDirector).

const WRONG_NAME := "Tư"
## Said by no one present.
const EXTRA_LINES: Array[String] = ["Ông Tư: ...lạnh quá, Rin.", "...Rin ơi, nước sâu lắm."]


## The speaker part of "Bảo: ..." ("" when there is none).
static func speaker(line: String) -> String:
	var colon := line.find(": ")
	return line.left(colon) if colon > 0 else ""


## The same line with Rin's name swapped for ông Tư's; a line without his
## name gets it appended, the way Bảo calls him.
static func wrong_name(line: String) -> String:
	if line.contains("Rin"):
		return line.replace("Rin", WRONG_NAME)
	var body := line.trim_suffix(".").trim_suffix("!")
	return "%s, %s." % [body, WRONG_NAME]


## Exactly the same words again (no "lại", no change): played back.
static func repeat(line: String) -> String:
	return line


static func extra(seed_: int) -> String:
	return EXTRA_LINES[posmod(seed_, EXTRA_LINES.size())]


## The line for a trick kind ("repeat" / "wrong_name" / "extra").
static func line_for(kind: String, base: String, seed_: int = 0) -> String:
	match kind:
		"repeat":
			return repeat(base)
		"wrong_name":
			return wrong_name(base)
		"extra":
			return extra(seed_)
	return ""
