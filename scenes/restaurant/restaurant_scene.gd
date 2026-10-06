extends Control
## Restaurant screen. Phase 2 placeholder: shows the return time and shift
## length passed from the sea. Real selling loop arrives in Phase 6.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

## Full selling shift length in real seconds when back on time.
@export var base_shift_seconds: float = 180.0

@onready var _info_label: Label = %InfoLabel
@onready var _next_day_button: Button = %NextDayButton


func _ready() -> void:
	var towed_text := " (bị kéo về)" if GameState.was_towed else ""
	_info_label.text = "Quán mở cửa\nVề bến lúc %s%s\nCa bán: %d%% = %d giây\nKho: %d món" % [
		DayClock.format_minutes(GameState.return_minutes),
		towed_text,
		roundi(GameState.shift_ratio * 100),
		roundi(get_shift_seconds()),
		GameState.storage.size(),
	]
	_next_day_button.pressed.connect(_on_next_day_pressed)
	_next_day_button.grab_focus()


func get_shift_seconds() -> float:
	return base_shift_seconds * GameState.shift_ratio


# Temporary shortcut so the day loop can be tested before Phase 7.
func _on_next_day_pressed() -> void:
	GameState.day += 1
	SceneRouter.go_to(SEA_SCENE_PATH)
