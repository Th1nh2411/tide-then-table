class_name FishingController
extends Node
## Handles a fishing attempt at a spot: picks the species by zone and weight,
## spends a cast and in-game time, then hands the fish to the minigame.
## Phase 3: the minigame is not built yet, so it just announces the bite.

## Emitted when a fish bites. Phase 4 opens the minigame from here.
signal fish_hooked(fish: FishData)

@export var catalog: FishCatalog
@export var spawner: FishingSpotSpawner
@export var boat: Boat
@export var hud: SeaHud
## In-game minutes each cast costs (on top of real minigame time).
@export var minutes_per_cast: float = 20.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	spawner.spot_fishable_changed.connect(_on_spot_fishable_changed)
	spawner.fishing_requested.connect(_on_fishing_requested)


func _on_spot_fishable_changed(spot: FishingSpot, can_fish: bool) -> void:
	if can_fish:
		hud.show_prompt("E: Câu (còn %d lượt)" % spot.casts_left)
	else:
		hud.hide_prompt()


func _on_fishing_requested(spot: FishingSpot) -> void:
	var fish := catalog.pick_random(spot.zone, _rng)
	if fish == null:
		push_warning("No fish defined for zone %d" % spot.zone)
		return
	boat.speed = 0.0
	spot.use_cast()
	if spot.casts_left > 0:
		_on_spot_fishable_changed(spot, true)  # refresh remaining-casts text
	DayClock.advance(minutes_per_cast)
	# Placeholder until the minigame exists (Phase 4).
	hud.flash_message("Cá cắn câu: %s" % fish.display_name)
	fish_hooked.emit(fish)
