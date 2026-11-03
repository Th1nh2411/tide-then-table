class_name SpeechStrip
extends Control
## Short spoken lines as subtitles (horror build), same look as DialogueBox:
## outlined text centred low on the screen, the speaker's name just above it
## in their colour (SpeakerTable), no box. Each line types in word by word
## (SubtitleText), stays for a time based on its length, then fades out.
## E / click / a queued line skip the typing. Dead speakers (SpeakerTable)
## tremble in pale blue-grey under the name "...". "Bảo: ..." names Bảo;
## other lines get `default_speaker` ("" = none). One line at a time, up to
## MAX_QUEUE waiting. Sound captions: `caption()` (CaptionLayer).
## It covers its parent's rect on its own, whatever anchors the owner sets.

const MIN_SECONDS := 0.9
const MAX_QUEUE := 4
const SPEAKERS: SpeakerTable = preload("res://data/story/speakers.tres")
## Kept for older callers; colours live in data/story/speakers.tres.
const NAME_COLORS := {"Rin": Color("4f8fba"), "Bảo": Color("de9e41"), "Mèo": Color("be772b")}
const OTHER_NAME := Color("c0503f")
const INK := Color("efe6d2")

## Speaker for lines without "Name:" (the sea: Rin talking to himself).
@export var default_speaker: String = ""
## Kept for older callers; the subtitle is as wide as the screen allows.
@export var text_width: float = 520.0
@export var font_size: int = 12
@export var tuning: SubtitleTuning = SubtitleText.TUNING

## The line on screen as it was said ("" = none).
var current: String = ""
## Shows lines whole at once (headless runs).
var instant: bool = DisplayServer.get_name() == "headless"
var _speaker: Label
var _text: SubtitleText
var _hold: float = 0.0  # seconds the typed line stays; < 0 = until clear()
var _shown_for: float = 0.0  # since the line finished typing
var _queue: Array[Dictionary] = []
var _fade: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker = Label.new()
	_speaker.theme_type_variation = &"TitleLabel"
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_speaker.add_theme_constant_override("outline_size", 4)
	add_child(_speaker)
	_text = SubtitleText.new(font_size)
	add_child(_text)
	visible = false


func _ready() -> void:
	_speaker.add_theme_font_size_override("font_size", font_size - 2)
	_text.add_theme_font_size_override("normal_font_size", font_size)
	_text.tuning = tuning
	CaptionLayer.ensure(get_tree())


## Shows a line (or queues it behind the current one); `seconds` <= 0 keeps
## it until `clear()`, otherwise it stays at least that long.
func say(words: String, seconds: float = 4.0) -> void:
	var speaker := words.get_slice(":", 0)
	var named := speaker != words and speaker.length() <= 10
	var text := words.substr(speaker.length() + 1).strip_edges() if named else words
	say_as(speaker if named else "", text, {"seconds": seconds, "key": words})


## Entry for scripted lines: `opts` may hold "seconds" (float), "dead"
## (bool, overrides SpeakerTable), "name" (shown name instead of the
## speaker's), "key" (what `current` reports; default "Speaker: text").
func say_as(speaker: String, text: String, opts: Dictionary = {}) -> void:
	var line := _resolve(speaker, text, opts)
	if line["key"] == current or _queue.any(func(item: Dictionary) -> bool: return item["key"] == line["key"]):
		return
	if current != "":
		_text.finish()  # the next line is waiting: show this one whole
		if _queue.size() >= MAX_QUEUE:
			_queue.pop_front()
		_queue.append(line)
		return
	_show_now(line)


## A sound caption ("[tiếng gõ cửa]"), in its own grey italic style.
func caption(text: String) -> void:
	CaptionLayer.ensure(get_tree())
	CaptionLayer.show_caption(text)


func is_typing() -> bool:
	return current != "" and _text.typing()


## Finishes the typing at once.
func skip() -> void:
	_text.finish()


func _resolve(speaker: String, text: String, opts: Dictionary) -> Dictionary:
	var dead := SPEAKERS.is_dead(speaker) or (speaker == "" and SPEAKERS.is_dead_whisper(text))
	if opts.has("dead"):
		dead = bool(opts["dead"])
	var who := speaker if speaker != "" or dead else default_speaker
	var shown: String = str(opts.get("name", SPEAKERS.dead_label if dead else who))
	var key: String = str(opts.get("key", (speaker + ": " + text) if speaker != "" else text))
	var seconds: Variant = opts.get("seconds", 4.0)
	return {"key": key, "name": shown, "who": who, "text": text, "dead": dead,
		"seconds": float(seconds) if (seconds is float or seconds is int) else 4.0}


func _show_now(line: Dictionary) -> void:
	current = str(line["key"])
	var dead: bool = line["dead"]
	var shown: String = line["name"]
	_speaker.visible = shown != ""
	_speaker.text = shown if shown == SPEAKERS.dead_label else shown + ":"
	_speaker.add_theme_color_override("font_color", tuning.dead_name_color if dead else SPEAKERS.color_of(str(line["who"])))
	_text.instant = instant
	var text: String = line["text"]
	_text.set_line(text, tuning.dead_color if dead else INK, dead)
	var seconds: float = line["seconds"]
	_hold = -1.0 if seconds <= 0.0 else maxf(tuning.hold_for(text.length()), seconds - _text.type_seconds())
	_shown_for = 0.0
	var fresh := not visible or modulate.a < 1.0
	show()
	_place()
	if fresh:  # a quick fade in, no slide (subtitles stay put)
		modulate.a = 0.0
		_fade_to(1.0, 0.15)


## Bottom-centre, like DialogueBox: the line, its speaker just above.
func _place() -> void:
	if not is_inside_tree():
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view := size if size.x > 0.0 else get_viewport_rect().size
	_text.size = Vector2(view.x - 120.0, 0.0)
	_text.reset_size()
	_text.size.x = view.x - 120.0
	_text.position = Vector2(60.0, view.y - 22.0 - _text.get_minimum_size().y)
	_speaker.reset_size()
	var lift := 4.0 if _text.dead else -3.0  # "..." sits on its baseline: keep it off the accents
	_speaker.position = Vector2((view.x - _speaker.size.x) * 0.5, _text.position.y - _speaker.size.y - lift)


## Fades the line away and drops anything queued. A line still typing shows
## whole for a moment first.
func clear() -> void:
	current = ""
	_queue.clear()
	if not visible:
		return
	var grace := 0.0 if instant or not _text.typing() else tuning.clear_grace
	_text.finish()
	_fade_to(0.0, tuning.fade_seconds, grace).tween_callback(func() -> void:
		if current == "":
			_text.text = ""
			hide())


func _fade_to(alpha: float, seconds: float, delay: float = 0.0) -> Tween:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", alpha, seconds).set_delay(delay)
	return _fade


func _input(event: InputEvent) -> void:
	if current == "" or not _text.typing():
		return
	var click := event as InputEventMouseButton
	if event.is_action_pressed("interact") or event.is_action_pressed("cast") \
			or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT):
		_text.finish()  # never eats the press


func _process(delta: float) -> void:
	step(delta / maxf(Engine.time_scale, 0.01))  # subtitles ignore slow-mo


## One frame of `seconds` real time (tests drive this directly).
func step(seconds: float) -> void:
	if current == "":
		return
	_place()  # wrapped text settles its height after a frame
	if _text.typing():
		_text.advance(seconds)
		return
	_shown_for += seconds
	if not _queue.is_empty() and _shown_for >= minf(MIN_SECONDS, tuning.min_seconds_queued):
		_show_now(_queue.pop_front())
		return
	if _hold >= 0.0 and _shown_for >= _hold:
		clear()
