class_name FishingMinigame
extends CanvasLayer
## Fishing overlay. Picks the TIMING or TENSION game for the fish, shows the
## result briefly, then reports back with the catch quality.

signal finished(fish: FishData, caught: bool, quality: float)

@export var perfect_quality: float = 1.0
@export var normal_quality: float = 0.7
## Seconds the result text stays before the overlay closes.
@export var result_seconds: float = 1.0
@export var aberrant_title_color: Color = Color(0.5, 1.0, 0.9)

var _fish: FishData
var _game: MinigameBase

@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _status_label: Label = %StatusLabel
@onready var _result_label: Label = %ResultLabel
@onready var _game_holder: Container = %GameHolder


func _ready() -> void:
	hide()


func is_running() -> bool:
	return _game != null


## `zone_scale` > 1 widens the green zone (rod upgrade).
func start(fish: FishData, zone_scale: float = 1.0) -> void:
	if is_running():
		return
	_fish = fish
	if fish.minigame == FishData.Minigame.TENSION:
		_game = TensionGame.new()
	else:
		_game = TimingGame.new()
	_game.setup(fish, zone_scale)
	_game.completed.connect(_on_game_completed)
	_game_holder.add_child(_game)

	_title_label.text = "Câu: %s" % fish.display_name
	_title_label.modulate = aberrant_title_color if fish.is_aberrant else Color.WHITE
	_hint_label.text = _game.get_hint()
	_result_label.text = ""
	show()


func _process(_delta: float) -> void:
	if _game:
		_status_label.text = _game.get_status_text()


func _on_game_completed(success: bool, perfect: bool) -> void:
	if success:
		_result_label.text = "Bắt được! (hoàn hảo)" if perfect else "Bắt được!"
	else:
		_result_label.text = _game.get_fail_text()
	var quality := perfect_quality if perfect else normal_quality
	await get_tree().create_timer(result_seconds).timeout
	_game.queue_free()
	_game = null
	hide()
	finished.emit(_fish, success, quality)
