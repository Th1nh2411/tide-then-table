extends Node
## Standalone test for the rod rhythm game (run with F6): RhythmChart (lanes,
## note counts, holds, playable gaps) and RhythmGame's judging (hits fill the
## reel, misses / wrong keys wear the line, long notes, win / lose).

var _failures: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 3
	_test_chart()
	_test_judging()
	print("rhythm_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _test_chart() -> void:
	var easy := RhythmChart.build(0.3, false, 1.0, _rng)
	var hard := RhythmChart.build(0.8, false, 1.0, _rng)
	_check("lanes by difficulty", RhythmChart.lane_count(0.3) == 2 and RhythmChart.lane_count(0.5) == 3
		and RhythmChart.lane_count(0.9) == 4)
	_check("harder fish: more notes", hard.size() > easy.size())
	_check("easy fish: taps only, lanes 0-1", easy.all(func(n: Dictionary) -> bool:
		return float(n["hold"]) == 0.0 and int(n["lane"]) < 2))
	var big := RhythmChart.build(0.8, false, 0.8, _rng)
	var rod := RhythmChart.build(0.8, false, 1.4, _rng)
	_check("big fish more notes, better rod fewer", big.size() > hard.size() and rod.size() < hard.size())
	var holds := 0
	var ordered := true
	for chart in [hard, RhythmChart.build(0.9, true, 1.0, _rng)]:
		for i in chart.size():
			holds += 1 if float(chart[i]["hold"]) > 0.0 else 0
			if i > 0 and float(chart[i]["t"]) <= float(chart[i - 1]["t"]) + float(chart[i - 1]["hold"]):
				ordered = false
	_check("hard fish pull (long notes)", holds > 0)
	_check("notes never overlap", ordered)


func _test_judging() -> void:
	var fish: FishData = load("res://data/fish/muc.tres")
	var game := RhythmGame.new()
	game.setup(fish, 1.0)
	var first: Dictionary = game.notes[0]
	game.set("_time", float(first["t"]))
	game.press(int(first["lane"]))
	_check("hit on time fills the reel", game.progress > 0.0 and int(first["state"]) == 2)
	var line_before := game.line
	game.press(int(first["lane"]))
	_check("wrong key wears the line a little", game.line < line_before and game.line > line_before - 0.1)
	var second: Dictionary = game.notes[1]
	game.set("_time", float(second["t"]) + 0.5)
	game.advance()
	_check("late note = miss", int(second["state"]) == 3 and game.misses == 1)
	# Play the rest perfectly: caught.
	for i in range(2, game.notes.size()):
		var note: Dictionary = game.notes[i]
		game.set("_time", float(note["t"]))
		game.press(int(note["lane"]))
		game.advance()
		if game.get("_done"):
			break
	_check("enough hits: caught", game.progress >= 0.999 and game.get("_done"))
	game.free()
	# A long note: held to the end counts fully, let go early is a miss.
	var hard: FishData = load("res://data/fish/ca_mu.tres")
	var found := false
	for attempt in 20:
		var g := RhythmGame.new()
		g.setup(hard, 1.0)
		for note in g.notes:
			if float(note["hold"]) > 0.0:
				found = true
				g.set("_time", float(note["t"]))
				g.press(int(note["lane"]))
				_check("long note: head hit -> holding", int(note["state"]) == 1)
				g.set("_time", float(note["t"]) + 0.05)
				g.release(int(note["lane"]))
				_check("long note: let go early -> miss", int(note["state"]) == 3)
				break
		g.free()
		if found:
			break
	_check("found a long note to test", found)


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
