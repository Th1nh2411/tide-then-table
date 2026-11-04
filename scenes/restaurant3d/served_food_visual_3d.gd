class_name ServedFoodVisual3D
extends RefCounted
## Cached visual variants; attachment, service state and colliders stay with the host.

static func show_dish(root: Node3D, dish: DishData, tray := false, glass := false) -> void:
	var id := "beer_tower" if dish != null and dish.instant_serve else "dish_bowl_soup" if dish != null and dish.id == "canh_chua_ca_thu" else "dish_plate_fish"
	show_kind(root, id, tray, glass)


static func show_kind(root: Node3D, id: String, tray := false, glass := false) -> void:
	var visuals := root.get_node_or_null("ServedFood") as Node3D
	if visuals == null:
		for old: Node in root.get_children():
			root.remove_child(old)
			old.queue_free()
		visuals = Node3D.new()
		visuals.name = "ServedFood"
		root.add_child(visuals)
	_add(visuals, id)
	if tray:
		_add(visuals, "tray_aluminium")
	if glass and id == "beer_tower":
		_add(visuals, "beer_glass_ice")
	for part: Node3D in visuals.get_children():
		part.visible = part.name == id or (tray and part.name == "tray_aluminium") or (glass and id == "beer_tower" and part.name == "beer_glass_ice")
	root.set_meta("served_food_id", id)


static func _add(parent: Node3D, id: String) -> void:
	if parent.has_node(NodePath(id)):
		return
	var size := Vector3(0.36, 0.10, 0.30)
	var at := Vector3(0, 0.025, 0)
	match id:
		"dish_bowl_soup": size = Vector3(0.29, 0.15, 0.29)
		"beer_tower": size = Vector3(0.24, 0.49, 0.24)
		"beer_glass_ice":
			size = Vector3(0.10, 0.15, 0.10)
			at.x = 0.18
		"tray_aluminium":
			size = Vector3(0.43, 0.025, 0.36)
			at.y = 0
	var model := ConceptModel3D.fit(parent, id, at, size)
	model.name = id
