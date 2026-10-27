extends Node2D
## F6: actual CutsceneActor / Customer renderers. O/K opens each new portrait.

var _poi: PoiDialog
var _dialogue: DialogueBox


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveSystem.autosave_off = true
	RenderingServer.set_default_clear_color(Color("253a5e"))
	var kinds: Array[String] = ["crate", "rin_bed", "rin_faint", "glow"]
	for index in kinds.size():
		var actor := CutsceneActor.new()
		actor.kind = kinds[index]
		actor.position = Vector2(65 + index * 155, 100)
		actor.art_scale = 1.0 if actor.kind == "glow" else 2.0
		add_child(actor)
	for index in 6:
		var guest := Customer.new()
		guest.rich = index < 3
		guest.regular_name = "Khách quen" if index >= 3 else ""
		guest.position = Vector2(65 + index * 102, 270)
		guest.scale = Vector2(2, 2)
		guest.state = Customer.State.READING if index % 3 == 1 else Customer.State.DINING
		if index % 3 == 0:
			guest.state = Customer.State.WALKING_IN
			guest.facing = Vector2i.LEFT
			guest._path = [guest.position + Vector2(10, 0)]
			guest._walk_time = 0.2
		elif index % 3 == 2:
			guest.plate = DishShelf.Plate.new()
		add_child(guest)
		guest.label = ""
		guest.process_mode = Node.PROCESS_MODE_DISABLED
		guest.queue_redraw()
	_poi = PoiDialog.new()
	add_child(_poi)
	_dialogue = DialogueBox.new()
	add_child(_dialogue)
	if "--capture-asset-preview" in OS.get_cmdline_user_args():
		await _capture("secondary_art_preview")
		_show_old_man()
		await _capture("ong_tam_poi_preview")
		_poi._answered.emit(-1)
		_show_regular()
		await _capture("khach_quen_dialogue_preview")
		SceneRouter.quit_game()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or _poi.is_open() or _dialogue.is_open():
		return
	if event.as_text() == "O":
		_show_old_man()
	elif event.as_text() == "K":
		_show_regular()


func _show_old_man() -> void:
	_poi.ask("Chòi ông Tám", "Ông Tám ngồi vá lưới dưới ngọn đèn dầu.\n\"Ra trễ vậy con?\"",
		PackedStringArray(["Nhờ vá thuyền (+25 bền, 40k)", "Hỏi chuyện", "Đi tiếp"]), "ong_tam")


func _show_regular() -> void:
	_dialogue.play_lines(DialogueLibrary.parse("Khách quen: Con cá đó nướng vừa tới. Lâu lắm rồi mới ăn được cá ngoài khơi ngon vậy."))
	_dialogue._text_label.visible_characters = -1


func _capture(name: String) -> void:
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build/shots")
	var error := get_viewport().get_texture().get_image().save_png("res://build/shots/%s.png" % name)
	print("Secondary art capture: ", name, " ", error_string(error))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var kinds: Array[String] = ["crate", "rin_bed", "rin_faint", "glow"]
	for index in kinds.size():
		draw_string(font, Vector2(25 + index * 155, 40), kinds[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	for index in 6:
		var labels: Array[String] = ["Đi", "Chờ", "Ăn"]
		draw_string(font, Vector2(48 + index * 102, 310), labels[index % 3], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(font, Vector2(35, 190), "Khách sang", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(font, Vector2(350, 190), "Khách quen", HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(font, Vector2(35, 345), "O: ông Tám / K: khách quen / Esc: đóng thoại", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
