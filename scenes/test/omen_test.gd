extends Node
## Standalone test for OmenPicker (run with F6): no omen on the first or the
## last night, about half of the other nights carry one, never the same omen
## two nights running, same result for the same (loop, day), the flags the
## bedroom sets, and the catalog's data.

const LOOPS := 200


func _ready() -> void:
	var failures := 0
	var catalog := OmenPicker.CATALOG
	var first_ok := true
	var last_ok := true
	var repeat_ok := true
	var omen_nights := 0
	var middle_nights := 0
	var seen: Dictionary = {}
	for loop: int in range(LOOPS):
		var previous := ""
		for day: int in range(1, LoopCalendar.NIGHTS + 1):
			var id := OmenPicker.pick(catalog, loop, day)
			if day == 1 and id != "":
				first_ok = false
			if day == LoopCalendar.NIGHTS and id != "":
				last_ok = false
			if id != "" and id == previous:
				repeat_ok = false
			if day > 1 and day < LoopCalendar.NIGHTS:
				middle_nights += 1
				omen_nights += 1 if id != "" else 0
			if id != "":
				seen[id] = true
			previous = id
	var rate := float(omen_nights) / float(middle_nights)
	failures += _check("mùng 9 never has an omen", first_ok)
	failures += _check("rằm never has an omen", last_ok)
	failures += _check("never the same omen two nights running", repeat_ok)
	failures += _check("omen rate %.2f is about half" % rate, rate >= 0.4 and rate <= 0.6)
	failures += _check("every omen shows up", seen.size() == catalog.omens.size())
	failures += _check("same loop + day -> same omen",
		OmenPicker.pick(catalog, 3, 4) == OmenPicker.pick(catalog, 3, 4))
	var differs := false
	for loop: int in range(1, 20):
		for day: int in range(2, 7):
			differs = differs or OmenPicker.pick(catalog, loop, day) != OmenPicker.pick(catalog, 0, day)
	failures += _check("loops differ", differs)
	var ids: Dictionary = {}
	var data_ok := true
	for omen in catalog.omens:
		data_ok = data_ok and omen.id != "" and omen.title != "" and not ids.has(omen.id)
		ids[omen.id] = true
	failures += _check("catalog: ids unique, titled", data_ok and catalog.omens.size() >= 6)
	failures += _check_customs(catalog)
	# Flags as the bedroom sets them.
	GameState.reset()
	var omen_day := _first_omen_day(catalog, 0)
	failures += _check("loop 0 has an omen night", omen_day > 0)
	GameState.day = omen_day
	OmenPicker.start_day(catalog)
	var tonight := OmenPicker.tonight(catalog)
	failures += _check("start_day sets the omen flags", GameState.has_flag(LoopCalendar.OMEN_FLAG)
		and tonight != null and tonight.id == OmenPicker.pick(catalog, 0, omen_day))
	failures += _check("is_tonight", OmenPicker.is_tonight(tonight.id) if tonight else false)
	LoopCalendar.choose(false)
	failures += _check("omen night, home -> next", LoopCalendar.take_result() == LoopCalendar.Result.NEXT)
	GameState.day = 1
	OmenPicker.start_day(catalog)
	failures += _check("calm day clears the flags", not GameState.has_flag(LoopCalendar.OMEN_FLAG)
		and not GameState.story_flags.has(OmenPicker.ID_FLAG) and OmenPicker.tonight(catalog) == null)
	GameState.reset()
	print("OMEN TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


## False omens: 1-2 eerie-but-right customs on calm nights, never tonight's
## omen, deterministic; state() of a custom is "" on nights it is not shown.
func _check_customs(catalog: OmenCatalog) -> int:
	var failures := 0
	var count_ok := true
	var never_omen := true
	var seen: Dictionary = {}
	for loop: int in range(LOOPS):
		for day: int in range(1, LoopCalendar.NIGHTS + 1):
			var omen_id := OmenPicker.pick(catalog, loop, day)
			var shown := OmenPicker.customs(catalog, loop, day)
			var low := catalog.customs_on_omen_night if omen_id != "" else catalog.customs_min
			var high := catalog.customs_on_omen_night if omen_id != "" else catalog.customs_max
			count_ok = count_ok and shown.size() >= low and shown.size() <= high
			never_omen = never_omen and not shown.has(omen_id)
			for id in shown:
				seen[id] = true
				count_ok = count_ok and catalog.find(id).custom
	failures += _check("customs: 1-2 per calm night, all custom", count_ok)
	failures += _check("customs never show tonight's omen", never_omen)
	failures += _check("every custom shows up", seen.size() >= 3)
	failures += _check("customs are deterministic", OmenPicker.customs(catalog, 2, 3) == OmenPicker.customs(catalog, 2, 3))
	GameState.reset()
	var shown_today := OmenPicker.customs(catalog, 0, 1)
	var states_ok := true
	for omen in catalog.omens:
		var expected := "normal" if (not omen.custom or shown_today.has(omen.id)) else ""
		states_ok = states_ok and OmenPicker.state(omen.id, catalog) == expected
	GameState.set_flag(OmenPicker.ID_FLAG, "vang_ma")
	GameState.set_flag(LoopCalendar.OMEN_FLAG)
	states_ok = states_ok and OmenPicker.state("vang_ma", catalog) == "omen"
	failures += _check("state(): normal / hidden custom / omen", states_ok)
	return failures


func _first_omen_day(catalog: OmenCatalog, loop: int) -> int:
	for day: int in range(2, LoopCalendar.NIGHTS):
		if OmenPicker.pick(catalog, loop, day) != "":
			return day
	return -1


func _check(label: String, ok: bool) -> int:
	print(("PASS " if ok else "FAIL ") + label)
	return 0 if ok else 1
