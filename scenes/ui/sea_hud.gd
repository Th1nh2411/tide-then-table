class_name SeaHud
extends CanvasLayer
## Sea screen HUD: day + night clock, lamp oil, nets, hull, prompts, tips.

@export var warning_color: Color = Color(1.0, 0.85, 0.3)
@export var late_color: Color = Color(1.0, 0.4, 0.35)
@export var flash_seconds: float = 1.5

var _message_token: int = 0

@onready var _clock_label: Label = %ClockLabel
@onready var _warning_label: Label = %WarningLabel
@onready var _prompt_label: Label = %PromptLabel
@onready var _message_label: Label = %MessageLabel
@onready var _net_label: Label = %NetLabel
@onready var _oil_label: Label = %OilLabel
@onready var _hull_label: Label = %HullLabel
@onready var _tip_label: Label = %TipLabel
@onready var _money_label: Label = %MoneyLabel


func _ready() -> void:
	DayClock.time_changed.connect(_on_time_changed)
	hide_prompt()
	_message_label.hide()
	_tip_label.hide()
	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)
	_on_time_changed(DayClock.current_minutes)


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
	_money_label.text = "%dk   [J] điện thoại" % money


## Persistent tutorial tip (bottom-left) until replaced or hidden.
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


func _on_time_changed(_minutes: float) -> void:
	_clock_label.text = "Đêm %d   %s" % [GameState.day, DayClock.get_time_text()]
