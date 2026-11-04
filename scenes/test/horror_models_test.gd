extends Node3D
## Actual import / scale / route checks, independent of the catch simulation.

var failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	var specs := ConceptModel3D.geometry("fish_ca_thu")
	_check(not specs.is_empty(), "model geometry metadata loads")
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/ready/horror_models.json"))
	_check(all.size() >= 25, "original model catalog is retained as new batches are added")
	for id: String in all:
		var model := ConceptModel3D.spawn(self, id, Vector3.ZERO, 1.0)
		var bounds := _bounds(model)
		_check(is_equal_approx(bounds.size.y, 1.0) and absf(bounds.position.y) < 0.001,
			id + " imports at requested height and stands on the ground")
		var lit := true
		for instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			for surface in range(instance.mesh.get_surface_count()):
				var arrays := instance.mesh.surface_get_arrays(surface)
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				lit = lit and not normals.is_empty()
				for normal in normals:
					lit = lit and normal.is_finite() and normal.length_squared() > 0.9
		_check(lit, id + " has finite normals for lamp lighting")
		model.free()
	var serving := Node3D.new()
	add_child(serving)
	ServedFoodVisual3D.show_dish(serving, load("res://data/dishes/canh_chua_ca_thu.tres") as DishData, true)
	_check(serving.get_meta("served_food_id") == "dish_bowl_soup", "soup uses a bowl on the serving tray")
	ServedFoodVisual3D.show_kind(serving, "beer_tower", false, true)
	var food := serving.get_node("ServedFood")
	_check(food.get_node("beer_glass_ice").visible and not food.get_node("dish_bowl_soup").visible,
		"beer table swaps the bowl for a tower and glass")
	var count := food.get_child_count()
	for i: int in range(10):
		ServedFoodVisual3D.show_kind(serving, "beer_tower", false, true)
	_check(food.get_child_count() == count, "repeated service updates reuse meshes")
	serving.free()
	var fish := FishBasket3D.fish_mesh(load("res://data/fish/ca_mu.tres"), 1.0)
	add_child(fish)
	var length := _bounds(fish).size.x
	_check(length > 0.30 and length < 0.34, "diagonal grouper aligns across the hand at life scale")
	fish.free()
	var camera := Camera3D.new()
	add_child(camera)
	camera.make_current()
	var rod := Rod3D.new()
	add_child(rod)
	rod.set_process(false)
	rod._process(0.0)
	var tip := rod.tip_position()
	rod.tension = 1.0
	rod._process(0.0)
	_check(tip.distance_to(rod.tip_position()) > 0.2, "inferred rod tip still bends with line tension")
	rod.free()
	camera.free()
	var village := (load(VillageLayout3D.SCENE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	await get_tree().physics_frame
	await get_tree().physics_frame
	village.hud._process(0.0)
	_check(not village.hud.visible, "restaurant HUD stays hidden on waking at home")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(21, 1.0, 3.5), Vector3(46, 1.0, 3.5))
	_check(get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "new village props leave the lane through-route open")
	var shore_path := PhysicsRayQueryParameters3D.create(Vector3(47, 1.0, 3.5), Vector3(60, 1.0, 3.5))
	_check(get_world_3d().direct_space_state.intersect_ray(shore_path).is_empty(), "drying nets leave the path from lane to house open")
	village.shift_running = true
	village.hud._process(0.0)
	_check(village.hud.visible, "restaurant HUD returns during the shift")
	village.queue_free()
	await get_tree().process_frame
	print("HORROR MODELS TEST ", "PASS" if failures == 0 else "FAIL")
	get_tree().quit(1 if failures else 0)


func _bounds(model: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds


func _check(ok: bool, words: String) -> void:
	print(("PASS " if ok else "FAIL ") + words)
	if not ok:
		failures += 1
