class_name CookingOverlay
extends CanvasLayer
## Compact cooking panel shown above the kitchen (top-left, the dining room
## stays visible — no pop-up over the screen). Picks the minigame by the
## dish's cook_type (drinks: BeerPourGame), shows the result briefly, then
## reports the multiplier.

signal finished(dish: DishData, result: CookingGameBase.Result, multiplier: float)
## The beer went over the rim (the kitchen takes the wasted beer away).
signal spilled(dish: DishData)

@export var perfect_multiplier: float = 1.3
@export var ok_multiplier: float = 1.0
@export var burnt_multiplier: float = 0.5
## Beer tower multipliers by result (BURNT = short, "vơi").
@export var pour_multipliers: Array[float] = [0.8, 1.0, 1.1]
@export var result_seconds: float = 0.8
## Kitchen upgrade: its value is the cooking game speed (< 1 = easier).
@export var kitchen_upgrade: UpgradeData
## Minigame bar size inside the compact panel.
@export var bar_size: Vector2 = Vector2(196, 12)

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
	if dish.instant_serve:
		var pour := BeerPourGame.new()
		pour.spilled.connect(func() -> void: spilled.emit(dish))
		_game = pour
	else:
		_game = _cooking_game(dish)
	_game.set("bar_size", bar_size)
	_game.setup(dish)
	if kitchen_upgrade:
		_game.time_scale = float(GameState.get_upgrade_value(kitchen_upgrade))
	_game.completed.connect(_on_game_completed)
	_game_holder.add_child(_game)
	_title_label.text = ("Rót: %s" if dish.instant_serve else "Nấu: %s") % dish.display_name
	_hint_label.text = _game.get_hint()
	_hint_label.visible = GameState.is_first_day()
	_result_label.text = ""
	show()


func _cooking_game(dish: DishData) -> CookingGameBase:
	match dish.cook_type:
		DishData.CookType.GRILL:
			return GrillGame.new()
		DishData.CookType.STEAM:
			return SteamGame.new()
	return StirGame.new()


func get_multiplier(result: CookingGameBase.Result) -> float:
	if _dish and _dish.instant_serve:
		return pour_multipliers[result]
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
		CookingGameBase.Result.BURNT: "Vơi..." if _dish.instant_serve else "Hỏng...",
	}
	var multiplier := get_multiplier(result)
	_result_label.text = "%s  x%.1f" % [names[result], multiplier]
	await get_tree().create_timer(result_seconds).timeout
	_game.queue_free()
	_game = null
	hide()
	finished.emit(_dish, result, multiplier)
