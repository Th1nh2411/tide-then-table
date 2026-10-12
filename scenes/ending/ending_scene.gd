extends Control
## MVP ending: white screen, Rin's lines appear one by one, then "Còn tiếp...";
## the lines then give way to a short card about the run (EndingStats) and a
## thank-you for playtesters. Any key / click after that returns to the main menu.

const MAIN_MENU_PATH: String = "res://scenes/main_menu/main_menu.tscn"

@export_multiline var lines: Array[String] = [
	"...Nước đang xoáy ngược chiều gió.",
	"App vẫn báo lỗi: tọa độ này không tồn tại trên bản đồ.",
	"Cái phao kia gắn đèn đỏ... in chữ THÂM LAM. Ai thả nó ở đây?",
	"Ông nội từng kể về một vùng biển nằm bên dưới mặt biển.",
	"Có bug thì phải debug. Mình phải xuống xem cho rõ.",
]
@export var line_fade_seconds: float = 0.8
@export var seconds_between_lines: float = 1.6
## Shown under the run card (the playtest build's thank-you / where to send feedback).
@export var thanks_text: String = "Cảm ơn bạn đã chơi thử bản đầu! Góp ý gì cũng quý."
@export var fish_catalog: FishCatalog

var _can_leave: bool = false

@onready var _lines_box: VBoxContainer = %LinesBox
@onready var _to_be_continued: Label = %ToBeContinuedLabel
@onready var _hint_label: Label = %HintLabel


func _ready() -> void:
	Sfx.ambience("")
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
	await get_tree().create_timer(seconds_between_lines).timeout
	await _show_run_card()
	await _fade_in(_hint_label)
	_can_leave = true


## Rin's lines fade out; the run's numbers + the thank-you fade in instead.
func _show_run_card() -> void:
	var tween := create_tween()
	tween.tween_property(_lines_box, "modulate:a", 0.0, line_fade_seconds)
	await tween.finished
	for child in _lines_box.get_children():
		child.queue_free()
	_lines_box.modulate.a = 1.0
	var total := fish_catalog.fish.size() if fish_catalog else 0
	var card: Array[Label] = []
	for text in EndingStats.lines(total):
		card.append(_card_label(text, Color(0.15, 0.2, 0.25), 14))
	card.append(_card_label(thanks_text, Color(0.1, 0.35, 0.4), 11))
	for label in card:
		_lines_box.add_child(label)
	for label in card:
		await _fade_in(label)


func _card_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate.a = 0.0
	return label


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
