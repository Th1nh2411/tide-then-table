class_name SeaGuide
extends Guide
## First-time pointers at sea (see Guide): steering, a fishing spot, the
## nets, a full net, the hold, a full hold, the lobster raft and selling
## there, low oil and the dock. Refs are set by the sea scene.

## Show "fish here" when the boat is this close to a spot (px).
@export var spot_reach: float = 90.0
@export var raft_reach: float = 110.0

var boat: Boat
var spawner: FishingSpotSpawner
var fishing: FishingController
var nets: NetController
var hold_manager: HoldManager
var oil: LampOil
var dock: Dock
var raft: Node2D

var _catches: int = 0


func _ready() -> void:
	super()
	fishing.fish_caught.connect(_on_caught)
	nets.fish_caught.connect(_on_caught)


func _add_rules() -> void:
	add("steer", "WASD: lái thuyền", func() -> bool: return DayClock.running,
		_boat_top,
		func() -> bool: return absf(boat.speed) > 30.0)
	add("fish_spot", "Dừng lại, E: câu", func() -> bool: return _near_spot() != null,
		_spot_target,
		func() -> bool: return fishing.is_fishing())
	add("net", "Q: thả lưới ốc", func() -> bool: return _catches >= 1 and nets.nets_available() > 0,
		_boat_top,
		func() -> bool: return nets.nets_out() > 0)
	add("haul", "E: kéo lưới", func() -> bool: return _full_buoy() != null,
		_buoy_target,
		func() -> bool: return _full_buoy() == null)
	add("hold", "Tab: xem khoang", func() -> bool: return _catches >= 3,
		_boat_top,
		func() -> bool: return hold_manager.hold_ui.visible)
	add("hold_full", "Kéo cá xếp lại · R: xoay", func() -> bool: return hold_manager.hold_ui.has_pending(),
		func() -> Vector2: return hold_manager.hold_ui.grid_view().get_global_rect().get_center(),
		func() -> bool: return not hold_manager.hold_ui.visible, true)
	add("raft", "E: bán cá", _near_raft,
		func() -> Vector2: return Guide.screen_of(raft, Vector2(0, -16)),
		func() -> bool: return get_tree().paused)
	add("sell", "Kéo vào đây · chuột phải: bán", func() -> bool: return hold_manager.hold_ui.is_selling(),
		func() -> Vector2: return hold_manager.hold_ui.grid_view().zone_center(),
		func() -> bool: return hold_manager.hold_ui.sold_count() > 0, true)
	add("oil_low", "Dầu sắp hết: về bến", func() -> bool: return _at_sea() and oil.fraction() <= 0.3,
		func() -> Vector2: return Guide.screen_of(dock),
		func() -> bool: return dock.is_boat_inside())
	add("dock", "E: dỡ cá / về ngủ", func() -> bool: return dock.is_boat_inside() and _catches > 0,
		func() -> Vector2: return Guide.screen_of(dock, Vector2(0, -14)))


func _at_sea() -> bool:
	return DayClock.running and not dock.is_boat_inside()


func _boat_top() -> Vector2:
	return Guide.screen_of(boat, Vector2(0, -12))


func _spot_target() -> Vector2:
	var spot := _near_spot()
	return Guide.screen_of(spot) if spot else Vector2.ZERO


func _buoy_target() -> Vector2:
	var buoy := _full_buoy()
	return Guide.screen_of(buoy) if buoy else Vector2.ZERO


func _near_raft() -> bool:
	return raft != null and not hold_manager.hold.items.is_empty() \
		and boat.global_position.distance_to(raft.global_position) <= raft_reach


func _on_caught(_fish: FishData, _quality: float, _count: int, _size: float) -> void:
	_catches += 1


func _near_spot() -> FishingSpot:
	for child in spawner.get_children():
		var spot := child as FishingSpot
		if spot and spot.casts_left > 0 and spot.global_position.distance_to(boat.global_position) <= spot_reach:
			return spot
	return null


func _full_buoy() -> NetBuoy:
	for child in nets.buoy_parent.get_children():
		var buoy := child as NetBuoy
		if buoy and buoy.fill_ratio() >= 1.0:
			return buoy
	return null
