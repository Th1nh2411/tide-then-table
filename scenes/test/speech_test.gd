extends Node
## Standalone test for SpeechStrip (run with F6): speaker names, the default
## speaker, one line at a time (a fresh line makes the next wait), kept
## lines, fading out; plus the speaker slugs / moods parsed by
## the dialogue code.

var _failures: int = 0


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var strip := SpeechStrip.new()
	strip.default_speaker = "Rin"
	layer.add_child(strip)
	await get_tree().process_frame
	strip.say("Bảo: Hết ca rồi.", 1.0)
	_check("named line shows its speaker", strip._speaker.text == "Bảo:" and strip._text.text == "Hết ca rồi.")
	_check("subtitle: no box, outlined, low and centred", strip._text.get_theme_constant("outline_size") > 0
		and strip._text.position.y > strip.size.y * 0.6)
	strip.say("Đèn leo lét rồi... về thôi.", 0.0)
	strip.say("Đèn leo lét rồi... về thôi.", 0.0)
	_check("a line said over a fresh one waits, once", strip.current == "Bảo: Hết ca rồi." and strip._queue.size() == 1)
	strip._process(SpeechStrip.MIN_SECONDS + 0.1)
	_check("then shows, with the default speaker", strip._speaker.text == "Rin:" and strip.current == "Đèn leo lét rồi... về thôi.")
	strip._process(5.0)
	_check("a kept line stays", strip.current != "")
	strip.say("Buông ra!", 0.2)
	strip._process(0.3)
	_check("a short line clears", strip.current == "")
	_check("portrait slugs", DialoguePortrait.slug("Cô Năm") == "co_nam" and DialoguePortrait.slug("Bảo") == "bao"
		and DialoguePortrait.slug("Ông Tám") == "ong_tam")
	var lines := DialogueLibrary.parse("Rin (lo): Sắp hết dầu rồi.")
	_check("dialogue speaker with a mood", lines[0]["speaker"] == "Rin (lo)")
	print("speech_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
