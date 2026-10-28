class_name MarketBag3D
extends RefCounted
## Rin's shopping bag in the 3D restaurant: goods bought during a shift wait here
## until he puts them away at the fridge (E next to it).

const FRIDGE_POSITION := Vector3(-1.5, 0, -7.2)
const REACH := 2.0

var bag := MarketStock.new({})


func add(dish: DishData, bulk: bool) -> void:
	bag.add(dish, dish.buy_units(bulk))


func has_goods() -> bool:
	return bag.total() > 0


func near_fridge(at: Vector3) -> bool:
	return at.distance_to(FRIDGE_POSITION) < REACH


## Bag -> fridge stock; returns how many units moved.
func store(stock: MarketStock, dishes: Array[DishData]) -> int:
	return bag.move_into(stock, dishes)


func build_fridge(parent: Node3D) -> void:
	var body := _box(parent, FRIDGE_POSITION + Vector3(0, 0.95, 0), Vector3(0.9, 1.9, 0.8), Color("c7cfcc"))
	_box(body, Vector3(0.3, 0.1, 0.42), Vector3(0.06, 0.6, 0.04), Color("394a50"))
	var label := Label3D.new()
	label.text = "TỦ LẠNH • E"
	label.font_size = 20
	label.pixel_size = 0.005
	label.modulate = Color("e5cf9d")
	parent.add_child(label)
	label.position = FRIDGE_POSITION + Vector3(0, 2.2, 0.4)


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	return mesh
