class_name SubtitleText
extends RichTextLabel
## One subtitle line (SpeechStrip, DialogueBox): outlined text centred low on
## the screen that types in word by word at speaking pace (SubtitleTyper).
## Dead voices are pale blue-grey, slower and tremble a little ([tremble]).
## Headless runs show every line whole at once.

const TUNING: SubtitleTuning = preload("res://data/story/subtitle_tuning.tres")

var tuning: SubtitleTuning = TUNING
## The words without markup.
var plain: String = ""
var dead: bool = false
var instant: bool = DisplayServer.get_name() == "headless"
var _beats: Array[Vector2] = []
var _elapsed: float = 0.0


func _init(px: int = 12) -> void:
	bbcode_enabled = true
	fit_content = true
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("normal_font_size", px)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 4)
	install_effect(TrembleEffect.new())


## Starts typing `words` (plain text, brackets are shown as written).
func set_line(words: String, color: Color, is_dead: bool) -> void:
	plain = words
	dead = is_dead
	var body := escape(words)
	if is_dead:
		body = "[tremble rate=%.1f level=%d]%s[/tremble]" % [tuning.dead_shake_rate, tuning.dead_shake_level, body]
	text = body
	add_theme_color_override("default_color", color)
	var cps := tuning.dead_chars_per_second if is_dead else tuning.chars_per_second
	_beats = SubtitleTyper.beats(words, cps, tuning.comma_pause, tuning.stop_pause)
	_elapsed = 0.0
	visible_characters = -1
	if not instant:
		_show(SubtitleTyper.visible_at(_beats, 0.0))


func typing() -> bool:
	return visible_characters >= 0 and visible_characters < plain.length()


## Skips the typing: the whole line at once.
func finish() -> void:
	visible_characters = -1


## Seconds the whole line takes to type.
func type_seconds() -> float:
	return SubtitleTyper.duration(_beats)


## Moves the typing on by `seconds` (real time).
func advance(seconds: float) -> void:
	if not typing():
		return
	_elapsed += seconds
	_show(SubtitleTyper.visible_at(_beats, _elapsed))


func _show(letters: int) -> void:
	visible_characters = -1 if letters >= plain.length() else letters


## Plain text -> BBCode-safe text.
static func escape(words: String) -> String:
	return words.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")
