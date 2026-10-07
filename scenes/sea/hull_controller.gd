class_name HullController
extends Node
## Hull damage at sea. Hitting rocks faster than `safe_impact_speed` costs
## hull points; a damaged hull slows the boat; at 0 the boat breaks and the
## sea scene calls a rescue. Full repairs only at the dock (`repair_boat`
## key); out at sea only a pricey patch (ông Tám's hut). A boat still broken from yesterday can't leave the dock.

signal boat_broken
signal hull_changed

@export var boat: Boat
@export var hud: SeaHud
## Impacts slower than this (px/s, straight into the surface) are harmless.
@export var safe_impact_speed: float = 25.0
## Hull points lost per px/s above the safe speed.
@export var damage_per_speed: float = 0.3
## Below this HP the boat starts slowing down, down to min_speed_factor at 0.
@export var slow_below_hp: float = 50.0
@export var min_speed_factor: float = 0.6
@export var warn_below_hp: float = 30.0

## Damage multiplier for tonight (the Miếu Cá Ông blessing lowers it).
var damage_scale: float = 1.0

var _at_dock: bool = false


func _ready() -> void:
	boat.collided.connect(_on_collided)
	boat.boat_data_changed.connect(func(_data: BoatData) -> void: _refresh())
	_refresh.call_deferred()
	if BoatCondition.is_broken():
		boat.set_physics_process.call_deferred(false)
		hud.flash_message.call_deferred("Thuyền đang hư! Sửa ở bến (F) trước khi ra khơi.", 3.0)


func set_at_dock(at_dock: bool) -> void:
	_at_dock = at_dock


func is_at_dock() -> bool:
	return _at_dock


## Dock prompt when the hull is damaged, e.g. "F: Sửa thuyền (40k)".
func repair_prompt() -> String:
	if not BoatCondition.is_damaged():
		return ""
	return "F: Sửa thuyền (%dk)" % BoatCondition.full_repair_cost(boat.boat_data)


func _unhandled_input(event: InputEvent) -> void:
	if _at_dock and event.is_action_pressed("repair_boat"):
		get_viewport().set_input_as_handled()
		_repair()


func _repair() -> void:
	if not BoatCondition.is_damaged():
		return
	var was_broken := BoatCondition.is_broken()
	var spent := BoatCondition.repair(boat.boat_data)
	if spent == 0:
		hud.flash_message("Không đủ tiền sửa thuyền")
		return
	var partial := " (chưa đủ tiền sửa hết)" if BoatCondition.is_damaged() else ""
	hud.flash_message("Đã sửa thuyền: -%dk%s" % [spent, partial])
	if was_broken and not BoatCondition.is_broken():
		boat.set_physics_process(true)
	_refresh()


## Patch at sea: +`hp` for `cost`. Returns false if the hull is fine or the
## player can't pay.
func patch(hp: float, cost: int) -> bool:
	if not BoatCondition.is_damaged() or not GameState.spend_money(cost):
		return false
	var was_broken := BoatCondition.is_broken()
	GameState.boat_hp = minf(GameState.boat_hp + hp, BoatCondition.MAX_HP)
	if was_broken:
		boat.set_physics_process(true)
	_refresh()
	return true


func _on_collided(impact_speed: float) -> void:
	if BoatCondition.is_broken():
		return
	apply_damage(maxf(impact_speed - safe_impact_speed, 0.0) * damage_per_speed)


## Hull damage from any source (rocks, jellyfish...). Tonight's damage_scale
## applies; breaking the hull emits boat_broken.
func apply_damage(amount: float) -> void:
	if BoatCondition.is_broken():
		return
	var damage := amount * damage_scale
	if damage <= 0.0:
		return
	var before := GameState.boat_hp
	BoatCondition.damage(damage)
	_refresh()
	if BoatCondition.is_broken():
		boat_broken.emit()
	elif GameState.boat_hp < warn_below_hp and before >= warn_below_hp:
		hud.flash_message("Thuyền thủng nặng! Về bến sửa đi.", 2.0)


func _refresh() -> void:
	var hp := GameState.boat_hp
	var t := clampf(hp / slow_below_hp, 0.0, 1.0)
	boat.speed_multiplier = lerpf(min_speed_factor, 1.0, t)
	hud.set_hull(hp, hp < warn_below_hp)
	hull_changed.emit()
