class_name NetController
extends Node
## Nets for shrimp, crab and snails (catch_method = NET). Press `drop_net`
## while slow in a zone where such species live to drop a net (a buoy
## appears). The longer it soaks (real seconds at sea), the more it holds.
## Come back, press `interact` and win the HAUL minigame to bring the catch
## aboard: each animal is rolled from the zone (near shore mostly shrimp, on
## the reef mostly crab, snails in both) with its own size. Nets left at sea
## when the day ends lose their catch.

signal fish_caught(fish: FishData, quality: float, count: int, size: float)
signal nets_changed(available: int, total: int)

@export var catalog: FishCatalog
@export var boat: Boat
@export var hud: SeaHud
@export var minigame: FishingMinigame
## Parent of the SeaZone rects, to know which zone the boat is in.
@export var zones_root: Node
@export var buoy_scene: PackedScene
@export var buoy_parent: Node2D
@export var oil: LampOil
## Nets carried on the boat (upgrade later).
@export var net_count: int = 2
@export var max_drop_speed: float = 15.0
## Seconds at sea for a net to fill up.
@export var seconds_to_full: float = 90.0
## Shellfish in a full net.
@export var max_catch: int = 8
@export var min_buoy_distance: float = 80.0
## Buoy is placed this far behind the boat so you don't haul it by accident.
@export var drop_offset: float = 40.0
## Lamp oil spent dropping / hauling a net.
@export var oil_per_drop: float = 1.0
@export var oil_per_haul: float = 2.0
## Fewer snags per "net" upgrade level (same idea as the rod bonus).
@export var net_bonus_per_level: float = 0.15
## "Depth" used for sizes, by zone (NEARSHORE, REEF, ...): reef crabs run bigger.
@export var depth_by_zone: Array[float] = [0.1, 0.5, 0.8, 1.0]

var _buoys: Array[NetBuoy] = []
## Buoy whose haul prompt is showing; its text is refreshed as the net fills.
var _prompt_buoy: NetBuoy
## True while the shared minigame overlay is running one of OUR hauls.
var _active: bool = false
## What the net being hauled holds: [[FishData, size], ...].
var _haul: Array[Array] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	minigame.finished.connect(_on_minigame_finished)
	_emit_nets.call_deferred()


## Nets work here (a zone with net species).
func can_drop_here() -> bool:
	var sea_zone := SeaZone.find_at(zones_root, boat.global_position)
	return sea_zone != null and not catalog.get_fish_for_zone(sea_zone.zone, FishData.CatchMethod.NET).is_empty()


func nets_out() -> int:
	return _buoys.size()


func nets_available() -> int:
	return net_count - _buoys.size()


## How many shellfish a buoy's net holds right now.
func expected_catch(buoy: NetBuoy) -> int:
	return roundi(max_catch * buoy.fill_ratio())


func _process(_delta: float) -> void:
	if is_instance_valid(_prompt_buoy) and not minigame.is_running():
		_show_haul_prompt(_prompt_buoy)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_net") and not minigame.is_running():
		get_viewport().set_input_as_handled()
		_try_drop()


func _try_drop() -> void:
	if nets_available() <= 0:
		hud.flash_message("Hết lưới rồi, phải kéo lưới cũ lên trước.")
		return
	if absf(boat.speed) > max_drop_speed:
		hud.flash_message("Phải dừng thuyền lại mới thả lưới được.")
		return
	var sea_zone := SeaZone.find_at(zones_root, boat.global_position)
	var fish: FishData = null
	if sea_zone:
		fish = catalog.pick_random(sea_zone.zone, _rng, FishData.CatchMethod.NET)
	if fish == null:
		hud.flash_message("Nước sâu quá, thả lưới ở đây không ăn thua.")
		return
	var drop_pos := boat.global_position - Vector2.RIGHT.rotated(boat.rotation) * drop_offset
	for other in _buoys:
		if other.global_position.distance_to(drop_pos) < min_buoy_distance:
			hud.flash_message("Sát lưới kia quá, ra chỗ khác thả.")
			return

	var buoy: NetBuoy = buoy_scene.instantiate()
	buoy.global_position = drop_pos
	buoy.fish = fish
	buoy.zone = sea_zone.zone
	buoy.full_seconds = seconds_to_full
	buoy.haulable_changed.connect(_on_buoy_haulable_changed)
	buoy.haul_requested.connect(_on_haul_requested)
	buoy_parent.add_child(buoy)
	_buoys.append(buoy)
	oil.spend(oil_per_drop)
	Sfx.play("splash")
	hud.flash_message("Thả lưới xong. Lát quay lại kéo.")
	_emit_nets()


func _on_buoy_haulable_changed(buoy: NetBuoy, can_haul: bool) -> void:
	if minigame.is_running():
		return
	if can_haul:
		_prompt_buoy = buoy
		_show_haul_prompt(buoy)
	elif buoy == _prompt_buoy:
		_prompt_buoy = null
		hud.hide_prompt()


func _show_haul_prompt(buoy: NetBuoy) -> void:
	hud.show_prompt("E: Kéo lưới (đầy %d%% · ~%d con)" % [
		roundi(buoy.fill_ratio() * 100.0), expected_catch(buoy)])


func _on_haul_requested(buoy: NetBuoy) -> void:
	if minigame.is_running():
		return
	var count := expected_catch(buoy)
	_haul = _roll_haul(buoy.zone, count)
	var fish := _main_species(_haul) if not _haul.is_empty() else buoy.fish
	# The net comes back aboard whatever happens next.
	_buoys.erase(buoy)
	buoy.queue_free()
	_prompt_buoy = null
	hud.hide_prompt()
	_emit_nets()
	if count <= 0:
		hud.flash_message("Lưới chưa dính con nào...")
		return
	_active = true
	boat.speed = 0.0
	boat.set_physics_process(false)
	oil.spend(oil_per_haul)
	var bonus := 1.0 + GameState.get_upgrade_level("net") * net_bonus_per_level
	minigame.start(fish, bonus, count)


func _on_minigame_finished(fish: FishData, caught: bool, quality: float, count: int) -> void:
	if not _active:
		return
	_active = false
	if DayClock.running:
		boat.set_physics_process(true)
	if caught:
		hud.flash_message("Được %s%s!" % [_haul_text(_haul), ", ngon lành" if quality >= 1.0 else ""])
		for entry: Array in _haul:
			fish_caught.emit(entry[0], quality, 1, entry[1])
	_haul.clear()


## `count` animals from a net in `zone`: [[FishData, size], ...].
func _roll_haul(zone: int, count: int) -> Array[Array]:
	var depth: float = depth_by_zone[clampi(zone, 0, depth_by_zone.size() - 1)]
	var haul: Array[Array] = []
	for i in count:
		var fish := catalog.pick_random(zone as FishData.Zone, _rng, FishData.CatchMethod.NET)
		if fish:
			var size := CatchRoll.snap_size(CatchRoll.roll_size(_rng, depth, false), fish.typical_kg)
			haul.append([fish, size])
	return haul


## The species most of the haul is (shown on the haul minigame).
func _main_species(haul: Array[Array]) -> FishData:
	var counts: Dictionary = {}
	var best: FishData = haul[0][0]
	for entry: Array in haul:
		var fish: FishData = entry[0]
		counts[fish] = int(counts.get(fish, 0)) + 1
		if counts[fish] > int(counts.get(best, 0)):
			best = fish
	return best


## "5 Tôm, 2 Ốc hương"
func _haul_text(haul: Array[Array]) -> String:
	var counts: Dictionary = {}
	for entry: Array in haul:
		var fish: FishData = entry[0]
		counts[fish] = int(counts.get(fish, 0)) + 1
	var parts := PackedStringArray()
	for fish: FishData in counts:
		parts.append("%d %s" % [counts[fish], fish.display_name])
	return ", ".join(parts)


func _emit_nets() -> void:
	nets_changed.emit(nets_available(), net_count)
