class_name FishingController
extends Node
## Handles a fishing attempt at a spot: picks the species by zone and weight,
## spends a cast and in-game time, then runs the minigame while the boat
## holds still. The day clock keeps running during the minigame.

## Emitted on a successful catch; the hold manager stores it.
signal fish_caught(fish: FishData, quality: float, count: int)

@export var catalog: FishCatalog
@export var spawner: FishingSpotSpawner
@export var boat: Boat
@export var hud: SeaHud
@export var minigame: FishingMinigame
## In-game minutes each cast costs (on top of real minigame time).
@export var minutes_per_cast: float = 20.0
## Extra green-zone size per rod upgrade level (0.15 = +15% per level).
## Replaced by UpgradeData values in Phase 7.
@export var rod_zone_bonus_per_level: float = 0.15

var _rng := RandomNumberGenerator.new()
var _current_spot: FishingSpot
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
		hud.show_prompt("E: Câu (còn %d lượt)" % spot.casts_left)
	else:
		hud.hide_prompt()


func _on_fishing_requested(spot: FishingSpot) -> void:
	if is_fishing():
		return
	var fish := catalog.pick_random(spot.zone, _rng)
	if fish == null:
		push_warning("No fish defined for zone %d" % spot.zone)
		return
	_current_spot = spot
	_active = true
	boat.speed = 0.0
	boat.set_physics_process(false)
	hud.hide_prompt()
	spot.use_cast()
	DayClock.advance(minutes_per_cast)
	minigame.start(fish, _get_zone_scale())


func _on_minigame_finished(fish: FishData, caught: bool, quality: float, count: int) -> void:
	# The overlay is shared with net hauling; only handle our own attempts.
	if not _active:
		return
	_active = false
	# If the deadline hit mid-game, the sea scene is towing us; stay frozen.
	if DayClock.running:
		boat.set_physics_process(true)
	if caught:
		hud.flash_message("Bắt được %s%s" % [fish.display_name, " ★" if quality >= 1.0 else ""])
		fish_caught.emit(fish, quality, count)
	# The spot may have casts left and the boat is still on it.
	if is_instance_valid(_current_spot) and _current_spot.casts_left > 0:
		hud.show_prompt("E: Câu (còn %d lượt)" % _current_spot.casts_left)
	_current_spot = null


func _get_zone_scale() -> float:
	return 1.0 + GameState.get_upgrade_level("rod") * rod_zone_bonus_per_level
