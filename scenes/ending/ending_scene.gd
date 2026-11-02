extends Control
## MVP ending: white screen, Rin's lines appear one by one, then "Còn tiếp...";
## the lines then give way to a short card about the run (EndingStats) and a
## thank-you for playtesters, as a taped newspaper clipping (RunClipping)
## with a "CÒN TIẾP" stamp. Any key / click after that returns to the main menu.
## After đêm rằm (RamNight.ending_id()) the lines are that ending's card,
## shown as narration over that ending's painting (EndingPainting, lower
## third, outlined); the painting dims for the run card.

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
var _narration := false
var _dark := false
var _painting: EndingPainting

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
	_use_ram_card()
	_play()


## Đêm rằm's ending card instead of the old lines.
func _use_ram_card() -> void:
	var id := RamNight.ending_id()
	if id == "":
		return
	var card: RamLinesData = RamFx3D.LINES
	_narration = true
	lines = card.card_drowned if id == "drowned" else card.card_true
	_to_be_continued.text = card.card_title_drowned if id == "drowned" else card.card_title_true
	if id == "drowned":
		_dark = true
		($White as ColorRect).color = Color("0d1114")
		_to_be_continued.add_theme_color_override("font_color", Color("9fe6e0"))
	_painting = EndingPainting.add(self, id)
	if _painting:
		_dark = true
		($White as ColorRect).color = Color.BLACK
		var box := $CenterContainer as Control
		box.anchor_top = 0.62  # the lines sit over the painting's lower third
		box.anchor_bottom = 1.0
		EndingPainting.outline(_to_be_continued, Color("9fe6e0") if id == "drowned" else Color("f3e3c0"))


func _play() -> void:
	if _painting:
		await _painting.fade_in()
	else:
		await get_tree().create_timer(1.0).timeout
	for text in lines:
		var label := Label.new()
		label.text = text if _narration else "Rin: " + text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_type_variation = &"InkLabel"
		if _painting:
			EndingPainting.outline(label, Color("ece6d8"))
		elif _dark:
			label.add_theme_color_override("font_color", Color("d8d2c4"))
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
	if _painting:
		await _painting.dim()
		($CenterContainer as Control).anchor_top = 0.0
		($CenterContainer as Control).anchor_bottom = 1.0
		EndingPainting.outline(_hint_label, Color("ece6d8"))
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
