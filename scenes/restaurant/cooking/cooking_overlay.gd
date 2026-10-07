class_name CookingOverlay
extends CanvasLayer
## Cooking popup. Picks the minigame by the dish's cook_type, shows the result
## briefly, then reports the price multiplier.

signal finished(dish: DishData, result: CookingGameBase.Result, multiplier: float)

@export var perfect_multiplier: float = 1.3
@export var ok_multiplier: float = 1.0
@export var burnt_multiplier: float = 0.5
@export var result_seconds: float = 0.8
## Kitchen upgrade: its value is the cooking game speed (< 1 = easier).
@export var kitchen_upgrade: UpgradeData

var _dish: DishData
var _game: CookingGameBase

@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _status_label: Label = %StatusLabel
@onready var _result_label: Label = %ResultLabel
@onready var _game_holder: Container = %GameHolder


func _ready() -> void:
	hide()


func is_running() -> bool:
	return _game != null


func start(dish: DishData) -> void:
	if is_running():
		return
	_dish = dish
	match dish.cook_type:
		DishData.CookType.GRILL:
			_game = GrillGame.new()
		DishData.CookType.STEAM:
			_game = SteamGame.new()
		_:
			_game = StirGame.new()
	_game.setup(dish)
	if kitchen_upgrade:
		_game.time_scale = float(GameState.get_upgrade_value(kitchen_upgrade))
	_game.completed.connect(_on_game_completed)
	_game_holder.add_child(_game)
	_title_label.text = "Nấu: %s" % dish.display_name
	_hint_label.text = _game.get_hint()
	_result_label.text = ""
	show()


func get_multiplier(result: CookingGameBase.Result) -> float:
	match result:
		CookingGameBase.Result.PERFECT:
			return perfect_multiplier
		CookingGameBase.Result.OK:
			return ok_multiplier
		_:
			return burnt_multiplier


func _process(_delta: float) -> void:
	if _game:
		_status_label.text = _game.get_status_text()


func _on_game_completed(result: CookingGameBase.Result) -> void:
	var names := {
		CookingGameBase.Result.PERFECT: "Hoàn hảo!",
		CookingGameBase.Result.OK: "Ổn",
		CookingGameBase.Result.BURNT: "Hỏng...",
	}
	var multiplier := get_multiplier(result)
	_result_label.text = "%s  x%.1f" % [names[result], multiplier]
	await get_tree().create_timer(result_seconds).timeout
	_game.queue_free()
	_game = null
	hide()
	finished.emit(_dish, result, multiplier)
