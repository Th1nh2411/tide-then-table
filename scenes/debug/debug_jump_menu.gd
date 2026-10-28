class_name DebugJumpMenu
extends CanvasLayer
## Debug builds, F9 anywhere (SceneRouter): jump to any day's night at sea or
## day at the restaurant, or to any cutscene. The game state is rebuilt by
## StoryTimeline as if the story ran up to that point; autosave stays off for
## the rest of the session so the real save is never overwritten.
## Pauses the game while open. Built in code.

const FONT_SIZE: int = 10
const MAX_DAY: int = 10

var _was_paused: bool = false
var _day: SpinBox


func _ready() -> void:
	layer = 98  # over the game and its dialogs, under PalettePreview / the fade
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(140, 20)
	panel.custom_minimum_size = Vector2(360, 320)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label("DEBUG: nhảy tới  (F9 / Esc đóng)"))
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_child(_label("Ngày"))
	_day = SpinBox.new()
	_day.min_value = 1
	_day.max_value = MAX_DAY
	_day.value = GameState.day
	_day.get_line_edit().add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(_day)
	row.add_child(_button("Đêm (biển)", _jump_to_day.bind(StoryTimeline.Slot.SEA)))
	row.add_child(_button("Quán", _jump_to_day.bind(StoryTimeline.Slot.ARRIVAL)))
	box.add_child(_label("Cutscene:"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for cutscene in StoryTimeline.load_all():
		var at := StoryTimeline.when(cutscene)
		var text := "Ngày %d · %s · %s" % [at[0], StoryTimeline.SLOT_NAMES[at[1]], cutscene.id]
		list.add_child(_button(text, _jump_to_cutscene.bind(cutscene)))
	var note := _label("Sau khi nhảy, game không tự lưu nữa (tới khi tắt game).")
	note.modulate = Color(1, 0.8, 0.4)
	box.add_child(note)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	get_tree().paused = _was_paused
	queue_free()


func _jump_to_day(slot: StoryTimeline.Slot) -> void:
	_go(StoryTimeline.prepare(int(_day.value), slot), null)


func _jump_to_cutscene(cutscene: Cutscene) -> void:
	_go(StoryTimeline.prepare_for(cutscene), cutscene)


## Intro / restaurant-arrival cutscenes play by themselves once the state is
## right; trip-end and after-shift ones are played here after the fade.
func _go(path: String, cutscene: Cutscene) -> void:
	SaveSystem.autosave_off = true
	print("[debug] jump: day %d -> %s %s" % [GameState.day, path.get_file(), cutscene.id if cutscene else ""])
	# Hidden, not freed yet: this coroutine still has to run after the fade.
	visible = false
	set_process_unhandled_input(false)
	get_tree().paused = false
	SceneRouter.go_to(path)
	if cutscene and not StoryTimeline.plays_by_itself(cutscene):
		await SceneRouter.scene_changed
		var player := get_tree().current_scene.get_node_or_null("CutscenePlayer") as CutscenePlayer
		if player and not player.playing:
			player.play(cutscene)
		else:
			var bridge: Variant = get_tree().current_scene.get("story_bridge")
			if bridge is StoryBridge3D and not bridge.playing:
				bridge.play(cutscene)
	queue_free()


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.pressed.connect(action)
	return button
