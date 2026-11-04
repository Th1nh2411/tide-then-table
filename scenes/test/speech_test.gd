extends Node
## Standalone test for SpeechStrip (run with F6): speaker names, the default
## speaker, typing word by word + skip, hold by length + fade, the queue,
## dead voices ("..." name, pale trembling, slower), DialogueBox's dead
## style; plus the speaker slugs / moods parsed by the dialogue code and the
## interaction prompt (InteractPrompt).

var _failures: int = 0


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var strip := SpeechStrip.new()
	strip.default_speaker = "Rin"
	layer.add_child(strip)
	await get_tree().process_frame
	strip.say("Bảo: Hết ca rồi.", 1.0)
	_check("named line shows its speaker", strip._speaker.text == "Bảo:" and strip._text.plain == "Hết ca rồi.")
	_check("headless: the line shows whole at once", not strip.is_typing())
	strip.step(0.0)
	_check("subtitle: no box, outlined, low and centred", strip._text.get_theme_constant("outline_size") > 0
		and strip._text.position.y > strip.size.y * 0.6)
	strip.say("Đèn leo lét rồi... về thôi.", 0.0)
	strip.say("Đèn leo lét rồi... về thôi.", 0.0)
	_check("a line said over another waits, once", strip.current == "Bảo: Hết ca rồi." and strip._queue.size() == 1)
	strip.step(SpeechStrip.MIN_SECONDS + 0.1)
	_check("then shows, with the default speaker", strip._speaker.text == "Rin:" and strip.current == "Đèn leo lét rồi... về thôi.")
	strip.step(9.0)
	_check("a kept line stays", strip.current != "")
	strip.clear()
	_typing_checks(strip)
	await _fade_checks(strip)
	_dead_checks(strip)
	_box_checks()
	_prompt_checks()
	_check("portrait slugs", DialoguePortrait.slug("Cô Năm") == "co_nam" and DialoguePortrait.slug("Bảo") == "bao"
		and DialoguePortrait.slug("Ông Tám") == "ong_tam")
	var lines := DialogueLibrary.parse("Rin (lo): Sắp hết dầu rồi.")
	_check("dialogue speaker with a mood", lines[0]["speaker"] == "Rin (lo)")
	print("speech_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


## Word by word at speaking pace; a press / a queued line shows it whole.
func _typing_checks(strip: SpeechStrip) -> void:
	strip.instant = false
	strip.say("Bảo: Ra bến đi, trời sắp tối rồi đó.", 2.0)
	var first: int = strip._text.visible_characters
	_check("typing starts with the first word only", first > 0 and first < 6)
	strip.step(0.5)
	var later: int = strip._text.visible_characters
	_check("more words after half a second", later > first and strip.is_typing())
	_check("a word shows whole, never half", strip._text.plain[later - 1] == " ")
	var cps: float = strip.tuning.chars_per_second
	_check("speaking pace 14-18 letters/s", cps >= 14.0 and cps <= 18.0)
	_check("pause after a comma", SubtitleTyper.duration(SubtitleTyper.beats("a, b", 10.0, 0.5, 0.0))
		> SubtitleTyper.duration(SubtitleTyper.beats("a b", 10.0, 0.5, 0.0)))
	strip.skip()
	_check("skip shows the whole line", not strip.is_typing() and strip._text.visible_characters == -1)
	strip.say("Rin: Về thôi.", 1.0)
	strip.step(SpeechStrip.MIN_SECONDS + 0.05)
	_check("next line types in", strip.current == "Rin: Về thôi." and strip.is_typing())
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	strip._input(press)
	_check("E shows it whole", not strip.is_typing())


func _fade_checks(strip: SpeechStrip) -> void:
	var hold := strip.tuning.hold_for("Về thôi.".length())
	_check("held by its length", hold > 1.0 and hold < 3.0)
	strip.step(hold + 0.05)
	_check("then cleared", strip.current == "")
	_check("fading, not gone at once", strip.visible and strip._fade.is_running())
	await get_tree().create_timer(strip.tuning.fade_seconds + 0.15).timeout
	_check("faded out", not strip.visible)
	strip.instant = true


func _dead_checks(strip: SpeechStrip) -> void:
	strip.say("Ông Tư: Về nhà đi con.", 2.0)
	_check("dead speaker named ...", strip._speaker.text == "..." and strip._text.dead)
	_check("dead: pale blue-grey, trembling", strip._text.get_theme_color("default_color") == strip.tuning.dead_color
		and strip._text.text.begins_with("[tremble"))
	_check("dead types slower", strip.tuning.dead_chars_per_second < strip.tuning.chars_per_second)
	strip.clear()
	strip.say("...về đi...", 2.0)
	_check("unnamed whisper is a dead voice, not Rin", strip._speaker.text == "..." and strip._text.dead)
	strip.clear()
	strip.say("Bảo: Ê.", 2.0)
	_check("the living keep their colour", not strip._text.dead
		and strip._speaker.get_theme_color("font_color") == SpeechStrip.SPEAKERS.color_of("Bảo"))
	strip.clear()
	strip.say_as("Bảo", "Rin ơi...", {"name": "Ông Tư", "seconds": 2.0})
	_check("say_as: shown name override", strip._speaker.text == "Ông Tư:" and strip.current == "Bảo: Rin ơi...")
	strip.clear()
	strip.say_as("", "[ai đó]", {"dead": true})
	_check("say_as: forced dead, brackets kept", strip._text.dead and strip._text.get_parsed_text() == "[ai đó]")
	strip.clear()


## InteractPrompt: fades in, a key-only mode, fades out keeping its words.
func _prompt_checks() -> void:
	var prompt := InteractPrompt.new()
	add_child(prompt)
	prompt.set_text("đọc")
	_check("prompt: starts faded", not prompt.shown())
	for i in 30:
		prompt._process(1.0 / 60.0)
	_check("prompt: fades in under half a second", prompt.shown() and prompt.key == "E")
	prompt.clear()
	prompt._process(1.0 / 60.0)
	_check("prompt: clear fades out, the old words still drawn", prompt.verb == "" and prompt._drawn_verb == "đọc")
	prompt.show_key("phím bất kỳ")
	for i in 30:
		prompt._process(1.0 / 60.0)
	_check("prompt: key-only glyph", prompt.shown() and prompt.verb == "" and prompt.key == "phím bất kỳ")
	var steady := InteractPrompt.new("sổ tay", "N", true)
	_check("prompt: steady list row sizes itself", steady.custom_minimum_size.x > 20.0 and steady.shown())
	steady.free()
	prompt.queue_free()


func _box_checks() -> void:
	var box := DialogueBox.new()
	add_child(box)
	box.show_line("Ông Tư", "Về nhà đi con.")
	_check("dialogue box: dead speaker named ...", box._name_label.text == "..." and box._text_label.dead)
	box.show_line("Bảo (vui)", "Ăn đi.")
	_check("dialogue box: living name + mood dropped", box._name_label.text == "Bảo:" and not box._text_label.dead)
	box._close()
	box.queue_free()


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
