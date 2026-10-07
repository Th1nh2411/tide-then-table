class_name FishingController
extends Node
## Handles a fishing attempt at a spot: the spot picks the species (featured
## fish or zone/depth random), the size is rolled (deeper / big shadow =
## bigger, bigger = harder), a cast and some lamp oil are spent, then the
## minigame runs while the boat holds still. Oil doesn't burn during the
## minigame (time stops while fishing).

## Emitted on a successful catch; the hold manager stores it.
## `size` 1.0 = average (scales price and weight).
signal fish_caught(fish: FishData, quality: float, count: int, size: float)

@export var catalog: FishCatalog
@export var spawner: FishingSpotSpawner
@export var boat: Boat
@export var hud: SeaHud
@export var minigame: FishingMinigame
@export var oil: LampOil
## Lamp oil each cast costs (on top of burning during the minigame).
@export var oil_per_cast: float = 2.0
## Rod upgrade: its value is the minigame zone scale (1.0 = no bonus).
@export var rod_upgrade: UpgradeData

@export_group("Fish size")
## Random spread around the mean size (normal distribution).
@export var size_spread: float = 0.15
## Mean size added at depth 1 / on a big-shadow spot.
@export var size_depth_bonus: float = 0.25
@export var size_big_bonus: float = 0.35
## How much a bigger fish fights harder (see CatchRoll.size_zone_scale).
@export var size_difficulty: float = 0.3

var _rng := RandomNumberGenerator.new()
var _current_spot: FishingSpot
var _size: float = 1.0
## True while the shared minigame overlay is running one of OUR casts.
var _active: bool = false


func _ready() -> void:
	_rng.randomize()
	spawner.spot_fishable_changed.connect(_on_spot_fishable_changed)
	spawner.fishing_requested.connect(_on_fishing_requested)
	minigame.finished.connect(_on_minigame_finished)


func is_fishing() -> bool:
	return minigame.is_running()


func _on_spot_fishable_changed(spot: FishingSpot, can_fish: bool) -> void:
	if is_fishing():
		return
	if can_fish:
		_show_spot_prompt(spot)
	else:
		hud.hide_prompt()


func _show_spot_prompt(spot: FishingSpot) -> void:
	hud.show_prompt("E: Câu - %s (còn %d lượt)" % [spot.hint_text(), spot.casts_left])


func _on_fishing_requested(spot: FishingSpot) -> void:
	if is_fishing():
		return
	var fish := spot.roll_fish(catalog, _rng)
	if fish == null:
		push_warning("No fish defined for zone %d" % spot.zone)
		return
	_current_spot = spot
	_active = true
	_size = CatchRoll.snap_size(CatchRoll.roll_size(_rng, spot.depth,
		spot.big_shadow and fish == spot.featured, size_spread, size_depth_bonus, size_big_bonus),
		fish.typical_kg)
	boat.speed = 0.0
	boat.set_physics_process(false)
	hud.hide_prompt()
	spot.use_cast()
	oil.spend(oil_per_cast)
	var zone_scale := _get_zone_scale() * CatchRoll.size_zone_scale(_size, size_difficulty)
	minigame.start(fish, zone_scale, 1, _size)


func _on_minigame_finished(fish: FishData, caught: bool, quality: float, count: int) -> void:
	# The overlay is shared with net hauling; only handle our own attempts.
	if not _active:
		return
	_active = false
	# If the boat got towed mid-game (hull/oil), stay frozen.
	if DayClock.running:
		boat.set_physics_process(true)
	if caught:
		hud.flash_message(_catch_message(fish, quality))
		fish_caught.emit(fish, quality, count, _size)
	# The spot may have casts left and the boat is still on it.
	if is_instance_valid(_current_spot) and _current_spot.casts_left > 0:
		_show_spot_prompt(_current_spot)
	_current_spot = null


## e.g. "Bắt được Cá mú 3.9kg (to!) - kỷ lục mới!"
func _catch_message(fish: FishData, quality: float) -> String:
	var text := "Bắt được %s %s" % [fish.display_name, fish.weight_text(_size)]
	if CatchRoll.is_big(_size):
		text += " (to!)"
	if quality >= 1.0:
		text += " (hoàn hảo)"
	# Must be checked before the hold manager records this catch.
	if GameState.caught_species.has(fish.id) and _size > GameState.best_size(fish):
		text += " - kỷ lục mới!"
	return text


func _get_zone_scale() -> float:
	return float(GameState.get_upgrade_value(rod_upgrade)) if rod_upgrade else 1.0
