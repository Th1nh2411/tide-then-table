class_name SettingsPanel
extends CanvasLayer
## "Cài đặt": mouse sensitivity, invert Y, volume, mute, PS1 look, fullscreen,
## one-frame flashes
## (GameSettings, saved at once) + the list of keys. Opened from the main
## menu and the pause menu; works while paused; Esc closes. Built in code.

signal closed

const KEYS: Array[Array] = [
	["W A S D", "đi / chèo thúng"], ["Chuột", "nhìn quanh"],
	["Chuột trái", "quăng câu, giữ để kéo"], ["E", "lấy, mở, hỏi"],
	["R", "lên bờ (ở bến)"], ["F", "vá thúng (ở bến)"], ["N", "sổ tay"],
	["Alt", "hiện con trỏ"], ["Esc", "tạm dừng"], ["F11", "toàn màn hình"],
]

var _panel: PanelContainer
var _first: Control
var _toggles: Dictionary = {}  # key -> Button


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func open() -> void:
	_sync()
	show()
	_first.grab_focus()
	UiFx.pop_in(_panel)


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", HorrorUi.panel_style())
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	box.add_child(HorrorUi.label("cài đặt", 16, HorrorUi.LAMP))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	box.add_child(columns)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 5)
	columns.add_child(grid)
	_first = _add_slider(grid, "Độ nhạy chuột", GameSettings.SENSITIVITY_MIN, GameSettings.SENSITIVITY_MAX, 0.05,
		GameSettings.mouse_sensitivity(), func(v: float) -> void:
			GameSettings.set_value("controls", "mouse_sensitivity", v),
		func(v: float) -> String: return "%.2fx" % v)
	_add_toggle(grid, "invert_y", "Đảo trục dọc", func(on: bool) -> void:
		GameSettings.set_value("controls", "invert_y", on))
	_add_slider(grid, "Âm lượng", 0.0, 1.0, 0.05, GameSettings.volume(), GameSettings.set_volume,
		func(v: float) -> String: return "%d%%" % roundi(v * 100.0))
	_add_toggle(grid, "muted", "Tắt tiếng", GameSettings.set_muted)
	_add_toggle(grid, "psx", "Đồ hoạ PS1", GameSettings.set_psx)
	_add_toggle(grid, "fullscreen", "Toàn màn hình", GameSettings.set_fullscreen)
	_add_toggle(grid, "flash", "Hiệu ứng nhấp nháy", GameSettings.set_flash_effects)
	columns.add_child(_keys_column())
	var done := HorrorUi.button("Xong", 12)
	done.alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.size_flags_horizontal = Control.SIZE_SHRINK_END
	done.custom_minimum_size.x = 80
	done.pressed.connect(close)
	box.add_child(done)


func _add_slider(grid: GridContainer, text: String, low: float, high: float, step: float,
		value: float, on_change: Callable, shown: Callable) -> HSlider:
	grid.add_child(_row_label(text))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	grid.add_child(row)
	var slider := HorrorUi.slider(low, high, step)
	slider.value = value
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var readout := HorrorUi.label(str(shown.call(value)), 10, HorrorUi.DIM)
	readout.custom_minimum_size.x = 34
	row.add_child(readout)
	slider.value_changed.connect(func(v: float) -> void:
		readout.text = str(shown.call(v))
		on_change.call(v))
	return slider


func _add_toggle(grid: GridContainer, key: String, text: String, on_change: Callable) -> void:
	grid.add_child(_row_label(text))
	var button := HorrorUi.button("", 11)
	button.toggle_mode = true
	button.custom_minimum_size.x = 60
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.toggled.connect(func(on: bool) -> void:
		button.text = "Bật" if on else "Tắt"
		on_change.call(on))
	grid.add_child(button)
	_toggles[key] = button


func _row_label(text: String) -> Label:
	var l := HorrorUi.label(text)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


## Re-read toggles (F11 / F8 may have changed them) without re-saving.
func _sync() -> void:
	var values := {"invert_y": GameSettings.invert_y(), "muted": GameSettings.muted(),
		"psx": GameSettings.psx(), "fullscreen": GameSettings.fullscreen(),
		"flash": GameSettings.flash_effects()}
	for key: String in _toggles:
		var button: Button = _toggles[key]
		var on: bool = values[key]
		button.set_pressed_no_signal(on)
		button.text = "Bật" if on else "Tắt"


## The key list, drawn like the in-game prompt (InteractPrompt, steady).
func _keys_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.add_child(HorrorUi.label("phím", 11, HorrorUi.DIM))
	for pair: Array in KEYS:
		column.add_child(InteractPrompt.new(str(pair[1]), str(pair[0]), true))
	return column
