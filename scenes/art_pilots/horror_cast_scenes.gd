extends Node
## The ghost cast in the game's own scenes (GhostCast3D): a chaser closing
## in down the lane, the fog figure at the edge, the extra person in the
## street, the pier-head ma da, the three faces, đêm âm figures at sea. Run windowed:
##   Godot --path . --resolution 1280x720 res://scenes/art_pilots/horror_cast_scenes.tscn -- --no-autosave
## Output: build/shot/horror_cast/scene_*.png.

const DIR := "res://build/shot/horror_cast"

var _camera := Camera3D.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var view := SceneRouter.get_node_or_null("FirstPersonView")
	if view:
		view.queue_free()
	_camera.fov = 72.0
	_camera.near = 0.05
	_run.call_deferred()


func _run() -> void:
	GameState.reset()
	UncannyDirector.bot = true  # no zone fires while we pose
	var village := load(VillageLayout3D.SCENE).instantiate() as VillageScene3D
	add_child(village)
	village.set_physics_process(false)
	add_child(_camera)
	await _wait(0.6)
	village.lighting.set_phase(VillageLighting3D.Phase.NIGHT, false)
	# Chaser closing in down the lane, warning overlay on.
	var eye := Vector3(40.0, 1.55, 3.6)
	var chaser := GhostCast3D.figure(village, "drowned_m")
	chaser.global_position = Vector3(37.4, 0, 3.2)
	_stare(chaser, eye)
	await _shot(village, "scene_chaser", eye, Vector3(37.4, 1.2, 3.2), 0.8)
	chaser.queue_free()
	# The fog figure at the west edge (third try of the day).
	var loop := village.get_node("WorldEdgeLoop") as WorldEdgeLoop3D
	var signs := loop.find_children("*", "VillageFogSigns3D", false, false)[0] as VillageFogSigns3D
	signs.show_sign(3, -1.0, WorldEdgeLoop3D.WEST_MOUTH, loop.west_z)
	var fog_eye := Vector3(WorldEdgeLoop3D.WEST_MOUTH - 7.0, 1.55, 5.0)
	await _shot(village, "scene_fog_figure", fog_eye, Vector3(WorldEdgeLoop3D.WEST_MOUTH - 13.0, 1.0, loop.west_z.x + 0.6))
	signs._clear()
	# The extra person by the parked bikes.
	var extra := UncannyScene3D.extra_figure(village, UncannyVillage3D.EXTRA_FIGURE, UncannyVillage3D.EXTRA_FIGURE + Vector3(0, 0, -3))
	extra.visible = true
	var street_eye := UncannyVillage3D.EXTRA_FIGURE + Vector3(4.5, 1.55, -2.5)
	_stare(extra, street_eye)
	await _shot(village, "scene_extra_person", street_eye, UncannyVillage3D.EXTRA_FIGURE + Vector3(0, 1.1, 0))
	extra.queue_free()
	# The pier-head ma da, from behind on the pier.
	if village.dock_omens == null:
		village.dock_omens = VillageBuilder3D.build_dock_omens(village)
	var dock := village.dock_omens
	var ma_da := GhostCast3D.figure(dock, "ma_da")
	ma_da.position = dock.pier_post + Vector3(-0.8, 0, 0.1)
	ma_da.rotation.y = PI
	var at := ma_da.global_position
	await _shot(village, "scene_pier_figure", at + Vector3(0.7, 1.55, 4.0), at + Vector3(0, 1.0, 0))
	ma_da.queue_free()
	# The three faces (wrong night / caught).
	_camera.global_position = Vector3(40.0, 1.55, 3.6)
	_camera.look_at(Vector3(30.0, 1.4, 3.6))
	for variant in 3:
		var face := WrongNightScare3D.show_face(village, variant)
		await _shot(village, "scene_face_%d" % variant, _camera.global_position, _camera.global_position + -_camera.global_basis.z)
		face.queue_free()
	village.queue_free()
	await _wait(0.2)
	await _sea()
	UncannyDirector.bot = false
	print("PASS horror cast scenes captured -> ", DIR)
	get_tree().quit()


## Đêm âm: a drowned person standing on the water, and a head swimming.
func _sea() -> void:
	var sea := load("res://scenes/sea3d/sea_scene_3d.tscn").instantiate() as Node3D
	add_child(sea)
	sea.set_process(false)
	sea.set_physics_process(false)
	await _wait(0.8)
	var boat := sea.get("boat") as Node3D
	var eye := boat.global_position + Vector3(0, 1.3, 0)
	for kind: DarkNightFigure3D.Kind in [DarkNightFigure3D.Kind.STAND, DarkNightFigure3D.Kind.SWIM]:
		var figure := DarkNightFigure3D.new()
		figure.kind = kind
		sea.add_child(figure)
		figure.global_position = Vector3(eye.x - 1.2, SeaWater3D.WATER_Y, eye.z - 4.5)
		figure.rotation.y = atan2(eye.x - figure.global_position.x, eye.z - figure.global_position.z)
		figure.set_process(false)
		var name_ := "scene_sea_stand" if kind == DarkNightFigure3D.Kind.STAND else "scene_sea_swim"
		_camera.make_current()
		_camera.global_position = eye
		_camera.look_at(figure.global_position + Vector3(0.9, 0.9, 0))
		await _wait(0.6)
		get_viewport().get_texture().get_image().save_png(DIR + "/" + name_ + ".png")
		figure.queue_free()
	sea.queue_free()


func _stare(rig: PersonRig3D, eye: Vector3) -> void:
	UncannyMoves3D.face_dir(rig, eye - rig.global_position)
	GhostCast3D.actor_of(rig).stare_at(_camera, 150.0, 0.0)


func _shot(village: VillageScene3D, name_: String, eye: Vector3, at: Vector3, warning := 0.0) -> void:
	_camera.make_current()
	_camera.global_position = eye
	_camera.look_at(at)
	village.lighting.set_inside(VillageLayout3D.in_room(eye))
	village.player.global_position = Vector3(eye.x, 0, eye.z)
	var left := 0.6
	while left > 0.0:
		if warning > 0.0:
			ProximityFx3D.of(village).push(warning)
		await get_tree().process_frame
		left -= get_process_delta_time()
	get_viewport().get_texture().get_image().save_png(DIR + "/" + name_ + ".png")


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
