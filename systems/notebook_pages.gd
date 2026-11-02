class_name NotebookPages
extends RefCounted
## Rin's notebook (pure): which entries it holds and how they fill its pages.
## Clues found at sea ("note_clue_<n>", picked up on day n) come first in day
## order, each under its lunar date; then what the old folks said after a
## wrong night ("note_missed_<id>", plus the last "note_missed" for old saves).
## Pages are lists of rows, one per ruled line: {"text", "kind": date|line}.

const CLUE_PREFIX := "note_clue_"
const MISSED_KEY := "note_missed"
const ELDERS := "Người già dặn: "
const EMPTY := "Chưa ghi gì."


## Entries {"date": String, "text": String}. `clues`: clues.tres lines (index
## = day - 1); `hint_for`: missed id -> hint text ("" when unknown).
static func entries(flags: Dictionary, clues: Array[String], hint_for: Callable) -> Array[Dictionary]:
	var days: Array[int] = []
	var heard: Array[String] = []
	for key: String in flags:
		var rest := key.substr(CLUE_PREFIX.length())
		if key.begins_with(CLUE_PREFIX) and rest.is_valid_int():
			days.append(int(rest))
		elif key.begins_with(MISSED_KEY + "_"):
			_add_once(heard, key.substr(MISSED_KEY.length() + 1))
	_add_once(heard, str(flags.get(MISSED_KEY, "")))
	days.sort()
	var out: Array[Dictionary] = []
	for day in days:
		if day >= 1 and day <= clues.size():
			out.append({"date": LoopCalendar.date_text(day), "text": clues[day - 1]})
	var said: Array[String] = []
	for id in heard:
		var hint := str(hint_for.call(id))
		if hint == "":
			continue
		if not hint.begins_with(ELDERS):
			hint = ELDERS + hint
		if not said.has(hint):  # two omens may share a saying
			said.append(hint)
			out.append({"date": "", "text": hint})
	return out


static func _add_once(list: Array[String], id: String) -> void:
	if id != "" and not list.has(id):
		list.append(id)


## Greedy word wrap; `measure`: text -> width in the same unit as `max_width`.
static func wrap_text(text: String, max_width: float, measure: Callable) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in text.split(" ", false):
		var tried := word if current == "" else current + " " + word
		if current != "" and float(measure.call(tried)) > max_width:
			lines.append(current)
			current = word
		else:
			current = tried
	if current != "":
		lines.append(current)
	return lines


## Pages of rows. An entry that does not fit what is left of a page starts
## the next one; an entry taller than a page runs on. One blank row between.
## No entries = one page with EMPTY.
static func layout(list: Array[Dictionary], max_width: float, rows_per_page: int, measure: Callable) -> Array[Array]:
	var pages: Array[Array] = [[]]
	if list.is_empty():
		pages[0].append({"text": EMPTY, "kind": "line"})
		return pages
	for entry in list:
		var rows: Array[Dictionary] = []
		if str(entry.get("date", "")) != "":
			rows.append({"text": str(entry["date"]), "kind": "date"})
		for line in wrap_text(str(entry.get("text", "")), max_width, measure):
			rows.append({"text": line, "kind": "line"})
		var page: Array = pages[-1]
		if not page.is_empty():
			if page.size() + 1 + rows.size() > rows_per_page:
				pages.append([])
			else:
				page.append({"text": "", "kind": "gap"})
		for row in rows:
			if pages[-1].size() >= rows_per_page:
				pages.append([])
			pages[-1].append(row)
	return pages


## Two pages face each other: spread i shows pages 2i and 2i + 1.
static func spread_count(pages: Array[Array]) -> int:
	return maxi(1, ceili(pages.size() / 2.0))
