extends Node
## Standalone test for Rin's notebook (run with F6): NotebookPages picks the
## clues in day order and the old folks' sayings once each, wraps and pages
## them; LoopCalendar keeps every miss; the hand font has every glyph;
## RinNotebook pauses the game while open.

const CLUES: Array[String] = ["Chai một", "Dây hai", "Trang ba"]


func _ready() -> void:
	call_deferred("_run")


func _hint(id: String) -> String:
	var hints := {"calm": "Người già dặn: đêm yên thì đi.", "hai_dang": "đèn đổi màu thì ở nhà.",
		"twin": "Người già dặn: đêm yên thì đi."}
	return str(hints.get(id, ""))


func _len(text: String) -> float:
	return float(text.length())


func _run() -> void:
	SaveSystem.autosave_off = true
	var failures := 0
	var none := NotebookPages.entries({}, CLUES, _hint)
	failures += _check("no flags, no entries", none.is_empty())
	var empty := NotebookPages.layout(none, 20.0, 10, _len)
	failures += _check("empty notebook: one page saying Chưa ghi gì.",
		empty.size() == 1 and str((empty[0][0] as Dictionary)["text"]) == "Chưa ghi gì.")
	var flags := {"note_clue_3": true, "loop_count": 2, "note_clue_1": true, "note_clue_x": true,
		"note_clue_9": true, "tip_wave": true}
	var list := NotebookPages.entries(flags, CLUES, _hint)
	failures += _check("clues in day order, bad ones skipped", list.size() == 2
		and list[0]["text"] == "Chai một" and list[1]["text"] == "Trang ba")
	failures += _check("each clue under its lunar date", list[0]["date"] == "Mùng 9 tháng Bảy"
		and list[1]["date"] == "11 tháng Bảy")
	flags = {"note_missed_calm": true, "note_missed": "hai_dang", "note_missed_hai_dang": true,
		"note_missed_twin": true, "note_missed_nope": true, "note_clue_2": true}
	list = NotebookPages.entries(flags, CLUES, _hint)
	var hints: Array[String] = []
	for entry in list.slice(1):
		hints.append(str(entry["text"]))
	failures += _check("sayings after the clues, once each, unknown ones left out",
		list.size() == 3 and list[0]["text"] == "Dây hai"
		and hints == (["Người già dặn: đêm yên thì đi.", "Người già dặn: đèn đổi màu thì ở nhà."] as Array[String]))
	var wrapped := NotebookPages.wrap_text("một hai ba bốn năm sáu", 8.0, _len)
	failures += _check("word wrap keeps lines inside the width",
		wrapped == (["một hai", "ba bốn", "năm sáu"] as Array[String]))
	failures += _check("a word longer than a line stays whole",
		NotebookPages.wrap_text("ngoằnngoèo dài", 4.0, _len) == (["ngoằnngoèo", "dài"] as Array[String]))
	var many: Array[Dictionary] = []
	for i in 7:
		many.append({"date": "Ngày %d" % i, "text": "chữ chữ chữ chữ chữ chữ"})
	var pages := NotebookPages.layout(many, 8.0, 9, _len)
	var fits := true
	var starts_clean := true
	for page: Array in pages:
		fits = fits and page.size() <= 9
		starts_clean = starts_clean and str((page[0] as Dictionary)["kind"]) == "date"
	failures += _check("pages never overflow, an entry is not split", fits and starts_clean)
	failures += _check("7 entries of 4 rows -> 4 pages, 2 spreads",
		pages.size() == 4 and NotebookPages.spread_count(pages) == 2)
	GameState.reset()
	LoopCalendar._remember_miss("calm")
	LoopCalendar._remember_miss("hai_dang")
	LoopCalendar.reset_loop()
	failures += _check("every miss is kept through a reset", LoopCalendar.missed() == "hai_dang"
		and GameState.has_flag("note_missed_calm") and GameState.has_flag("note_missed_hai_dang"))
	failures += _check("the hand font writes every notebook line", _missing_glyphs() == "")
	GameState.reset()
	GameState.set_flag("note_clue_1")
	var book := RinNotebook.open(self)
	failures += _check("opening pauses on the cover", get_tree().paused and book._spread == -1)
	failures += _check("a second N does not open another", RinNotebook.open(self) == null)
	book._turn(0)
	failures += _check("E opens the spread", book._spread == 0 and book._ink.visible)
	book._turn(5)
	failures += _check("no turning past the last page", book._spread == 0)
	book.close()
	failures += _check("closing unpauses", not get_tree().paused)
	await get_tree().process_frame
	GameState.reset()
	print("NOTEBOOK TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _missing_glyphs() -> String:
	var text := "SỔ TAY Rin " + NotebookPages.EMPTY + " 0123456789 " + " ".join(RinNotebook.CLUES.lines)
	for omen in OmenPicker.CATALOG.omens:
		text += omen.missed_hint
	text += RinNotebook.NEWS.calm_missed_hint
	for i in 7:
		text += LoopCalendar.date_text(i + 1)
	var missing := ""
	for i in text.length():
		var code := text.unicode_at(i)
		if not RinNotebook.HAND.has_char(code) and not missing.contains(char(code)):
			missing += char(code)
	if missing != "":
		print("  missing: ", missing)
	return missing


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
