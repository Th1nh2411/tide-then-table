extends Node

func _ready() -> void:
	var bot: Node = load("res://tools/bot/game_bot.gd").new()
	# Do not start its autonomous full run in this isolated regression.
	bot.set_script(null)
	bot.free()
	var dialogue := DialogueBox.new()
	add_child(dialogue)
	var resolved: Array[int] = []
	_choose(dialogue, resolved)
	for node in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var box := node as DialogueBox
		if box and box.visible and box._choice_count > 0:
			(box._choices.get_child(0) as Button).pressed.emit()
			break
	print("PASS bot selects actual dialogue button" if resolved == [0] else "FAIL bot choice unresolved")
	get_tree().quit(0 if resolved == [0] else 1)

func _choose(dialogue: DialogueBox, result: Array[int]) -> void:
	result.append(await dialogue.choose(PackedStringArray(["Nhận Vy làm luôn", "Để anh tính"])))
