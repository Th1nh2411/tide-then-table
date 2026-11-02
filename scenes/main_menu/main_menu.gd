extends Control
## Main menu of the horror build: the key art (slow push-in, the pier lamp
## flickers), "RIN" + subtitle in its dark left third, then Tiếp tục (only
## with a save) / Chơi mới (press twice over a save) / Cài đặt / Thoát.

## Every day (new game, continue) starts in Rin's room.
const BEDROOM_SCENE_PATH: String = "res://scenes/home3d/bedroom_scene_3d.tscn"
## Where the pier lamp sits in the key art (share of width / height).
const LAMP_AT := Vector2(0.751, 0.462)
## Push-in: zoom reached after PUSH_SECONDS, then back (ping-pong).
const PUSH_ZOOM: float = 1.07
const PUSH_SECONDS: float = 40.0

var _art: TextureRect
var _lamp: TextureRect
var _title: Label
var _subtitle: Label
var _buttons: VBoxContainer
var _continue_button: Button
var _new_game_button: Button
var _status: Label
var _settings: SettingsPanel
## Set after the first "Chơi mới" press when a save exists.
var _confirm_new_game: bool = false
var _time: float = 0.0
var _next_flicker: float = 2.5


func _ready() -> void:
	Sfx.ambience("sea")
	Sfx.bed("sea")
	MainMenuView.build(self)
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.closed.connect(_focus_first)
	_continue_button = _add_button("Tiếp tục", _on_continue_pressed)
	_new_game_button = _add_button("Chơi mới", _on_new_game_pressed)
	_add_button("Cài đặt", _settings.open)
	_add_button("Thoát", SceneRouter.quit_game)
	_buttons.add_child(_status)
	_continue_button.visible = SaveSystem.has_save()
	_focus_first()
	_play_intro()


## Called by MainMenuView: the nodes it built.
func set_parts(art: TextureRect, lamp: TextureRect, title: Label, subtitle: Label,
		buttons: VBoxContainer, status: Label) -> void:
	_art = art
	_lamp = lamp
	_title = title
	_subtitle = subtitle
	_buttons = buttons
	_status = status


func _add_button(text: String, action: Callable) -> Button:
	var button := HorrorUi.button(text, 14)
	button.custom_minimum_size = Vector2(150, 0)
	button.pressed.connect(action)
	_buttons.add_child(button)
	return button


func _focus_first() -> void:
	(_continue_button if _continue_button.visible else _new_game_button).grab_focus()


## Title fades up out of the dark, then the buttons one by one.
func _play_intro() -> void:
	var parts: Array[Control] = [_title, _subtitle]
	for child in _buttons.get_children():
		parts.append(child as Control)
	for part in parts:
		part.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.4)
	for part in parts:
		tween.tween_property(part, "modulate:a", 1.0, 0.9 if part == _title else 0.35)


## Slow push-in + the pier lamp breathing, with a stutter now and then.
func _process(delta: float) -> void:
	_time += delta
	var t := 0.5 - 0.5 * cos(_time / PUSH_SECONDS * PI)
	_art.pivot_offset = _art.size * Vector2(0.62, 0.45)
	_art.scale = Vector2.ONE * lerpf(1.0, PUSH_ZOOM, t)
	var lamp_size := _art.size.y * 0.42
	_lamp.size = Vector2.ONE * lamp_size
	_lamp.position = _art.size * LAMP_AT - _lamp.size * 0.5
	if _lamp.get_meta("stutter", false):
		return
	_lamp.modulate.a = 0.55 + 0.08 * sin(_time * 2.3) + 0.05 * sin(_time * 7.1)
	if _time >= _next_flicker:
		_next_flicker = _time + randf_range(3.0, 7.0)
		_stutter()


func _stutter() -> void:
	_lamp.set_meta("stutter", true)
	var tween := create_tween()
	for a: float in [0.15, 0.6, 0.05, 0.5, 0.25, 0.6]:
		tween.tween_property(_lamp, "modulate:a", a, randf_range(0.03, 0.08))
	tween.tween_callback(_lamp.set_meta.bind("stutter", false))


func _on_continue_pressed() -> void:
	if not SaveSystem.load_game():
		_status.text = "Bản lưu bị lỗi. Hãy chơi mới."
		UiFx.shake(_status)
		_continue_button.hide()
		_new_game_button.grab_focus()
		return
	SceneRouter.go_to(BEDROOM_SCENE_PATH)


func _on_new_game_pressed() -> void:
	# The old save is overwritten when day 1 starts, so ask once first.
	if SaveSystem.has_save() and not _confirm_new_game:
		_confirm_new_game = true
		_new_game_button.text = "Bấm lần nữa?"
		_status.text = "Xoá bản lưu: %s" % LoopCalendar.date_text(_saved_day())
		UiFx.shake(_new_game_button)
		return
	GameState.reset()
	SceneRouter.go_to(BEDROOM_SCENE_PATH)  # mùng 9, Rin wakes in his room


func _saved_day() -> int:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)) == OK and json.data is Dictionary:
		var day: Variant = (json.data as Dictionary).get("day")
		if day is float or day is int:
			return int(day)
	return 1
