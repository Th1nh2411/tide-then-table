extends Node3D
## Actual village/sea assets, photographed in their existing placements.
var camera: Camera3D
const FOLDER := "res://build/brief7/game/"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	SaveSystem.autosave_off = true
	GameState.reset()
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().content_scale_size = Vector2i.ZERO
	get_window().size = Vector2i(1280, 720)
	SceneRouter.set_psx_look(false)
	_disable_view()
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var village := (load(VillageLayout3D.SCENE) as PackedScene).instantiate() as VillageScene3D
	add_child(village)
	for frame: int in range(8):
		await get_tree().process_frame
	village.process_mode = Node.PROCESS_MODE_DISABLED
	village.player.visible = false
	village.hud.visible = false
	village.lighting.set_inside(false)
	village.lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	camera = Camera3D.new()
	camera.fov = 70
	camera.far = 280
	add_child(camera)
	for id: String in ["charcoal_stove_clay", "boat_upturned", "boat_pulled_up", "coconut_palm", "food_cart_glass", "planter_tree_street"]:
		var target := Vector3(45, 0, -7) if id in ["boat_upturned", "boat_pulled_up", "coconut_palm"] else Vector3(-31, 0, 7.7) if id == "planter_tree_street" else Vector3.ZERO
		var item := _find(village, id, target)
		assert(item != null, "missing gameplay placement " + id)
		var bounds := _bounds(item)
		var focus := bounds.get_center()
		var eye := focus + Vector3(2.0, 0, 2.5)
		eye.y = 1.6
		if id == "charcoal_stove_clay":
			eye = item.global_position + Vector3(-1.1, 1.25, 1.25)
		if id in ["boat_upturned", "boat_pulled_up"]:
			eye = focus + Vector3(2.5, 1.2, 3.2)
		if id == "coconut_palm":
			eye = item.global_position + Vector3(5, 1.6, -6)
		if id == "planter_tree_street":
			eye = item.global_position + Vector3(-3, 1.6, -5)
			var rin := PersonRig3D.build(village, "rin")
			rin.process_mode = Node.PROCESS_MODE_ALWAYS
			rin.position = item.global_position + Vector3(-1.3, 0, 0)
		if id == "food_cart_glass":
			eye = item.global_position + item.global_basis * Vector3(1.5, 1.6, 2.3)
		await _shot(id, eye, focus)
		print("GAME SHOT ", id, " at=", item.global_position)
	var house := _find(village, "tube_house_b", Vector3(8, 0, 18))
	for key: String in ["tap_hoa", "sua_xe", "thuoc_bac", "plain"]:
		assert(ConceptModel3D.set_sign_variant(house, key))
		var focus := _bounds(house).get_center()
		await _shot("sign_" + key, house.global_position + house.global_basis * Vector3(2.5, 1.6, 8), focus)
	village.queue_free()
	await get_tree().process_frame
	var sea := (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate() as SeaScene3D
	add_child(sea)
	for frame: int in range(8):
		await get_tree().process_frame
	sea.process_mode = Node.PROCESS_MODE_DISABLED
	_disable_view()
	# First-person game hides Rin's own body and the boat's decorative lamp post.
	for rider: Node3D in sea.rin_figure:
		rider.visible = false
	sea.paddle.visible = false
	for child: Node in sea.boat_visual.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	var eye := sea.boat.global_position + Vector3(0, 1.55, 0)
	for id: String in ["ca_mu", "cua", "tom", "muc", "oc_huong", "ca_thu_phat_sang"]:
		sea.rod.rod.show_fish(load("res://data/fish/%s.tres" % id) as FishData, 1.0)
		await _shot("hand_" + id, eye, eye + Vector3(0, -.04, -1), sea.rod.rod)
		print("HAND SHOT ", id)
	sea.queue_free()
	await get_tree().process_frame
	print("BRIEF7 GAME REVIEW OK")
	get_tree().quit()

func _disable_view() -> void:
	var view := SceneRouter.get_node_or_null("FirstPersonView")
	if view:
		view.process_mode = Node.PROCESS_MODE_DISABLED

func _shot(id: String, eye: Vector3, focus: Vector3, rod: Rod3D = null) -> void:
	_disable_view()
	camera.global_position = eye
	camera.look_at(focus)
	camera.reset_physics_interpolation()
	for frame: int in range(6):
		camera.make_current()
		if rod:
			rod._process(0.0)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(FOLDER + id + ".png")

func _find(root: Node, id: String, target: Vector3) -> Node3D:
	var best: Node3D
	var distance := INF
	for node: Node in root.find_children("*", "Node3D", true, false):
		if str(node.get_meta("horror_model_id", "")) != id:
			continue
		var item := node as Node3D
		var d := item.global_position.distance_squared_to(target)
		if d < distance:
			distance = d
			best = item
	return best

func _bounds(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
