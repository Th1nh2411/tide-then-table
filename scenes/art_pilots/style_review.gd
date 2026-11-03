extends Node
## Style review (PLAN §10 "Đồng bộ style"): every area of the village map from
## eye height with one camera (FOV 72), the street in its shift light and all
## areas at night, a ghost close-up and the night sea; plus the per-material
## table (StyleAudit). Run windowed:
##   Godot --path . --resolution 1280x720 res://scenes/art_pilots/style_review.tscn -- --no-autosave [--no-style] [--tag=before]
## Output: build/style_review/<tag>/*.png + table.txt.

const VIEWS := [
	# [name, eye, look at]
	["street_tables", Vector3(9.0, 1.55, 5.0), Vector3(2.0, 0.7, -1.5)],
	["street_cart", Vector3(1.5, 1.55, 2.6), Vector3(3.0, 0.9, -4.3)],
	["street_counter", Vector3(7.0, 1.55, 1.0), Vector3(10.0, 1.0, -4.3)],
	["lane", Vector3(40.0, 1.55, 3.5), Vector3(24.0, 1.0, 3.0)],
	["waterfront", Vector3(63.0, 1.55, 3.9), Vector3(70.0, 0.4, -12.0)],
	["room", Vector3(62.9, 1.55, 5.2), Vector3(59.8, 0.6, 7.6)],
]

var _camera := Camera3D.new()
var _dir := "res://build/style_review/after"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_dir = "res://build/style_review/" + arg.trim_prefix("--tag=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var view := SceneRouter.get_node_or_null("FirstPersonView")
	if view:
		view.queue_free()
	_camera.fov = 72.0
	_camera.near = 0.05
	_run.call_deferred()


func _run() -> void:
	GameState.reset()
	var village := load(VillageLayout3D.SCENE).instantiate() as VillageScene3D
	add_child(village)
	village.set_physics_process(false)
	add_child(_camera)
	_camera.make_current()
	await _wait(0.6)
	village._open_shift()
	await _wait(1.2)
	for v: Array in VIEWS.slice(0, 4):
		await _shot(village, "shift_" + str(v[0]), v[1], v[2])
	village.lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	for v: Array in VIEWS:
		await _shot(village, "night_" + str(v[0]), v[1], v[2])
	var table := StyleAudit.rows(village, VillageLayout3D.area)
	_ghosts(village)
	await _shot(village, "ghosts", Vector3(66.0, 1.55, 1.2), Vector3(66.0, 1.0, -1.6))
	village.queue_free()
	await _wait(0.2)
	var sea := load("res://scenes/sea3d/sea_scene_3d.tscn").instantiate() as Node3D
	add_child(sea)
	sea.set_process(false)
	sea.set_physics_process(false)
	await _wait(0.8)
	var boat := sea.get("boat") as Node3D
	await _shot(sea, "sea", boat.global_position + Vector3(0.0, 1.8, 2.5), boat.global_position + Vector3(0, 0.2, -6.0))
	table.append_array(StyleAudit.rows(sea, func(_p: Vector3) -> String: return "sea"))
	var text := StyleAudit.format(table)
	print(text)
	var file := FileAccess.open(_dir + "/table.txt", FileAccess.WRITE)
	file.store_string(text)
	print("PASS style review captured -> ", _dir)
	get_tree().quit()


## ông Tư, a drowned man and woman on the waterfront, facing the camera.
func _ghosts(village: Node3D) -> void:
	var tu := RamFx3D.ghost(village, Vector3(66.0, 0, -1.6), "ong_tu")
	RamFx3D.ghost_holder(tu).rotation.y = 0.0
	for i in 2:
		var rig := PersonRig3D.build(village, "drowned_m" if i == 0 else "drowned_f")
		rig.position = Vector3(64.6 + i * 2.8, 0, -1.2)


func _shot(scene: Node3D, name_: String, eye: Vector3, at: Vector3) -> void:
	_camera.make_current()
	_camera.global_position = eye
	_camera.look_at(at)
	if scene is VillageScene3D:
		(scene as VillageScene3D).lighting.set_inside(VillageLayout3D.in_room(eye))
		(scene as VillageScene3D).player.global_position = eye + Vector3(0, -1.55, 3.0)
	await _wait(0.5)
	get_viewport().get_texture().get_image().save_png(_dir + "/" + name_ + ".png")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
