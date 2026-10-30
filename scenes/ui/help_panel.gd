class_name HelpPanel
extends CanvasLayer
## "Hướng dẫn" screen: every control in one place as key caps + short
## captions grouped under icons (content in HelpEntries), opened from the
## pause menu and the main menu. In-game hints are first-time pointers;
## this is where the player looks after that. Works while paused. Built in code.

signal closed

var _content: HelpGridView
var _scroll: ScrollContainer
var _panel: PanelContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func open() -> void:
	show()
	_show_section(0)
	UiFx.pop_in(_panel)


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		close()


func _show_section(index: int) -> void:
	_content.show_tab(HelpEntries.TABS[index])
	_scroll.scroll_vertical = 0
	for i in _buttons.size():
		_buttons[i].button_pressed = i == index


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.09, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ChalkPanel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 24
	_panel.offset_top = 14
	_panel.offset_right = -24
	_panel.offset_bottom = -14
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)
	header.add_child(UiIcons.make("help", 18, UiIcons.GOLD))
	var title := Label.new()
	title.text = "HƯỚNG DẪN"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_font_size_override("font_size", 16)
	header.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size.x = 6
	header.add_child(gap)
	for i in HelpEntries.TABS.size():
		var tab: Dictionary = HelpEntries.TABS[i]
		var button := Button.new()
		button.text = str(tab["tab"])
		UiIcons.dress(button, str(tab["icon"]), 12)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.theme_type_variation = &"ChipButton"
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_show_section.bind(i))
		UiFx.hover_lift(button, 0.06)
		header.add_child(button)
		_buttons.append(button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := UiIcons.icon_button("close", "Đóng (Esc)", 12)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var rule := ColorRect.new()
	rule.color = Color(0.92, 0.93, 0.91, 0.35)  # chalk line
	rule.custom_minimum_size.y = 1
	box.add_child(rule)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_content = HelpGridView.new()
	_scroll.add_child(_content)
