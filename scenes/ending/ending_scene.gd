extends Control
## MVP ending: white screen, Rin's lines appear one by one, then "Còn tiếp...";
## the lines then give way to a short card about the run (EndingStats) and a
## thank-you for playtesters, as a taped newspaper clipping (RunClipping)
## with a "CÒN TIẾP" stamp. Any key / click after that returns to the main menu.

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
	_to_be_continued.theme_type_variation = &"HeadingLabel"
	_hint_label.modulate.a = 0.0
	_hint_label.theme_type_variation = &"KeyLabel"
	_hint_label.text = "Space"
	_hint_label.tooltip_text = "Bấm phím bất kỳ để về màn hình chính"
	var home := UiIcons.make("house", 12, Color("394a50"))
	_hint_label.add_sibling(home)
	home.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home.modulate.a = 0.0
	_hint_label.set_meta("home", home)
	_hint_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play()


func _play() -> void:
	await get_tree().create_timer(1.0).timeout
	for text in lines:
		var label := Label.new()
		label.text = "Rin: " + text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_type_variation = &"InkLabel"
		label.modulate.a = 0.0
		_lines_box.add_child(label)
		await _fade_in(label)
		await get_tree().create_timer(seconds_between_lines).timeout
	await _fade_in(_to_be_continued)
	await get_tree().create_timer(seconds_between_lines).timeout
	await _show_run_card()
	_fade_in(_hint_label.get_meta("home") as CanvasItem)
	await _fade_in(_hint_label)
	_can_leave = true


## Rin's lines fade out; the run's numbers + the thank-you fade in instead.
func _show_run_card() -> void:
	var tween := create_tween()
	tween.tween_property(_lines_box, "modulate:a", 0.0, line_fade_seconds)
	await tween.finished
	for child in _lines_box.get_children():
		child.queue_free()
	_to_be_continued.hide()  # the clipping's stamp says it now
	_lines_box.modulate.a = 1.0
	var total := fish_catalog.fish.size() if fish_catalog else 0
	var clipping := RunClipping.new()
	clipping.setup(EndingStats.values(total), thanks_text)
	clipping.tooltip_text = "\n".join(EndingStats.lines(total))
	_lines_box.add_child(clipping)
	await get_tree().process_frame
	await clipping.reveal()


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
