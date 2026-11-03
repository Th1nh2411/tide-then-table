class_name CaptionLayer
extends CanvasLayer
## Closed captions for story sounds: grey italic words in [brackets] above
## the subtitles, e.g. "[tiếng gõ mạn thúng, ba tiếng — bên trái]". One per
## game, under the root (made by the first SpeechStrip / OnScreenText):
## listens to Sfx.sound_played, looks the recipe up in SoundCaptions and adds
## a direction word for sounds placed in the world. Off with the setting
## "Phụ đề âm thanh" (GameSettings.sound_captions). Sits over black screens.

const CAPTIONS: SoundCaptions = preload("res://data/story/sound_captions.tres")
const FONT: Font = preload("res://assets/fonts/BeVietnamPro-Medium.ttf")

static var _instance: CaptionLayer

var tuning: SubtitleTuning = SubtitleText.TUNING
## The caption on screen ("" = none).
var current: String = ""
var _label: Label
var _clock: float = 0.0
var _last: Dictionary = {}  # recipe -> seconds (ticks) it was captioned
var _fade: Tween


static func ensure(tree: SceneTree) -> CaptionLayer:
	if is_instance_valid(_instance):
		return _instance
	if tree == null:
		return null
	_instance = CaptionLayer.new()
	tree.root.add_child.call_deferred(_instance)
	return _instance


static func instance() -> CaptionLayer:
	return _instance if is_instance_valid(_instance) else null


## Shows a caption now (setting permitting); "" or no layer = nothing.
static func show_caption(text: String) -> void:
	if text == "" or not is_instance_valid(_instance) or not GameSettings.sound_captions():
		return
	_instance._show(CaptionDirector.compose(text))


func _init() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var italic := FontVariation.new()
	italic.base_font = FONT
	italic.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(tuning.caption_slant, 1.0), Vector2.ZERO)
	_label.add_theme_font_override("font", italic)
	_label.add_theme_font_size_override("font_size", tuning.caption_font_size)
	_label.add_theme_color_override("font_color", tuning.caption_color)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_label.add_theme_constant_override("outline_size", 3)
	_label.modulate.a = 0.0
	add_child(_label)


func _ready() -> void:
	Sfx.sound_played.connect(_on_sound)


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


## Sfx played `sound` (at `at` when `positional`).
func _on_sound(sound: String, at: Vector3, positional: bool) -> void:
	var text := CAPTIONS.text_for(sound, positional, _at_sea())
	if text == "":
		return
	var now := Time.get_ticks_msec() / 1000.0
	var last: float = _last.get(sound, -1000.0)
	if now - last < CAPTIONS.cooldown_for(sound, tuning.caption_cooldown):
		return
	_last[sound] = now
	var where := ""
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if positional and camera:
		where = CaptionDirector.direction(camera.global_transform, at)
	show_caption(CaptionDirector.compose(text, where))


## The sea's horror bed is playing: Rin is on the water.
func _at_sea() -> bool:
	return Sfx._bed_name.begins_with("sea")


func _show(text: String) -> void:
	current = text
	_label.text = text
	_clock = tuning.caption_seconds
	_place()
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_label, "modulate:a", 1.0, 0.2)


func _place() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport().get_visible_rect().size
	_label.size = Vector2(view.x - 120.0, 0.0)
	_label.reset_size()
	_label.size.x = view.x - 120.0
	_label.position = Vector2(60.0, view.y * 0.74 - _label.get_minimum_size().y)


func _process(delta: float) -> void:
	if current == "":
		return
	_place()
	_clock -= delta / maxf(Engine.time_scale, 0.01)
	if _clock <= 0.0:
		hide_caption()


func hide_caption() -> void:
	current = ""
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_label, "modulate:a", 0.0, tuning.fade_seconds)
