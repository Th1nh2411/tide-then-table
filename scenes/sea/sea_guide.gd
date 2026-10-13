class_name SeaGuide
extends Guide
## First-time pointers at sea (see Guide): steering, a fishing spot, the
## nets, a full net, the hold, a full hold, the lobster raft and selling
## there, low oil, a dented hull, repairing at the dock, unloading a nearly
## full hold, and the dock. Refs are set by the sea scene.

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
var hud: SeaHud

var _catches: int = 0


func _ready() -> void:
	blocked = fishing.is_fishing
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
	add("net", "Q: thả lưới (tôm, cua, ốc)", _net_tip_due,
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
	add("hull", "Thuyền móp: về bến sửa", func() -> bool: return _at_sea() and BoatCondition.is_damaged(),
		hud.hull_target,
		func() -> bool: return dock.is_boat_inside())
	add("repair", "F: sửa thuyền", func() -> bool: return dock.is_boat_inside() and BoatCondition.is_damaged(),
		_boat_top,
		func() -> bool: return not BoatCondition.is_damaged())
	add("unload", "Về bến dỡ bớt cá", _hold_nearly_full,
		func() -> Vector2: return Guide.screen_of(dock),
		func() -> bool: return dock.is_boat_inside())
	add("dock", "E: dỡ cá / về ngủ", func() -> bool: return dock.is_boat_inside() and _catches > 0,
		func() -> Vector2: return Guide.screen_of(dock, Vector2(0, -14)))
	add("wave", "C khi câu: chậm lại", func() -> bool: return WaveMark.has_power() and DayClock.running,
		wave_badge_target,
		func() -> bool: return WavePower.active)


func _at_sea() -> bool:
	return DayClock.running and not dock.is_boat_inside()


## Nets are taught on the first night: shrimp and crab only come from them.
func _net_tip_due() -> bool:
	return Guide.is_seen("steer") and _at_sea() and nets.nets_available() > 0 and nets.can_drop_here()


func _hold_nearly_full() -> bool:
	return _at_sea() and hold_manager.hold.fill_fraction() >= hold_manager.almost_full_fraction


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
