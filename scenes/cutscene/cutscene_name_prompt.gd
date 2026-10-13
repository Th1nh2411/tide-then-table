class_name CutsceneNamePrompt
extends CanvasLayer
## The cutscene's "name the cat" box (`name_pet`): `await ask(default)`.

signal _entered(text: String)

@export var max_length: int = 12


func _ready() -> void:
	layer = 26
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := Label.new()
	label.text = "Đặt tên cho bé mèo:"
	label.add_theme_font_size_override("font_size", 11)
	box.add_child(label)
	var edit := LineEdit.new()
	edit.name = "NameEdit"
	edit.max_length = max_length
	edit.custom_minimum_size = Vector2(160, 0)
	edit.text_submitted.connect(_entered.emit)
	box.add_child(edit)
	var ok := Button.new()
	ok.text = "Xong (Enter)"
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(func() -> void: _entered.emit(edit.text))
	box.add_child(ok)
	hide()


func ask(default_name: String) -> String:
	var edit := find_child("NameEdit", true, false) as LineEdit
	edit.text = default_name
	show()
	edit.grab_focus()
	edit.select_all()
	var entered: String = await _entered
	hide()
	entered = entered.strip_edges().left(max_length)
	return entered if entered != "" else default_name
