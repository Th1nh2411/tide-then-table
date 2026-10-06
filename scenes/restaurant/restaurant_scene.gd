extends Control
## Restaurant screen (side view). Runs the selling shift: the length comes
## from the sea trip (late return = shorter shift). Shows money, shift time
## and storage, and a simple summary when the shift ends.
## Phase 7 replaces the summary with the full day summary + upgrade shop.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

## Full selling shift length in real seconds when back on time.
@export var base_shift_seconds: float = 180.0
@export var message_seconds: float = 1.5

var _time_left: float = 0.0
var _shift_running: bool = false
var _earned_today: int = 0
var _served: int = 0
var _left_angry: int = 0
var _message_token: int = 0

@onready var _customers: CustomerManager = $CustomerManager
@onready var _top_label: Label = %TopLabel
@onready var _storage_label: Label = %StorageLabel
@onready var _message_label: Label = %MessageLabel
@onready var _summary_panel: Control = %SummaryPanel
@onready var _summary_label: Label = %SummaryLabel
@onready var _next_day_button: Button = %NextDayButton


func _ready() -> void:
	_summary_panel.hide()
	_message_label.hide()
	_customers.customer_served.connect(_on_customer_served)
	_customers.customer_left_angry.connect(_on_customer_left_angry)
	_customers.storage_changed.connect(_refresh_storage)
	_customers.message_requested.connect(_show_message)
	_next_day_button.pressed.connect(_on_next_day_pressed)

	_time_left = get_shift_seconds()
	_shift_running = true
	_customers.start_shift()
	var late_text := ""
	if GameState.was_towed:
		late_text = " (bị kéo về, ca bán ngắn nhất)"
	elif GameState.shift_ratio < 1.0:
		late_text = " (về trễ, ca bán còn %d%%)" % roundi(GameState.shift_ratio * 100)
	_show_message("Quán mở cửa!" + late_text)
	_refresh_storage()


func get_shift_seconds() -> float:
	return base_shift_seconds * GameState.shift_ratio


func _process(delta: float) -> void:
	if _shift_running:
		_time_left = maxf(_time_left - delta, 0.0)
		if _time_left <= 0.0:
			_end_shift()
	_top_label.text = "Ngày %d   Ca còn %d:%02d   Tiền %dk (hôm nay +%dk)" % [
		GameState.day, int(_time_left) / 60, int(_time_left) % 60, GameState.money, _earned_today]


func _end_shift() -> void:
	_shift_running = false
	_customers.stop_shift()
	_show_message("Hết giờ bán!")
	# Let the dish on the stove finish before closing up.
	if _customers.is_cooking():
		await _customers.cooking_ended
	_summary_label.text = "Hết ca!\nThu được: %dk\nKhách đã phục vụ: %d\nKhách bỏ đi: %d" % [
		_earned_today, _served, _left_angry]
	_summary_panel.show()
	_next_day_button.grab_focus()


func _on_customer_served(price: int, tip: int) -> void:
	_earned_today += price + tip
	_served += 1


func _on_customer_left_angry() -> void:
	_left_angry += 1


func _refresh_storage() -> void:
	var counts := KitchenLogic.count_by_fish(GameState.storage)
	var parts: PackedStringArray = []
	for item: InventoryItem in GameState.storage:
		var entry := "%s x%d" % [item.fish.display_name, counts[item.fish.id]]
		if not parts.has(entry):
			parts.append(entry)
	_storage_label.text = "Kho: " + (", ".join(parts) if not parts.is_empty() else "trống")


func _show_message(text: String) -> void:
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	_message_label.show()
	await get_tree().create_timer(message_seconds).timeout
	if token == _message_token:
		_message_label.hide()


# Temporary shortcut so the day loop can be tested before Phase 7.
func _on_next_day_pressed() -> void:
	GameState.day += 1
	SceneRouter.go_to(SEA_SCENE_PATH)
