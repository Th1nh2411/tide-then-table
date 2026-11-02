class_name PauseMenu
extends CanvasLayer
## Esc menu in every 3D place: Tiếp tục / Cài đặt (SettingsPanel) / Về menu
## (press twice) / Thoát. The sea and the restaurant add it themselves,
## SceneRouter adds it to the other 3D scenes. Runs while paused. Built in code.

const GROUP := &"pause_menu"
const SCENE_PATH := "res://scenes/ui/pause_menu.tscn"
const MAIN_MENU_PATH: String = "res://scenes/main_menu/main_menu.tscn"
const SAVE_NOTE: String = "Tự lưu mỗi sáng khi tỉnh dậy"

var _confirm_menu: bool = false
var _dim: ColorRect
var _panel: PanelContainer
var _date: Label
var _note: Label
var _resume_button: Button
var _menu_button: Button
var _settings: SettingsPanel


func _ready() -> void:
	add_to_group(GROUP)
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_settings = SettingsPanel.new()
	add_child(_settings)
	_settings.closed.connect(func() -> void: _panel.show(); _resume_button.grab_focus())
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or _settings.visible:
		return
	if visible:
		get_viewport().set_input_as_handled()
		_resume()
	elif not get_tree().paused:
		# Something else (a paper, a dialogue) owns the pause: leave it.
		get_viewport().set_input_as_handled()
		_open()


func _open() -> void:
	_confirm_menu = false
	_menu_button.text = "Về menu"
	_note.text = SAVE_NOTE
	_note.add_theme_color_override("font_color", HorrorUi.DIM)
	_date.text = LoopCalendar.date_text(GameState.day)
	get_tree().paused = true
	show()
	_panel.show()
	_resume_button.grab_focus()
	_dim.modulate.a = 0.0
	var fade := _dim.create_tween()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(_dim, "modulate:a", 1.0, 0.18)
	UiFx.pop_in(_panel)


func _resume() -> void:
	hide()
	get_tree().paused = false


func _open_settings() -> void:
	_panel.hide()
	_settings.open()


## Two presses: leaving loses everything since this morning's autosave.
func _on_menu_pressed() -> void:
	if not _confirm_menu:
		_confirm_menu = true
		_menu_button.text = "Bấm lần nữa"
		_note.text = "Mất tiến độ từ sáng nay"
		_note.add_theme_color_override("font_color", HorrorUi.BLOOD)
		UiFx.shake(_menu_button)
		return
	get_tree().paused = false
	hide()
	SceneRouter.go_to(MAIN_MENU_PATH)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.62)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", HorrorUi.panel_style())
	_panel.custom_minimum_size.x = 170
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_panel.add_child(box)
	box.add_child(HorrorUi.label("TẠM DỪNG", 16, HorrorUi.LAMP))
	_date = HorrorUi.label("", 10, HorrorUi.DIM)
	box.add_child(_date)
	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	box.add_child(gap)
	_resume_button = _add_button(box, "Tiếp tục", _resume)
	_add_button(box, "Cài đặt", _open_settings)
	_menu_button = _add_button(box, "Về menu", _on_menu_pressed)
	_add_button(box, "Thoát", SceneRouter.quit_game)
	_note = HorrorUi.label(SAVE_NOTE, 9, HorrorUi.DIM)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_note)


func _add_button(box: VBoxContainer, text: String, action: Callable) -> Button:
	var button := HorrorUi.button(text)
	button.pressed.connect(action)
	box.add_child(button)
	return button
