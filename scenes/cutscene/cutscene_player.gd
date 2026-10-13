class_name CutscenePlayer
extends Node2D
## Plays Cutscenes Stardew Valley style, in the world: pauses the game, hides
## the HUD, moves its own camera between markers (children of `markers`),
## spawns CutsceneActors, shows dialogue / choices (DialogueBox) and fades.
## Esc skips: the rest runs instantly, keeping the effects that matter
## (flags, the pet's default name, the first answer of a choice).
## Command list: see CutsceneScript. Camera + markers: CutsceneCamera; the
## cat's name box: CutsceneNamePrompt; rain / slow-mo: CutsceneEffects.
## An `emote` gives that actor's next line a portrait mood ("!" surprised...).

signal started
signal finished

## Emote symbol -> portrait mood for the actor's next line.
const EMOTE_MOODS := {"!": "ngac_nhien", "?": "boi_roi", "...": "buon", "heart": "vui", "note": "vui"}

@export var markers: Node2D
@export var day_tint: DayTint
## Nodes hidden while a cutscene plays (HUD layers, the player character...).
## Things drawn inside another node (Rin on the boat) listen to `started` /
## `finished` and check `playing` instead.
@export var hidden_nodes: Array[Node] = []
## Groups hidden too (people added at runtime: staff, customers).
@export var hidden_groups: Array[StringName] = []
@export var name_max_length: int = 12
## Size of drawn art (Art) for actors: 1 = restaurant scale (people 16x32),
## 0.5 at sea (the sea camera zooms x2).
@export var actor_art_scale: float = 1.0

var playing: bool = false

var _skipping: bool = false
var _actors: Dictionary = {}  # name -> CutsceneActor
## portrait id -> mood from the last emote, used by that speaker's next line.
var _moods: Dictionary = {}
var _camera: CutsceneCamera
var _fade: ColorRect
var _dialogue: DialogueBox
var _name_prompt: CutsceneNamePrompt
var _effects: CutsceneEffects


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = CutsceneCamera.new()
	_camera.markers = markers
	add_child(_camera)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 23  # under the dialogue box (24)
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)
	_effects = CutsceneEffects.new()
	add_child(_effects)
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.skipped.connect(func() -> void: _skipping = true)
	_name_prompt = CutsceneNamePrompt.new()
	_name_prompt.max_length = name_max_length
	add_child(_name_prompt)


func play(cutscene: Cutscene) -> void:
	playing = true
	_skipping = false
	_dialogue.hold_pause = true
	var was_paused := get_tree().paused
	get_tree().paused = true
	var shown: Array[Node] = []
	var to_hide: Array[Node] = hidden_nodes.duplicate()
	for group in hidden_groups:
		to_hide.append_array(get_tree().get_nodes_in_group(group))
	for node in to_hide:
		if node.get("visible"):
			shown.append(node)
			node.set("visible", false)
	started.emit()
	_camera.begin()
	_moods.clear()

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
	_effects.reset()
	for actor: CutsceneActor in _actors.values():
		actor.queue_free()
	_actors.clear()
	_dialogue.hold_pause = false
	_dialogue.hide()
	for node in shown:
		if is_instance_valid(node):
			node.set("visible", true)
	_camera.end()
	get_tree().paused = was_paused
	playing = false
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if playing and not _name_prompt.visible and event.is_action_pressed("pause"):
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
			await _camera.move(_camera.marker(args[0]), _float(args, 1, 1.0), _float(args, 2, _camera.zoom.x), _skipping)
		"spawn":
			var actor := CutsceneActor.new()
			actor.kind = args[1]
			actor.art_scale = actor_art_scale
			actor.position = _camera.marker(args[2])
			actor.scale = Vector2.ONE * _float(args, 3, 1.0)
			add_child(actor)
			_actors[args[0]] = actor
		"move_to":
			var actor: CutsceneActor = _actors[args[0]]
			if _skipping:
				actor.position = _camera.marker(args[1])
			else:
				await actor.walk_to(_camera.marker(args[1]), _float(args, 2, 1.0))
		"face":
			(_actors[args[0]] as CutsceneActor).face(args[1])
		"emote":
			if EMOTE_MOODS.has(args[1]):
				_moods[DialoguePortrait.slug(args[0])] = EMOTE_MOODS[args[1]]
			if not _skipping:
				(_actors[args[0]] as CutsceneActor).emote(args[1], _float(args, 2, 1.0))
		"speak", "narrate":
			if not _skipping:
				var speaker := args[0] if command["cmd"] == "speak" else ""
				_dialogue.show_line(_with_mood(speaker), args[args.size() - 1])
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
		"rain":
			_effects.set_rain(args[0] == "on")
		"slow":
			if _skipping:
				_effects.reset()
			else:
				await _effects.slow(_float(args, 0, 1.0), _float(args, 1, 0.5))
		"sfx":
			if not _skipping:
				Sfx.play(args[0])
		"ambience":
			Sfx.ambience("" if args[0] == "none" else args[0])
		"if_flag":
			return args[1] if GameState.has_flag(args[0]) else ""
		"pause":
			if not _skipping:
				await get_tree().create_timer(_float(args, 0, 0.5), true).timeout
		"name_pet":
			var pet := args[0] if args.size() > 0 else "Mèo"
			if not _skipping:
				pet = await _name_prompt.ask(pet)
			GameState.set_flag("pet_name", pet)
		"set_flag":
			GameState.set_flag(args[0])
		"remove":
			var gone := _actors.get(args[0]) as Node
			if gone:
				gone.queue_free()
				_actors.erase(args[0])
		"label":
			pass
		_:
			push_warning("Unknown cutscene command '%s' (line %d)" % [command["cmd"], command["line"]])
	return ""


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


## "Rin" -> "Rin (ngac_nhien)" after `emote Rin !` (once).
func _with_mood(speaker: String) -> String:
	if speaker == "" or speaker.ends_with(")"):
		return speaker
	var id := "cat" if speaker == "{pet}" or speaker == "Mèo" else DialoguePortrait.slug(speaker)
	if not _moods.has(id):
		return speaker
	var mood: String = _moods[id]
	_moods.erase(id)
	return "%s (%s)" % [speaker, mood]
