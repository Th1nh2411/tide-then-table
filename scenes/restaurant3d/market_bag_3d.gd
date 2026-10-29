class_name MarketBag3D
extends RefCounted
## Rin's shopping bag in the 3D restaurant: goods bought during a shift wait here
## until he puts them away at the fridge (E next to it).

const FRIDGE_POSITION := Vector3(-1.5, 0, -7.2)
const REACH := 2.0

var bag := MarketStock.new({})
var visual: Node3D


func add(dish: DishData, bulk: bool) -> void:
	bag.add(dish, dish.buy_units(bulk))
	_sync_bag()


func has_goods() -> bool:
	return bag.total() > 0


func near_fridge(at: Vector3) -> bool:
	return at.distance_to(FRIDGE_POSITION) < REACH


## Bag -> fridge stock; returns how many units moved.
func store(stock: MarketStock, dishes: Array[DishData]) -> int:
	var moved := bag.move_into(stock, dishes)
	_sync_bag()
	return moved


func build_fridge(parent: Node3D) -> void:
	RestaurantBatchVisuals.upgrade(parent, "fridge", ["fridge_0", "fridge_1", "fridge_2"], FRIDGE_POSITION)
	var actor: Node3D = parent.get("body")
	if actor:
		visual = RestaurantBatchVisuals.add(actor, "plastic_bag", Vector3(0.34, 0.63, 0.08))
		_sync_bag()
	var label := Label3D.new()
	label.text = "TỦ LẠNH • E"
	label.font_size = 20
	label.pixel_size = 0.005
	label.modulate = Color("e5cf9d")
	parent.add_child(label)
	label.position = FRIDGE_POSITION + Vector3(0, 2.2, 0.4)


func _sync_bag() -> void:
	if is_instance_valid(visual):
		visual.visible = has_goods()
