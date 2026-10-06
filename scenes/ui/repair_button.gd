class_name RepairButton
extends Button
## "Repair boat" button for anywhere on land (restaurant). Hidden while the
## hull is fine; repairs as much as the player can afford.

signal repaired(spent: int, fully: bool)

## Boat upgrade track, to know which boat (and repair rate) the player owns.
@export var boat_upgrade: UpgradeData


func _ready() -> void:
	pressed.connect(_on_pressed)
	GameState.money_changed.connect(func(_money: int) -> void: refresh())
	refresh()


func refresh() -> void:
	visible = BoatCondition.is_damaged()
	if not visible:
		return
	var cost := BoatCondition.full_repair_cost(_boat())
	text = "Sửa thuyền %d%% (%dk)" % [roundi(GameState.boat_hp), cost]
	disabled = GameState.money <= 0


func _on_pressed() -> void:
	var spent := BoatCondition.repair(_boat())
	if spent > 0:
		repaired.emit(spent, not BoatCondition.is_damaged())
	refresh()


func _boat() -> BoatData:
	return GameState.get_upgrade_value(boat_upgrade)
