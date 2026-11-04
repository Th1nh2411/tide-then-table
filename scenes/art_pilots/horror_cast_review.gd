extends Node
## Ghost cast review: each candidate stands in idle on the night waterfront
## twice (plain, then with GhostLook3D), name above. Front + 3/4 shots. Run windowed:
##   Godot --path . --resolution 1280x720 res://scenes/art_pilots/horror_cast_review.tscn -- --no-autosave [--ids=a,b,c] [--tag=x]
## `ids` are CAST ids or pack file names. Output: build/shot/horror_cast/<tag>_<n>_{front,quarter}.png.

## The kept ghost cast (GhostCast3D.POOL).
const DEFAULT_IDS := ["drowned_m", "drowned_f", "ma_da", "ma_da_b", "drowned_old", "corpse"]
const PER_SHOT := 3
const SPACING := 2.1
const ORIGIN := Vector3(100.0, 0.0, 30.0)

var _camera := Camera3D.new()
var _dir := "res://build/shot/horror_cast"
var _tag := "lineup"
var _ids: Array[String] = []
var _cam_z := 32.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: String in DEFAULT_IDS:
		_ids.append(id)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--cam_z="):
			_cam_z = float(arg.trim_prefix("--cam_z="))
		elif arg.begins_with("--ids="):
			_ids.clear()
			for id in arg.trim_prefix("--ids=").split(","):
				_ids.append(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var view := SceneRouter.get_node_or_null("FirstPersonView")
	if view:
		view.queue_free()
	_camera.fov = 70.0
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
	village.lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	village.lighting.set_inside(false)
	village.player.global_position = ORIGIN + Vector3(3.0, 0.0, 8.0)
	var lamp := OmniLight3D.new()  # Rin's lantern-ish fill
	lamp.light_color = Color("ffc98a")
	lamp.light_energy = 1.4
	lamp.omni_range = 9.0
	village.add_child(lamp)
	_floor(village)
	var shot := 0
	for start in range(0, _ids.size(), PER_SHOT):
		var batch: Array[Node3D] = []
		var count := mini(PER_SHOT, _ids.size() - start)
		for i in count:
			batch.append_array(_pair(village, _ids[start + i], ORIGIN + Vector3(i * SPACING, 0, 0)))
		var mid := ORIGIN + Vector3((count - 1) * SPACING * 0.5 + 0.45, 0, 0)
		lamp.global_position = Vector3(mid.x, 2.2, _cam_z - 0.4)
		await _shot("%s_%d_front" % [_tag, shot], Vector3(mid.x, 1.4, _cam_z), mid + Vector3(0, 0.9, 0))
		for figure in batch:
			if figure is PsxCharacterVisual:
				figure.get_parent_node_3d().rotation.y = 0.75
		await _shot("%s_%d_quarter" % [_tag, shot], Vector3(mid.x, 1.4, _cam_z), mid + Vector3(0, 0.9, 0))
		for figure in batch:
			figure.get_parent().queue_free()
		shot += 1
	print("PASS horror cast review captured -> ", _dir)
	get_tree().quit()


## Plain and ghost figure of `id` side by side; returns the two visuals.
func _pair(parent: Node3D, id: String, at: Vector3) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for ghost in [false, true]:
		var holder := Node3D.new()
		parent.add_child(holder)
		holder.global_position = at + Vector3(0.9 if ghost else 0.0, 0, 0)
		var visual := PsxCharacterVisual.new()
		visual.asset_id = id
		visual.ghost_look = ghost
		holder.add_child(visual)
		if ghost and not visual.has_meta(StylePass3D.SKIP):
			GhostLook3D.apply(visual)
		var label := Label3D.new()
		label.text = id.trim_prefix("Character_") + (" ma" if ghost else "")
		label.font_size = 40
		label.outline_size = 8
		label.pixel_size = 0.003
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = Vector3(0, 2.05, 0)
		label.set_meta(StylePass3D.SKIP, true)
		holder.add_child(label)
		out.append(visual)
	return out


## A patch of wet sand away from the map's props.
func _floor(parent: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(16, 12)
	ground.mesh = plane
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color("4a4036")
	sand.roughness = 0.95
	ground.material_override = sand
	parent.add_child(ground)
	ground.global_position = ORIGIN + Vector3(3.0, 0, 1.0)


func _shot(name_: String, eye: Vector3, at: Vector3) -> void:
	_camera.make_current()
	_camera.global_position = eye
	_camera.look_at(at)
	await _wait(0.6)
	get_viewport().get_texture().get_image().save_png(_dir + "/" + name_ + ".png")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
