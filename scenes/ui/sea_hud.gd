class_name SeaHud
extends CanvasLayer
## Sea screen HUD: day + night clock, lamp oil, nets, hull, prompts, tips,
## and the dock buttons (unload / go home) pinned while the boat is docked —
## the night only ends when the player presses "go home".

signal unload_pressed
signal go_home_pressed

@export var warning_color: Color = Color(1.0, 0.85, 0.3)
@export var late_color: Color = Color(1.0, 0.4, 0.35)
@export var flash_seconds: float = 1.5

var _message_token: int = 0
## Tonight's weather name, shown next to the clock.
var _weather_name: String = ""
var _dock_panel: PanelContainer
var _unload_button: Button
var _home_button: Button

@onready var _clock_label: Label = %ClockLabel
@onready var _warning_label: Label = %WarningLabel
@onready var _prompt_label: Label = %PromptLabel
@onready var _message_label: Label = %MessageLabel
@onready var _net_label: Label = %NetLabel
@onready var _oil_label: Label = %OilLabel
@onready var _hull_label: Label = %HullLabel
@onready var _tip_label: Label = %TipLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _order_label: Label = %OrderLabel


func _ready() -> void:
	DayClock.time_changed.connect(_on_time_changed)
	hide_prompt()
	_message_label.hide()
	_tip_label.hide()
	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)
	_on_time_changed(DayClock.current_minutes)
	_build_dock_panel()


## Pinned dock buttons (shown while docked).
func show_dock(hold_count: int, nets_out: int) -> void:
	_unload_button.text = "Dỡ %d con vào kho" % hold_count if hold_count > 0 else "Khoang trống"
	_unload_button.disabled = hold_count == 0
	_home_button.text = "Về nhà ngủ  →" if nets_out == 0 else "Về nhà ngủ (bỏ %d lưới)  →" % nets_out
	_dock_panel.show()


func hide_dock() -> void:
	_dock_panel.hide()


func _build_dock_panel() -> void:
	_dock_panel = PanelContainer.new()
	_dock_panel.anchor_left = 1.0
	_dock_panel.anchor_right = 1.0
	_dock_panel.anchor_top = 1.0
	_dock_panel.anchor_bottom = 1.0
	_dock_panel.offset_left = -170
	_dock_panel.offset_top = -78
	_dock_panel.offset_right = -6
	_dock_panel.offset_bottom = -6
	add_child(_dock_panel)
	var box := VBoxContainer.new()
	_dock_panel.add_child(box)
	var title := Label.new()
	title.text = "BẾN"
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	box.add_child(title)
	_unload_button = _dock_button(unload_pressed)
	box.add_child(_unload_button)
	_home_button = _dock_button(go_home_pressed)
	box.add_child(_home_button)
	_dock_panel.hide()


func _dock_button(pressed: Signal) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	button.pressed.connect(pressed.emit)
	return button


func set_oil(amount: float, capacity: float) -> void:
	var fraction := amount / capacity
	_oil_label.text = "Dầu đèn %d%%" % roundi(fraction * 100.0)
	_oil_label.modulate = late_color if fraction <= 0.25 else (warning_color if fraction <= 0.5 else Color.WHITE)
	if fraction <= 0.25:
		_warning_label.text = "Dầu sắp cạn! Về bến trước khi tắt đèn"
		_warning_label.modulate = late_color
		_warning_label.show()
	else:
		_warning_label.hide()


func set_nets(available: int, total: int) -> void:
	_net_label.text = "Lưới %d/%d  [Q] thả" % [available, total]


func _on_money_changed(money: int) -> void:
	_money_label.text = "%dk" % money


## Persistent tutorial tip (bottom-left) until replaced or hidden.
## Active fish orders under the money (one line each), hidden when none.
func set_orders(lines: PackedStringArray) -> void:
	_order_label.text = "\n".join(lines)
	_order_label.visible = not lines.is_empty()


func show_tip(text: String) -> void:
	_tip_label.text = text
	_tip_label.show()


func set_hull(hp: float, critical: bool) -> void:
	_hull_label.text = "Thân thuyền %d%%" % roundi(hp)
	_hull_label.modulate = late_color if critical else Color.WHITE


## Context hint at the bottom of the screen, e.g. "E: Cập bến".
func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.show()


func hide_prompt() -> void:
	_prompt_label.hide()


## Big centered message, e.g. when the boat gets towed.
func show_message(text: String) -> void:
	_message_token += 1
	_message_label.text = text
	_message_label.show()


## Centered message that hides itself after `seconds`.
func flash_message(text: String, seconds: float = flash_seconds) -> void:
	show_message(text)
	# Token check: a newer message must not be hidden by an older timer.
	var token := _message_token
	await get_tree().create_timer(seconds).timeout
	if token == _message_token:
		_message_label.hide()


func set_weather(weather_name: String) -> void:
	_weather_name = weather_name
	_on_time_changed(DayClock.current_minutes)


func _on_time_changed(_minutes: float) -> void:
	var weather := "  · %s" % _weather_name if _weather_name else ""
	_clock_label.text = "Đêm %d   %s%s" % [GameState.day, DayClock.get_time_text(), weather]
