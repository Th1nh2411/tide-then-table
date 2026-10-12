class_name FishingMinigame
extends CanvasLayer
## Fishing overlay. For rod fish it runs two stages: BiteGame (wait for the
## bite and strike) then the fight (TIMING or TENSION). Nets go straight to
## HAUL. Shows the result briefly, then reports quality and how many were
## caught (more than 1 when hauling a net). LampOil doesn't burn while this
## overlay is running: time stops while fishing.

signal finished(fish: FishData, caught: bool, quality: float, count: int)
## The player pressed the hold button / key during the minigame.
signal hold_requested

@export var perfect_quality: float = 1.0
@export var normal_quality: float = 0.7
## Seconds the result text stays before the overlay closes.
@export var result_seconds: float = 1.0
## Pause between hooking the fish and the fight starting.
@export var hooked_pause_seconds: float = 0.6
@export var aberrant_title_color: Color = Color(0.5, 1.0, 0.9)

var _fish: FishData
var _game: MinigameBase
var _zone_scale: float = 1.0
var _count: int = 1
## Rolled fish size, shown once hooked (CatchRoll).
var _size: float = 1.0
var _in_bite_stage: bool = false
## False if the player struck too early while waiting (no perfect catch).
var _bite_clean: bool = true

@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _status_label: Label = %StatusLabel
@onready var _result_label: Label = %ResultLabel
@onready var _game_holder: Container = %GameHolder
@onready var _hold_button: Button = %HoldButton


func _ready() -> void:
	hide()
	# No keyboard focus: Space is `cast` and must never "click" this button.
	_hold_button.focus_mode = Control.FOCUS_NONE
	_hold_button.pressed.connect(hold_requested.emit)


func is_running() -> bool:
	return _game != null


## `zone_scale` > 1 makes the game easier (rod/net upgrade).
## `count` = how many fish are at stake (shellfish in a net).
## `size` only changes the "hooked" title; difficulty comes in via zone_scale.
func start(fish: FishData, zone_scale: float = 1.0, count: int = 1, size: float = 1.0) -> void:
	if is_running():
		return
	_fish = fish
	_zone_scale = zone_scale
	_count = count
	_size = size
	_bite_clean = true
	_result_label.text = ""
	_title_label.modulate = Color.WHITE
	if fish.minigame == FishData.Minigame.HAUL:
		_in_bite_stage = false
		_title_label.text = "Kéo lưới: %s" % fish.display_name
		_start_stage(HaulGame.new())
	else:
		# The species stays a mystery until it's hooked.
		_in_bite_stage = true
		_title_label.text = "Đang câu..."
		_start_stage(BiteGame.new())
	show()


func _start_stage(game: MinigameBase) -> void:
	_game = game
	_game.catch_count = _count
	_game.setup(_fish, _zone_scale)
	_game.completed.connect(_on_game_completed)
	_game_holder.add_child(_game)
	_hint_label.text = _game.get_hint()
	# First time with each game only; the how-to lives in Hướng dẫn.
	_hint_label.visible = Guide.once("game_" + str(_game.get_script().get_global_name()))


func _create_fight() -> MinigameBase:
	if _fish.minigame == FishData.Minigame.TENSION:
		return TensionGame.new()
	return TimingGame.new()


func _process(_delta: float) -> void:
	if _game:
		_status_label.text = _game.get_status_text()


func _on_game_completed(success: bool, perfect: bool) -> void:
	if _in_bite_stage and success:
		_in_bite_stage = false
		_bite_clean = perfect
		_title_label.text = "Dính câu: %s %s%s!" % [_fish.display_name, _fish.weight_text(_size),
			" (to!)" if CatchRoll.is_big(_size) else ""]
		_title_label.modulate = aberrant_title_color if _fish.is_aberrant else Color.WHITE
		await get_tree().create_timer(hooked_pause_seconds).timeout
		_free_game()
		_start_stage(_create_fight())
		return

	perfect = perfect and _bite_clean
	Sfx.play("catch" if success and perfect else "ok" if success else "miss")
	if success:
		var amount := " %d con" % _game.catch_count if _game.catch_count > 1 else ""
		_result_label.text = "Bắt được%s!%s" % [amount, " (hoàn hảo)" if perfect else ""]
	else:
		_result_label.text = _game.get_fail_text()
	var quality := perfect_quality if perfect else normal_quality
	var count := _game.catch_count if success else 0
	await get_tree().create_timer(result_seconds).timeout
	_free_game()
	hide()
	finished.emit(_fish, success, quality, count)


func _free_game() -> void:
	_game_holder.remove_child(_game)
	_game.queue_free()
	_game = null
