class_name FishingMinigame
extends CanvasLayer
## Fishing overlay. Rod fish bite automatically when the free-moving hook
## stays close; the same game then continues as a rod fight. Nets use HAUL.
## Shows the result briefly, then reports quality and how many were
## caught (more than 1 when hauling a net). LampOil doesn't burn while this
## overlay is running: time stops while fishing.

signal finished(fish: FishData, caught: bool, quality: float, count: int)
signal fight_stun_changed(value: float)
signal rin_fainted
signal catch_size_changed(value: float)
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
## Fish drawn in the school (3D sea passes the shoal's fish left).
var school_size: int = 6
## Rolled fish size, shown once hooked (CatchRoll).
var _size: float = 1.0
var _in_bite_stage: bool = false
## False if the player struck too early while waiting (no perfect catch).
var _bite_clean: bool = true
var _starting_stun: float = 0.0
var _fainted: bool = false

@onready var _title_label: Label = %TitleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _status_label: Label = %StatusLabel
@onready var _result_label: Label = %ResultLabel
@onready var _game_holder: Container = %GameHolder
@onready var _hold_button: Button = %HoldButton

var _portrait: FishPortrait


func _ready() -> void:
	hide()
	# No keyboard focus: Space is `cast` and must never "click" this button.
	_hold_button.focus_mode = Control.FOCUS_NONE
	UiIcons.dress(_hold_button, "crate", 12, UiIcons.GOLD)
	_hold_button.pressed.connect(hold_requested.emit)
	# The fish on the line sits right of the minigame, big.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_game_holder.add_sibling(row)
	_game_holder.reparent(row)
	_portrait = FishPortrait.new()
	_portrait.custom_minimum_size = Vector2(56, 120)
	_portrait.vertical = true
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait)


func is_running() -> bool:
	return _game != null


## `zone_scale` > 1 makes the game easier (rod/net upgrade).
## `count` = how many fish are at stake (shellfish in a net).
## `size` only changes the "hooked" title; difficulty comes in via zone_scale.
func start(fish: FishData, zone_scale: float = 1.0, count: int = 1, size: float = 1.0,
		starting_stun: float = 0.0) -> void:
	if is_running():
		return
	_fish = fish
	_zone_scale = zone_scale
	_count = count
	_size = size
	_starting_stun = starting_stun
	_fainted = false
	_bite_clean = true
	_result_label.text = ""
	_title_label.modulate = Color.WHITE
	_portrait.fish = fish
	if fish.minigame == FishData.Minigame.HAUL:
		_in_bite_stage = false
		_title_label.text = "Kéo lưới: %s" % _species_name()
		_show_species()
		_start_stage(HaulGame.new())
	else:
		# The player lowers the hook into a visible school and chooses a fish.
		_in_bite_stage = false
		_title_label.text = "Đưa mồi lại gần cá"
		_portrait.silhouette = 1.0  # who's down there? a shadow until hooked
		_portrait.mystery = true
		_start_stage(_create_fight())
	show()


func _start_stage(game: MinigameBase) -> void:
	_game = game
	_game.catch_count = _count
	_game.setup(_fish, _zone_scale)
	_game.completed.connect(_on_game_completed)
	_game_holder.add_child(_game)
	_hint_label.text = _game.get_hint()
	# First time with each game only; the how-to lives in Hướng dẫn.
	var guide_id := "game_fish_school_auto_bite_v2" if _game is FishFightGame \
		else "game_" + str(_game.get_script().get_global_name())
	_hint_label.visible = Guide.once(guide_id)
	if not _hint_label.visible and WaveMark.has_power() and Guide.once("wave_power"):
		_hint_label.text = "C: Nhịp Sóng · chậm lại vài giây"
		_hint_label.visible = true


func _create_fight() -> MinigameBase:
	var game := FishFightGame.new()
	game.school_size = school_size
	game.stun = _starting_stun
	game.tugged.connect(_portrait.jolt)
	game.rin_fainted.connect(_on_rin_fainted)
	game.fish_hooked.connect(_on_fish_hooked)
	return game


func _on_fish_hooked(size_scale: float) -> void:
	_size = CatchRoll.snap_size(clampf(_size * size_scale, CatchRoll.MIN_SIZE, CatchRoll.MAX_SIZE),
		_fish.typical_kg)
	catch_size_changed.emit(_size)
	_show_species()
	_title_label.text = "Cá cắn câu: %s %s%s!" % [_species_name(), _fish.weight_text(_size),
		" (to!)" if CatchRoll.is_big(_size) else ""]
	_title_label.modulate = aberrant_title_color if _fish.is_aberrant else Color.WHITE
	_hint_label.text = _game.get_hint()
	_hint_label.visible = Guide.once("game_fish_haul_v1")


func _process(_delta: float) -> void:
	if _game:
		_status_label.text = _game.get_status_text()


func _on_game_completed(success: bool, perfect: bool) -> void:
	if _in_bite_stage and success:
		_in_bite_stage = false
		_bite_clean = perfect
		_show_species()
		_title_label.text = "Dính câu: %s %s%s!" % [_species_name(), _fish.weight_text(_size),
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
	elif _fainted:
		_result_label.text = "Rin bất tỉnh!"
	else:
		_result_label.text = _game.get_fail_text()
	var quality := perfect_quality if perfect else normal_quality
	var count := _game.catch_count if success else 0
	if _game is FishFightGame:
		fight_stun_changed.emit((_game as FishFightGame).stun)
	await get_tree().create_timer(result_seconds).timeout
	_free_game()
	hide()
	finished.emit(_fish, success, quality, count)
	if _fainted:
		rin_fainted.emit()


func _on_rin_fainted() -> void:
	_fainted = true


func _free_game() -> void:
	_game_holder.remove_child(_game)
	_game.queue_free()
	_game = null


## Known species (in the Dex) show in colour; new ones stay a shadow with a
## "?" — the NewCatchCard reveals them once landed.
func _show_species() -> void:
	var known := int(GameState.caught_species.get(_fish.id, 0)) > 0
	_portrait.silhouette = 0.0 if known else 1.0
	_portrait.mystery = not known


func _species_name() -> String:
	return _fish.display_name if int(GameState.caught_species.get(_fish.id, 0)) > 0 else "???"
