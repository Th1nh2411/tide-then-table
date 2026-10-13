extends Node
## Standalone test for SpeechLine (run with F6): one bubble per speaker, the
## same speaker's next line waits its turn, app lines, sticky lines, and the
## dialogue portrait's name slugs.

var _failures: int = 0
var _time: float = 0.0
var _speech: SpeechLine


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var speech := SpeechLine.new()
	speech.min_seconds = 0.3
	speech.max_wait = 0.3
	speech.clock = func() -> float: return _time
	_speech = speech
	layer.add_child(speech)
	speech.say("Khoang gần đầy rồi.", 2.0)
	speech.say("Bảo: Hết rau rồi Rin ơi!", 2.0)
	speech.say("[MSG] Có khách đặt cá", 2.0)
	_check("each speaker keeps their own bubble", speech.current("Rin") == "Khoang gần đầy rồi."
		and speech.current("Bảo") == "Hết rau rồi Rin ơi!" and speech.current("NEO") == "Có khách đặt cá")
	speech.say("Được con Mực.", 2.0)
	_check("same speaker's next line waits", speech.current("Rin") == "Khoang gần đầy rồi.")
	await _wait(0.4)
	_check("then it shows", speech.current("Rin") == "Được con Mực.")
	speech.say("Thuyền đang được kéo về...", 0.0)
	await _wait(0.8)
	_check("a kept line stays", speech.current("Rin") == "Thuyền đang được kéo về...")
	speech.say("Về tới bến rồi.", 0.3)
	await _wait(0.1)
	_check("a kept line gives way to the next", speech.current("Rin") == "Về tới bến rồi.")
	await _wait(0.6)
	_check("short line fades away", speech.current("Rin") == "")
	speech.hide_line()
	_check("hide_line clears all", speech.current("Bảo") == "")
	_check("portrait slugs", DialoguePortrait.slug("Cô Năm") == "co_nam" and DialoguePortrait.slug("Bảo") == "bao"
		and DialoguePortrait.slug("Ông Tám") == "ong_tam")
	var commands := CutsceneScript.parse("speak \"Cô Năm (vui)\" \"Chào con.\"")
	_check("cutscene speaker with a mood", commands[0]["args"][0] == "Cô Năm (vui)")
	var lines := DialogueLibrary.parse("Rin (lo): Sắp hết dầu rồi.")
	_check("dialogue speaker with a mood", lines[0]["speaker"] == "Rin (lo)")
	print("speech_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


## Moves the fake clock in small steps and lets the bubbles update.
func _wait(seconds: float) -> void:
	var end := _time + seconds
	while _time < end:
		_time = minf(_time + 0.05, end)
		_speech._process(0.05)
	await get_tree().process_frame


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
