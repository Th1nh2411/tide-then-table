extends Control
## Restaurant screen (side view).
## Flow: prepare today's menu from storage -> open -> serve customers until
## the shift timer runs out or the menu sells out -> leftovers go back to
## storage -> summary. Shift length comes from the sea trip (late = shorter).
## Phase 7 replaces the summary with the full day summary + upgrade shop.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

## Full selling shift length in real seconds when back on time.
@export var base_shift_seconds: float = 180.0
@export var menu: DishCatalog
@export var fish_catalog: FishCatalog
## How many different dishes the menu can hold.
@export var menu_slots: int = 3
@export var message_seconds: float = 1.5

var _plan: MenuPlan
var _time_left: float = 0.0
var _shift_running: bool = false
var _shift_over: bool = false
var _earned_today: int = 0
var _served: int = 0
var _left_angry: int = 0
var _message_token: int = 0

@onready var _customers: CustomerManager = $CustomerManager
@onready var _menu_panel: MenuSetupPanel = %MenuSetupPanel
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
	_customers.customer_left_angry.connect(func() -> void: _left_angry += 1)
	_customers.message_requested.connect(_show_message)
	_next_day_button.pressed.connect(_on_next_day_pressed)

	_plan = MenuPlan.new(menu_slots)
	_plan.changed.connect(_refresh_storage)
	_menu_panel.setup(_plan, menu, fish_catalog)
	_menu_panel.confirmed.connect(_open_shop)
	_menu_panel.show()
	_time_left = get_shift_seconds()
	_refresh_storage()


func get_shift_seconds() -> float:
	return base_shift_seconds * GameState.shift_ratio


func _open_shop() -> void:
	_menu_panel.hide()
	_shift_running = true
	_customers.start_shift(_plan)
	var late_text := ""
	if GameState.was_towed:
		late_text = " (bị kéo về, ca bán ngắn nhất)"
	elif GameState.shift_ratio < 1.0:
		late_text = " (về trễ, ca bán còn %d%%)" % roundi(GameState.shift_ratio * 100)
	_show_message("Quán mở cửa!" + late_text)
	_refresh_storage()


# Debug builds: F1 during menu setup adds one of every fish to storage,
# so the restaurant can be tested with F6 without a sea trip.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or key == null or not key.pressed or key.physical_keycode != KEY_F1:
		return
	if not _menu_panel.visible:
		return
	for fish in fish_catalog.fish:
		GameState.storage.append(InventoryItem.new(fish, 1.0))
	_plan.changed.emit()  # refresh panel + storage line


func _process(delta: float) -> void:
	if _shift_running:
		_time_left = maxf(_time_left - delta, 0.0)
		if _time_left <= 0.0:
			_end_shift("Hết giờ bán!")
		elif _plan.is_sold_out() and _customers.is_idle():
			_end_shift("Bán hết món!" if _plan.get_dishes().size() > 0 else "Không có món để bán")
	_top_label.text = "Ngày %d   Ca còn %d:%02d   Tiền %dk (hôm nay +%dk)" % [
		GameState.day, int(_time_left) / 60, int(_time_left) % 60, GameState.money, _earned_today]


func _end_shift(reason: String) -> void:
	_shift_running = false
	_customers.stop_shift()
	_show_message(reason)
	# Let the dish on the stove finish before closing up.
	if _customers.is_cooking():
		await _customers.cooking_ended
	var leftover := _plan.total_portions()
	_plan.clear(GameState.storage)
	_shift_over = true
	_summary_label.text = "%s\nThu được: %dk\nKhách đã phục vụ: %d\nKhách bỏ đi: %d\nPhần thừa trả về kho: %d" % [
		reason, _earned_today, _served, _left_angry, leftover]
	_summary_panel.show()
	_next_day_button.grab_focus()


func _on_customer_served(price: int, tip: int) -> void:
	_earned_today += price + tip
	_served += 1


func _refresh_storage() -> void:
	var lines: PackedStringArray = []
	if _shift_running:
		var menu_parts: PackedStringArray = []
		for dish in _plan.get_dishes():
			var left := _plan.get_portion_count(dish)
			menu_parts.append("%s %s" % [dish.display_name, ("còn %d" % left) if left > 0 else "(hết)"])
		lines.append("Menu: " + " · ".join(menu_parts))
	var counts := KitchenLogic.count_by_fish(GameState.storage)
	var parts: PackedStringArray = []
	for item: InventoryItem in GameState.storage:
		var entry := "%s x%d" % [item.fish.display_name, counts[item.fish.id]]
		if not parts.has(entry):
			parts.append(entry)
	lines.append("Kho: " + (", ".join(parts) if not parts.is_empty() else "trống"))
	_storage_label.text = "\n".join(lines)


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
