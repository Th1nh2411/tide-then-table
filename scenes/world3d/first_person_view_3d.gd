class_name FirstPersonView3D
extends Node
## Trial first-person view (SceneRouter toggles it with F10 in debug builds)
## for the 3D restaurant and sea: a camera at Rin's eyes, mouse look, his
## own body hidden from it. Restaurant: it becomes the host's `demo_camera`,
## so WASD already walks where he looks. Sea: the look turns with the boat and
## the boat lamp follows it like a hand lamp. Cutscenes and the cast
## cinematic get the game camera back while they play. Hold Alt (or open a
## panel) for the mouse cursor. Removing the node restores everything.

const HIDDEN_LAYER := 1 << 19  # Rin's own mesh: drawn for others, not for this camera
const MOUSE_SPEED := 0.0025
const EYE_RESTAURANT := Vector3(0, 1.55, 0)
const EYE_SEA := 1.3  # above the rider's feet (rider is scaled 0.85)

var _camera := Camera3D.new()
var _scene: Node
var _game_camera: Camera3D
var _yaw := 0.0
var _pitch := -0.15
var _hidden: Array[VisualInstance3D] = []
var _lamp: SpotLight3D
var _lamp_home := Transform3D()
var _cutscene := false
var _links: Array = []  # [StoryBridge3D, started callable, finished callable]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 900  # after the game moved Rin / the boat this frame
	_camera.fov = 72.0
	_camera.near = 0.05
	_camera.cull_mask = 0xFFFFF & ~HIDDEN_LAYER
	add_child(_camera)


func _exit_tree() -> void:
	_detach()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= motion.relative.x * MOUSE_SPEED
		_pitch = clampf(_pitch - motion.relative.y * MOUSE_SPEED, -1.35, 1.35)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_detach()
		_attach(scene)
	if _scene == null:
		return
	var handed_back := _cutscene or (_scene is SeaScene3D and (_scene as SeaScene3D).fishing)
	if handed_back:
		if _camera.current and is_instance_valid(_game_camera):
			_game_camera.make_current()
	elif not _camera.current:
		_camera.make_current()
	_update_mouse(handed_back)
	if _scene is RestaurantScene3D:
		_follow_restaurant(_scene as RestaurantScene3D)
	elif _scene is SeaScene3D:
		_follow_sea(_scene as SeaScene3D)


func _attach(scene: Node) -> void:
	if not (scene is RestaurantScene3D or scene is SeaScene3D):
		return
	_scene = scene
	for bridge in scene.find_children("*", "Node", true, false):
		if bridge is StoryBridge3D:
			var on_start := _on_cutscene.bind(true)
			var on_end := _on_cutscene.bind(false)
			(bridge as StoryBridge3D).started.connect(on_start)
			(bridge as StoryBridge3D).finished.connect(on_end)
			_links.append([bridge, on_start, on_end])
	if scene is RestaurantScene3D:
		var room := scene as RestaurantScene3D
		_game_camera = room.demo_camera
		room.demo_camera = _camera
		_camera.far = 80.0
		_yaw = 0.0  # facing the shop front (-Z)
		for child in room.body.get_children():
			if child is RinPilotVisual:
				_hide_meshes(child)
	else:
		var sea := scene as SeaScene3D
		_game_camera = sea.camera
		_camera.far = 300.0
		_yaw = 0.0
		for rider in sea.rin_figure:
			_hide_meshes(rider)
		# The lamp post on the boat would sit in the middle of the view; the lamp is in his hand now.
		for child in sea.boat_visual.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).layers = HIDDEN_LAYER
				_hidden.append(child)
		_lamp = sea.boat_lamp
		if is_instance_valid(_lamp):
			_lamp_home = _lamp.transform
	_camera.make_current()


func _detach() -> void:
	if is_instance_valid(_scene):
		if _scene is RestaurantScene3D and is_instance_valid(_game_camera):
			(_scene as RestaurantScene3D).demo_camera = _game_camera
	for link: Array in _links:
		if is_instance_valid(link[0]):
			var bridge := link[0] as StoryBridge3D
			bridge.started.disconnect(link[1])
			bridge.finished.disconnect(link[2])
	_links.clear()
	for mesh in _hidden:
		if is_instance_valid(mesh):
			mesh.layers &= ~HIDDEN_LAYER
			mesh.layers |= 1
	_hidden.clear()
	if is_instance_valid(_lamp):
		_lamp.transform = _lamp_home
	_lamp = null
	if is_instance_valid(_game_camera):
		_game_camera.make_current()
	_scene = null
	_game_camera = null
	_cutscene = false


## Rin's own body (not the paddle or a carried plate) leaves this camera's view.
func _hide_meshes(root: Node) -> void:
	for node in root.find_children("*", "VisualInstance3D", true, false):
		if node.get_parent().name == "Paddle" or node.get_parent().get_parent().name == "Paddle":
			continue
		var mesh := node as VisualInstance3D
		mesh.layers = HIDDEN_LAYER
		_hidden.append(mesh)


func _on_cutscene(_cutscene_res: Cutscene, playing: bool) -> void:
	_cutscene = playing
	if playing and is_instance_valid(_game_camera):
		_game_camera.make_current()  # the stage frames its shots from the game camera


func _update_mouse(handed_back: bool) -> void:
	var busy := handed_back or get_tree().paused or Input.is_key_pressed(KEY_ALT)
	if _scene is RestaurantScene3D and (_scene as RestaurantScene3D).modal_open():
		busy = true
	var mode := Input.MOUSE_MODE_VISIBLE if busy else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != mode:
		Input.mouse_mode = mode


func _follow_restaurant(room: RestaurantScene3D) -> void:
	_camera.global_position = room.player.global_position + EYE_RESTAURANT
	_camera.global_rotation = Vector3(_pitch, _yaw, 0)


func _follow_sea(sea: SeaScene3D) -> void:
	if sea.rin_figure.is_empty() or not is_instance_valid(sea.rin_figure[0]):
		return
	var rider := sea.rin_figure[0] as Node3D
	var boat_yaw := sea.boat.global_rotation.y
	_camera.global_position = rider.global_position + Vector3(0, EYE_SEA, 0)
	_camera.global_rotation = Vector3(_pitch, boat_yaw + _yaw, 0)
	if is_instance_valid(_lamp) and not sea.fishing:
		# Hand lamp: shines where Rin looks, a little lower.
		var aim := Basis.from_euler(Vector3(_pitch - 0.25, boat_yaw + _yaw, 0))
		_lamp.global_basis = aim
