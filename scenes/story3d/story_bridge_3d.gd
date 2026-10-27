class_name StoryBridge3D
extends Node
## Plays existing Cutscene story logic and dialogue over a 3D world.
## Physical actor/camera commands need authored 3D markers and are skipped here.

signal started(cutscene: Cutscene)
signal finished(cutscene: Cutscene)

var playing := false
var _skipping := false
var _was_paused := false
var _dialogue: DialogueBox
var _name_prompt: CutsceneNamePrompt
var _fade: ColorRect
var _moods: Dictionary = {}

const EMOTE_MOODS := {"!": "ngac_nhien", "?": "boi_roi", "...": "buon", "heart": "vui", "note": "vui"}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 23
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	_dialogue.skipped.connect(func() -> void: _skipping = true)
	_name_prompt = CutsceneNamePrompt.new()
	add_child(_name_prompt)

func play_eligible(cutscenes: Array[Cutscene]) -> bool:
	var chosen := DialogueLibrary.pick(cutscenes) as Cutscene
	if chosen == null:
		return false
	await play(chosen)
	return true

func play(cutscene: Cutscene) -> void:
	if playing or cutscene == null:
		return
	playing = true
	_skipping = false
	_was_paused = get_tree().paused
	get_tree().paused = true
	_dialogue.hold_pause = true
	_moods.clear()
	started.emit(cutscene)
	var commands := CutsceneScript.parse(cutscene.script_text)
	var labels := CutsceneScript.labels(commands)
	var index := 0
	while index < commands.size():
		var command: Dictionary = commands[index]
		index += 1
		var jump: String = await _execute(command)
		if jump != "":
			index = int(labels.get(jump, commands.size())) + 1
	DialogueLibrary.mark_done(cutscene)
	_dialogue.hold_pause = false
	_dialogue.hide()
	_fade.color.a = 0.0
	get_tree().paused = _was_paused
	playing = false
	finished.emit(cutscene)

func _unhandled_input(event: InputEvent) -> void:
	if playing and not _name_prompt.visible and event.is_action_pressed("pause"):
		_skipping = true
		get_viewport().set_input_as_handled()

func _execute(command: Dictionary) -> String:
	var args: PackedStringArray = command["args"]
	match command["cmd"]:
		"speak", "narrate":
			if not _skipping:
				var speaker := args[0] if command["cmd"] == "speak" else ""
				_dialogue.show_line(_with_mood(speaker), args[args.size() - 1])
				await _dialogue.await_advance()
		"choice":
			var options := PackedStringArray()
			var targets := PackedStringArray()
			for i in range(0, args.size() - 1, 2):
				options.append(args[i])
				targets.append(args[i + 1])
			if targets.is_empty():
				return ""
			var chosen := 0
			if not _skipping:
				chosen = await _dialogue.choose(options)
			return targets[clampi(chosen, 0, targets.size() - 1)]
		"goto":
			return args[0] if not args.is_empty() else ""
		"if_flag":
			return args[1] if args.size() >= 2 and GameState.has_flag(args[0]) else ""
		"set_flag":
			if not args.is_empty():
				GameState.set_flag(args[0])
		"name_pet":
			var pet := args[0] if not args.is_empty() else "Mèo"
			if not _skipping:
				pet = await _name_prompt.ask(pet)
			GameState.set_flag("pet_name", pet)
		"emote":
			if args.size() >= 2 and EMOTE_MOODS.has(args[1]):
				_moods[DialoguePortrait.slug(args[0])] = EMOTE_MOODS[args[1]]
		"sfx":
			if not _skipping and not args.is_empty():
				Sfx.play(args[0])
		"ambience":
			if not args.is_empty():
				Sfx.ambience("" if args[0] == "none" else args[0])
		"pause":
			if not _skipping:
				await get_tree().create_timer(_seconds(args, 0, 0.5), true).timeout
		"fade_out":
			await _fade_to(1.0, _seconds(args, 0, 0.5))
		"fade_in":
			await _fade_to(0.0, _seconds(args, 0, 0.5))
		# Actor movement, camera markers, tint and rain need 3D staging data.
		"camera", "spawn", "remove", "move_to", "face", "tint", "rain", "slow", "label":
			pass
		_:
			push_warning("StoryBridge3D: unknown command '%s' at line %d" % [command["cmd"], command["line"]])
	return ""

func _with_mood(speaker: String) -> String:
	if speaker == "" or speaker.ends_with(")"):
		return speaker
	var id := "cat" if speaker == "{pet}" or speaker == "Mèo" else DialoguePortrait.slug(speaker)
	if not _moods.has(id):
		return speaker
	var mood: String = _moods[id]
	_moods.erase(id)
	return "%s (%s)" % [speaker, mood]

func _seconds(args: PackedStringArray, index: int, fallback: float) -> float:
	return float(args[index]) if index < args.size() and args[index].is_valid_float() else fallback

func _fade_to(alpha: float, seconds: float) -> void:
	if _skipping or seconds <= 0.0:
		_fade.color.a = alpha
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", alpha, seconds)
	await tween.finished
