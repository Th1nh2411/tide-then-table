extends Control
## Standalone test for the fishing minigame (run with F6).
## Number keys 1-9 start the minigame for that fish in the catalog.
## +/- changes the simulated rod level.

@export var catalog: FishCatalog

var _rod_level: int = 0

@onready var _minigame: FishingMinigame = $FishingMinigame
@onready var _info_label: Label = %InfoLabel


func _ready() -> void:
	_minigame.finished.connect(_on_finished)
	_refresh("")


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _minigame.is_running():
		return
	if key.physical_keycode == KEY_EQUAL:
		_rod_level += 1
		_refresh("")
	elif key.physical_keycode == KEY_MINUS:
		_rod_level = maxi(_rod_level - 1, 0)
		_refresh("")
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < catalog.fish.size():
		var fish := catalog.fish[index]
		var count := 6 if fish.minigame == FishData.Minigame.HAUL else 1
		_minigame.start(fish, 1.0 + _rod_level * 0.15, count)


func _on_finished(fish: FishData, caught: bool, quality: float, count: int) -> void:
	_refresh("Kết quả: %s — %s x%d, quality %.1f" % [fish.display_name, "bắt được" if caught else "trượt", count, quality])


func _refresh(result: String) -> void:
	var lines: PackedStringArray = []
	for i in catalog.fish.size():
		var f := catalog.fish[i]
		lines.append("%d: %s (%s, độ khó %.1f)" % [i + 1, f.display_name,
			FishData.Minigame.keys()[f.minigame], f.difficulty])
	lines.append("Cần câu cấp %d  (+/- để đổi)" % _rod_level)
	lines.append(result)
	_info_label.text = "\n".join(lines)
