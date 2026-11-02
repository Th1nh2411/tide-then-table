extends Control
## Main menu: Continue (only if a save exists) / New Game / Hướng dẫn / Quit,
## over a living night backdrop (MainMenuBackdrop), with an animated sign title.

## Horror build: every day (new game, continue) starts in Rin's room.
const BEDROOM_SCENE_PATH: String = "res://scenes/home3d/bedroom_scene_3d.tscn"
const SWAY_DEGREES: float = 0.8

@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _quit_button: Button = %QuitButton
@onready var _status_label: Label = %StatusLabel
@onready var _sign: PanelContainer = %Sign
@onready var _backdrop: Control = %Backdrop
@onready var _buttons: VBoxContainer = %VBox

## Set after the first "New Game" press when a save exists.
var _confirm_new_game: bool = false
var _time: float = 0.0
var _next_flicker: float = 3.5


func _ready() -> void:
	Sfx.ambience("sea")
	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_dress_buttons()
	_status_label.text = ""
	_continue_button.visible = SaveSystem.has_save()
	var primary := _continue_button if _continue_button.visible else _new_game_button
	primary.theme_type_variation = &"AccentButton"
	primary.grab_focus()
	for child in _buttons.get_children() + %IconRow.get_children():
		if child is Button:
			UiFx.hover_lift(child as Button, 0.06)
	_play_intro()


## Icon + one word for the big buttons; help / sound / quit are icon-only.
func _dress_buttons() -> void:
	UiIcons.dress(_continue_button, "play", 16, UiIcons.CHALK)
	UiIcons.dress(_new_game_button, "boat", 18)
	var help := HelpPanel.new()
	add_child(help)
	var row: HBoxContainer = %IconRow
	var help_button := UiIcons.icon_button("help", "Hướng dẫn")
	help_button.pressed.connect(help.open)
	row.add_child(help_button)
	row.move_child(help_button, 0)
	var sound := UiIcons.icon_button("sound_off" if Sfx.muted else "sound_on", "Âm thanh")
	sound.pressed.connect(func() -> void:
		Sfx.set_muted(not Sfx.muted)
		sound.icon = UiIcons.sticker("sound_off" if Sfx.muted else "sound_on", 16))
	row.add_child(sound)
	row.move_child(sound, 1)
	UiIcons.dress(_quit_button, "quit", 16)
	_quit_button.custom_minimum_size = help_button.custom_minimum_size
	# Edition line: small pictures instead of a sentence (fishing at night, street food).
	var edition: HBoxContainer = %Edition
	for id: String in ["moon", "rod", "fish"]:
		edition.add_child(UiIcons.make(id, 16, UiIcons.SEA))
	edition.add_child(UiIcons.make("lantern", 16, UiIcons.CHILI))
	edition.add_child(UiIcons.make("meal", 16, UiIcons.AMBER))
	var badge := Label.new()
	badge.theme_type_variation = &"BadgeLabel"
	badge.add_theme_font_size_override("font_size", 9)
	badge.text = "3D"
	edition.add_child(badge)


## Title drops in, then the buttons slide in one by one from the left.
func _play_intro() -> void:
	var animated: Array[Control] = [%Kicker, _sign, %Edition]
	for child in _buttons.get_children():
		if child is Control and (child as Control).visible and not child is Label:
			animated.append(child as Control)
	for control in animated:
		control.modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame  # containers have placed everything
	UiFx.slide_in(%Kicker, Vector2(0, -10), 0.05)
	# The sign drops on its chains and swings to rest, a little crooked.
	UiFx.tilt(_sign, -2.0)
	_sign.pivot_offset = Vector2(_sign.size.x * 0.5, 0)
	UiFx.settle(_sign, Vector2(0, -60), 0.1)
	UiFx.slide_in(%Edition, Vector2(0, 8), 0.3)
	var i := 0
	for child in _buttons.get_children():
		var control := child as Control
		if control and control.visible and not control is Label:
			UiFx.slide_in(control, Vector2(-28, 0), 0.4 + 0.07 * i)
			i += 1


## Sign sway + light spill + a tube-light flicker now and then.
func _process(delta: float) -> void:
	_time += delta
	if _time > 1.0:
		_sign.rotation = deg_to_rad(-2.0 + sin(_time * 0.9) * SWAY_DEGREES)
	var breath := 0.85 + 0.15 * sin(_time * 1.7)
	_backdrop.set("title_glow_at", _sign.position + _sign.get_parent().position + _sign.size * Vector2(0.5, 0.55))
	_backdrop.set("title_glow_strength", breath * 0.6)
	if _time >= _next_flicker:
		_next_flicker = _time + randf_range(4.0, 8.0)
		_flicker()


func _flicker() -> void:
	var tween := create_tween()
	tween.tween_property(_sign, "self_modulate", Color(0.55, 0.5, 0.45), 0.05)
	tween.tween_property(_sign, "self_modulate", Color.WHITE, 0.05)
	tween.tween_property(_sign, "self_modulate", Color(0.7, 0.65, 0.6), 0.04)
	tween.tween_property(_sign, "self_modulate", Color(1.15, 1.1, 1.0), 0.08)
	tween.tween_property(_sign, "self_modulate", Color.WHITE, 0.3)


func _on_continue_pressed() -> void:
	if not SaveSystem.load_game():
		_status_label.text = "Bản lưu bị lỗi. Hãy chơi mới."
		UiFx.shake(_status_label)
		_continue_button.hide()
		_new_game_button.theme_type_variation = &"AccentButton"
		_new_game_button.grab_focus()
		return
	SceneRouter.go_to(BEDROOM_SCENE_PATH)


func _on_new_game_pressed() -> void:
	# The old save is overwritten when day 1 starts, so ask once first.
	if SaveSystem.has_save() and not _confirm_new_game:
		_confirm_new_game = true
		_new_game_button.text = "Bấm lần nữa?"
		_new_game_button.theme_type_variation = &"AccentButton"
		_status_label.text = "Xóa bản lưu ngày %d!" % _saved_day()
		UiFx.shake(_new_game_button)
		UiFx.pop_in(_status_label)
		return
	GameState.reset()
	SceneRouter.go_to(BEDROOM_SCENE_PATH)  # mùng 9, Rin wakes in his room


func _saved_day() -> int:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)) == OK and json.data is Dictionary:
		var day: Variant = json.data.get("day")
		if day is float or day is int:
			return int(day)
	return 0


func _on_quit_pressed() -> void:
	SceneRouter.quit_game()
