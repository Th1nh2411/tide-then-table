class_name FirstPersonView3D
extends Node
## First-person view for the 3D village map, restaurant and sea (SceneRouter adds it at
## start; F10 in debug builds toggles it): a camera at Rin's eyes, mouse look, his
## own body hidden from it. Restaurant: it becomes the host's `demo_camera`,
## so WASD already walks where he looks. Sea: the look turns with the boat and
## the boat lamp follows it like a hand lamp; fishing stays in this view
## (Fishing3D). Hold Alt (or open a
## panel) for the mouse cursor. Removing the node restores everything.

const HIDDEN_LAYER := 1 << 19  # Rin's own mesh: drawn for others, not for this camera
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
## look_toward(): yaw / pitch from -> to over _turn_time; mouse motion ends it.
var _turn_from := Vector2.ZERO
var _turn_to := Vector2.ZERO
var _turn_time := 0.0
var _turn_left := 0.0


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
	if _scene and event.is_action_pressed("notebook") and not get_tree().paused: RinNotebook.open(_scene)
	var motion := event as InputEventMouseMotion
	if motion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var speed := GameSettings.mouse_speed()  # sensitivity + invert Y (Cài đặt)
		_turn_left = 0.0  # the player looks for himself
		_yaw -= motion.relative.x * speed.x
		_pitch = clampf(_pitch - motion.relative.y * speed.y, -1.35, 1.35)


## Turns the look by `radians` (the alley gate's fog loop turns Rin round).
func turn(radians: float) -> void:
	_yaw += radians


## Turns the view smoothly (eased) to face `point` (a speaker's head) over
## `seconds`; nothing is locked, moving the mouse takes over at once. False
## (no turn) while paused / in a menu or while the line is out fishing.
func look_toward(point: Vector3, seconds: float = 0.3) -> bool:
	if _scene == null or get_tree().paused or _fishing():
		return false
	var to := point - _camera.global_position
	var flat := Vector2(to.x, to.z).length()
	if flat < 0.05:
		return false
	var base := (_scene as SeaScene3D).boat.global_rotation.y if _scene is SeaScene3D else 0.0
	var yaw := atan2(-to.x, -to.z) - base
	_turn_from = Vector2(_yaw, _pitch)
	_turn_to = Vector2(_yaw + wrapf(yaw - _yaw, -PI, PI), clampf(atan2(to.y, flat), -0.7, 0.7))
	_turn_time = maxf(seconds, 0.01)
	_turn_left = _turn_time
	return true


## A look_toward() turn is still going.
func turning() -> bool:
	return _turn_left > 0.0


func _fishing() -> bool:
	var fishing := _scene.get_node_or_null("Fishing")
	return fishing != null and fishing.has_method("line_out") and bool(fishing.call("line_out"))


func _step_turn(delta: float) -> void:
	if _turn_left <= 0.0:
		return
	_turn_left = maxf(_turn_left - delta, 0.0)
	var t := smoothstep(0.0, 1.0, 1.0 - _turn_left / _turn_time)
	_yaw = lerpf(_turn_from.x, _turn_to.x, t)
	_pitch = lerpf(_turn_from.y, _turn_to.y, t)


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_detach()
		_attach(scene)
	if _scene == null:
		return
	if not _camera.current:
		_camera.make_current()
	_update_mouse()
	_step_turn(delta)
	if _walks(_scene):
		_follow_walker(_scene)
	elif _scene is SeaScene3D:
		_follow_sea(_scene as SeaScene3D)


func _attach(scene: Node) -> void:
	if not (_walks(scene) or scene is SeaScene3D):
		return
	_scene = scene
	if _walks(scene):
		_game_camera = scene.get("demo_camera")
		scene.set("demo_camera", _camera)
		_camera.far = 260.0  # the village bay and its islands
		# Restaurant: facing the shop front (-Z); village: the scene's start_yaw.
		var yaw: Variant = scene.get("start_yaw")
		_yaw = float(yaw) if yaw != null else 0.0
		var body := scene.get("body") as Node
		if body:
			for child in body.get_children():
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
		if _walks(_scene) and is_instance_valid(_game_camera):
			_scene.set("demo_camera", _game_camera)
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
	# Rest card, menus and the 2D scenes need the cursor.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Rin's own body (not the paddle or a carried plate) leaves this camera's view.
func _hide_meshes(root: Node) -> void:
	for node in root.find_children("*", "VisualInstance3D", true, false):
		if node.get_parent().name == "Paddle" or node.get_parent().get_parent().name == "Paddle":
			continue
		var mesh := node as VisualInstance3D
		mesh.layers = HIDDEN_LAYER
		_hidden.append(mesh)


func _update_mouse() -> void:
	var busy := get_tree().paused or Input.is_key_pressed(KEY_ALT)
	if _scene is RestaurantScene3D and (_scene as RestaurantScene3D).modal_open():
		busy = true
	var mode := Input.MOUSE_MODE_VISIBLE if busy else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != mode:
		Input.mouse_mode = mode


## Scenes where Rin walks with WASD relative to `demo_camera` (the village
## map, which is a RestaurantScene3D, and the restaurant alone).
func _walks(scene: Node) -> bool:
	return scene is RestaurantScene3D


func _follow_walker(room: Node) -> void:
	var player := room.get("player") as Node3D
	if player == null:
		return
	# A scene may move the eye / hold the pitch for a moment (the village's nightmare wake).
	var offset: Variant = room.get("eye_offset")
	_camera.global_position = player.global_position + EYE_RESTAURANT + (offset as Vector3 if offset is Vector3 else Vector3.ZERO)
	var held: Variant = room.get("held_pitch")
	if held is float and not is_nan(held as float):
		_pitch = held as float
	_camera.global_rotation = Vector3(_pitch, _yaw, 0)


func _follow_sea(sea: SeaScene3D) -> void:
	if sea.rin_figure.is_empty() or not is_instance_valid(sea.rin_figure[0]):
		return
	var rider := sea.rin_figure[0] as Node3D
	var boat_yaw := sea.boat.global_rotation.y
	_camera.global_position = rider.global_position + Vector3(0, EYE_SEA, 0)
	_camera.global_rotation = Vector3(_pitch, boat_yaw + _yaw, 0)
	if is_instance_valid(_lamp):
		# Hand lamp: shines where Rin looks, a little lower.
		var aim := Basis.from_euler(Vector3(_pitch - 0.25, boat_yaw + _yaw, 0))
		_lamp.global_basis = aim
