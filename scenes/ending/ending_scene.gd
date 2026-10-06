extends Control
## MVP ending: white screen, Rin's lines appear one by one, then "Còn tiếp...".
## Any key / click after that returns to the main menu.

const MAIN_MENU_PATH: String = "res://scenes/main_menu/main_menu.tscn"

@export_multiline var lines: Array[String] = [
	"...Nước đang xoáy ngược chiều gió.",
	"App vẫn báo lỗi: tọa độ này không tồn tại trên bản đồ.",
	"Ông nội từng kể về một vùng biển nằm bên dưới mặt biển.",
	"Có bug thì phải debug. Mình phải xuống xem cho rõ.",
]
@export var line_fade_seconds: float = 0.8
@export var seconds_between_lines: float = 1.6

var _can_leave: bool = false

@onready var _lines_box: VBoxContainer = %LinesBox
@onready var _to_be_continued: Label = %ToBeContinuedLabel
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	_to_be_continued.modulate.a = 0.0
	_hint_label.modulate.a = 0.0
	_play()


func _play() -> void:
	await get_tree().create_timer(1.0).timeout
	for text in lines:
		var label := Label.new()
		label.text = "Rin: " + text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.25))
		label.modulate.a = 0.0
		_lines_box.add_child(label)
		await _fade_in(label)
		await get_tree().create_timer(seconds_between_lines).timeout
	await _fade_in(_to_be_continued)
	await _fade_in(_hint_label)
	_can_leave = true


func _fade_in(node: CanvasItem) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, line_fade_seconds)
	await tween.finished


func _unhandled_input(event: InputEvent) -> void:
	if not _can_leave:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_can_leave = false
		SceneRouter.go_to(MAIN_MENU_PATH, Color.WHITE)
