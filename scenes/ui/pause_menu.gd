class_name PauseMenu
extends CanvasLayer
## Esc menu for the sea and the restaurant: resume, then icon buttons for
## Hướng dẫn (HelpPanel) / sound / main menu / quit (tooltips name them).
## Runs while paused (PROCESS_MODE_ALWAYS in the scene).
## Put it BEFORE other overlays in the tree: later nodes get input first, so
## e.g. the hold window can use Esc to close itself before this opens.

const MAIN_MENU_PATH: String = "res://scenes/main_menu/main_menu.tscn"
const SAVE_NOTE: String = "Tự lưu khi ra khơi, về bến"

var _confirm_menu: bool = false

@onready var _resume_button: Button = %ResumeButton
@onready var _menu_button: Button = %MenuButton
@onready var _quit_button: Button = %QuitButton
@onready var _note_label: Label = %NoteLabel
@onready var _info: HBoxContainer = %Info
@onready var _panel: PanelContainer = %Panel
@onready var _dim: ColorRect = %Dim
@onready var _icons: HBoxContainer = %IconRow

var _help: HelpPanel


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(_resume)
	_menu_button.pressed.connect(_on_menu_pressed)
	_quit_button.pressed.connect(SceneRouter.quit_game)
	UiIcons.dress(_resume_button, "play", 14, UiIcons.CHALK)
	_help = HelpPanel.new()
	add_child(_help)
	_help.closed.connect(_resume_button.grab_focus)
	var help_button := UiIcons.icon_button("help", "Hướng dẫn")
	help_button.pressed.connect(_help.open)
	_icons.add_child(help_button)
	_icons.move_child(help_button, 0)
	var sound_button := UiIcons.icon_button(_sound_icon(), "Âm thanh")
	sound_button.pressed.connect(func() -> void:
		Sfx.set_muted(not Sfx.muted)
		sound_button.icon = UiIcons.sticker(_sound_icon(), 16))
	_icons.add_child(sound_button)
	_icons.move_child(sound_button, 1)
	for pair: Array in [[_menu_button, "house"], [_quit_button, "quit"]]:
		var button: Button = pair[0]
		UiIcons.dress(button, str(pair[1]), 16)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = help_button.custom_minimum_size
	for button in [_resume_button] + _icons.get_children():
		UiFx.hover_lift(button as Control, 0.06)


func _sound_icon() -> String:
	return "sound_off" if Sfx.muted else "sound_on"


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		get_viewport().set_input_as_handled()
		_resume()
	elif not get_tree().paused:
		# Something else (hold overflow, hold mid-fishing) owns the pause: leave it.
		get_viewport().set_input_as_handled()
		_open()


func _open() -> void:
	_confirm_menu = false
	_menu_button.theme_type_variation = &""
	_note_label.text = SAVE_NOTE
	_note_label.remove_theme_color_override("font_color")
	_fill_info()
	get_tree().paused = true
	show()
	_resume_button.grab_focus()
	_dim.modulate.a = 0.0
	var fade := _dim.create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(_dim, "modulate:a", 1.0, 0.18)
	UiFx.pop_in(_panel)
	UiFx.stagger(_icons, 0.05, 0.2)
	var sign: Control = %Sign
	UiFx.tilt(sign, -2.5)
	UiFx.stamp(sign, _panel, 0.12)


## Day and time as icon + number.
func _fill_info() -> void:
	for child in _info.get_children():
		_info.remove_child(child)
		child.queue_free()
	_info.add_child(UiIcons.pair("calendar", "Ngày %d" % GameState.day, 12, UiIcons.SEA))
	_info.add_child(UiIcons.pair("clock", DayClock.get_time_text(), 12, UiIcons.SEA))


func _resume() -> void:
	hide()
	get_tree().paused = false


## Two presses: leaving loses everything since this morning's autosave.
func _on_menu_pressed() -> void:
	if not _confirm_menu:
		_confirm_menu = true
		_menu_button.theme_type_variation = &"AccentButton"
		_note_label.text = "Bấm lần nữa: mất tiến độ đêm nay"
		_note_label.add_theme_color_override("font_color", Color("f0a08a"))
		UiFx.shake(_menu_button)
		return
	get_tree().paused = false
	hide()
	SceneRouter.go_to(MAIN_MENU_PATH)
