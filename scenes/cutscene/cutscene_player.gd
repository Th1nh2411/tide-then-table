class_name CutscenePlayer
extends Node2D
## Plays Cutscenes Stardew Valley style, in the world: pauses the game, hides
## the HUD, moves its own camera between markers (children of `markers`),
## spawns CutsceneActors, shows dialogue / choices (DialogueBox) and fades.
## Esc skips: the rest runs instantly, keeping the effects that matter
## (flags, the pet's default name, the first answer of a choice).
## Command list: see CutsceneScript.

signal finished

@export var markers: Node2D
@export var day_tint: DayTint
## Nodes hidden while a cutscene plays (HUD layers, the player character...).
@export var hidden_nodes: Array[Node] = []
@export var name_max_length: int = 12

var playing: bool = false

var _skipping: bool = false
var _actors: Dictionary = {}  # name -> CutsceneActor
var _camera: Camera2D
var _previous_camera: Camera2D
var _fade: ColorRect
var _dialogue: DialogueBox
var _name_layer: CanvasLayer
var _name_edit: LineEdit
signal _name_entered(text: String)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera2D.new()
	# Off until a cutscene plays: in a scene without a camera (restaurant) an
	# enabled Camera2D becomes current by itself and shifts the whole view.
	_camera.enabled = false
	add_child(_camera)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 23  # under the dialogue box (24)
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.skipped.connect(func() -> void: _skipping = true)
	_build_name_prompt()


func play(cutscene: Cutscene) -> void:
	playing = true
	_skipping = false
	_dialogue.hold_pause = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	var shown: Array[Node] = []
	for node in hidden_nodes:
		if node.get("visible"):
			shown.append(node)
			node.set("visible", false)
	_previous_camera = get_viewport().get_camera_2d()
	if _previous_camera:
		_camera.global_position = _previous_camera.get_screen_center_position()
		_camera.zoom = _previous_camera.zoom
	else:
		# UI scenes (restaurant) have no camera: start on the plain view.
		_camera.global_position = get_viewport_rect().size * 0.5
		_camera.zoom = Vector2.ONE
	_camera.enabled = true
	_camera.make_current()

	var commands := CutsceneScript.parse(cutscene.script_text)
	var labels := CutsceneScript.labels(commands)
	var i := 0
	while i < commands.size():
		var command := commands[i]
		i += 1
		var jump: String = await _run(command)
		if jump != "":
			i = int(labels.get(jump, commands.size())) + 1

	DialogueLibrary.mark_done(cutscene)
	for actor: CutsceneActor in _actors.values():
		actor.queue_free()
	_actors.clear()
	_dialogue.hold_pause = false
	_dialogue.hide()
	for node in shown:
		node.set("visible", true)
	if _previous_camera:
		_previous_camera.make_current()
	else:
		_camera.enabled = false
	get_tree().paused = was_paused
	playing = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if playing and not _name_layer.visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_skipping = true


## Runs one command; returns a label to jump to ("" = next line).
func _run(command: Dictionary) -> String:
	var args: PackedStringArray = command["args"]
	match command["cmd"]:
		"fade_out":
			await _fade_to(1.0, _float(args, 0, 1.0))
		"fade_in":
			await _fade_to(0.0, _float(args, 0, 1.0))
		"tint":
			if day_tint == null:
				return ""
			match args[0]:
				"dawn":
					day_tint.color = day_tint.dawn_color
				"day":
					day_tint.color = day_tint.day_color
				_:
					day_tint.color = day_tint.night_color
		"camera":
			await _move_camera(_marker(args[0]), _float(args, 1, 1.0), _float(args, 2, _camera.zoom.x))
		"spawn":
			var actor := CutsceneActor.new()
			actor.kind = args[1]
			actor.position = _marker(args[2])
			actor.scale = Vector2.ONE * _float(args, 3, 1.0)
			add_child(actor)
			_actors[args[0]] = actor
		"move_to":
			var actor: CutsceneActor = _actors[args[0]]
			if _skipping:
				actor.position = _marker(args[1])
			else:
				await actor.walk_to(_marker(args[1]), _float(args, 2, 1.0))
		"face":
			(_actors[args[0]] as CutsceneActor).face(args[1])
		"emote":
			if not _skipping:
				(_actors[args[0]] as CutsceneActor).emote(args[1], _float(args, 2, 1.0))
		"speak", "narrate":
			if not _skipping:
				var speaker := args[0] if command["cmd"] == "speak" else ""
				_dialogue.show_line(speaker, args[args.size() - 1])
				await _dialogue.await_advance()
		"choice":
			var options := PackedStringArray()
			var targets := PackedStringArray()
			for k in range(0, args.size() - 1, 2):
				options.append(args[k])
				targets.append(args[k + 1])
			var index := 0
			if not _skipping:
				index = await _dialogue.choose(options)
			return targets[index]
		"goto":
			return args[0]
		"pause":
			if not _skipping:
				await get_tree().create_timer(_float(args, 0, 0.5), true).timeout
		"name_pet":
			var pet := args[0] if args.size() > 0 else "Mèo"
			if not _skipping:
				pet = await _ask_name(pet)
			GameState.set_flag("pet_name", pet)
		"set_flag":
			GameState.set_flag(args[0])
		"label":
			pass
		_:
			push_warning("Unknown cutscene command '%s' (line %d)" % [command["cmd"], command["line"]])
	return ""


func _marker(marker_name: String) -> Vector2:
	var node := markers.get_node_or_null(marker_name) as Node2D
	if node == null:
		push_warning("Cutscene marker '%s' not found" % marker_name)
		return _camera.global_position
	return node.global_position


func _float(args: PackedStringArray, index: int, fallback: float) -> float:
	return float(args[index]) if index < args.size() and args[index].is_valid_float() else fallback


func _fade_to(alpha: float, seconds: float) -> void:
	if _skipping or seconds <= 0.0:
		_fade.color.a = alpha
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await tween.finished


func _move_camera(target: Vector2, seconds: float, zoom: float) -> void:
	if _skipping or seconds <= 0.0:
		_camera.global_position = target
		_camera.zoom = Vector2(zoom, zoom)
		return
	var tween := create_tween().set_parallel()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_camera, "global_position", target, seconds)
	tween.tween_property(_camera, "zoom", Vector2(zoom, zoom), seconds)
	await tween.finished


func _ask_name(default_name: String) -> String:
	_name_edit.text = default_name
	_name_layer.show()
	_name_edit.grab_focus()
	_name_edit.select_all()
	var entered: String = await _name_entered
	_name_layer.hide()
	entered = entered.strip_edges().left(name_max_length)
	return entered if entered != "" else default_name


func _build_name_prompt() -> void:
	_name_layer = CanvasLayer.new()
	_name_layer.layer = 26
	add_child(_name_layer)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name_layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var label := Label.new()
	label.text = "Đặt tên cho bé mèo:"
	label.add_theme_font_size_override("font_size", 11)
	box.add_child(label)
	_name_edit = LineEdit.new()
	_name_edit.max_length = name_max_length
	_name_edit.custom_minimum_size = Vector2(160, 0)
	_name_edit.text_submitted.connect(_name_entered.emit)
	box.add_child(_name_edit)
	var ok := Button.new()
	ok.text = "Xong (Enter)"
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(func() -> void: _name_entered.emit(_name_edit.text))
	box.add_child(ok)
	_name_layer.hide()
