extends Node
## Run headless as a scene so project autoloads are present.

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameState.reset()
	var bridge := load("res://scenes/story3d/story_bridge_3d.tscn").instantiate() as StoryBridge3D
	add_child(bridge)
	var branch := Cutscene.new()
	branch.id = "story3d_branch_smoke"
	branch.script_text = "set_flag story3d_route\nif_flag story3d_route yes\nset_flag story3d_wrong\ngoto end\nlabel yes\nset_flag story3d_right\nlabel end"
	await bridge.play(branch)
	if not GameState.has_flag("story3d_right") or GameState.has_flag("story3d_wrong") or not DialogueLibrary.is_seen(branch):
		_fail("branch or seen flag was not persisted in GameState")
		return
	if get_tree().paused:
		_fail("world stayed paused after a completed story")
		return
	var skipped := Cutscene.new()
	skipped.id = "story3d_skip_smoke"
	skipped.script_text = "speak Rin \"Dòng thử.\"\nchoice \"Chọn\" yes \"Bỏ\" no\nlabel yes\nset_flag story3d_skip_choice\ngoto end\nlabel no\nset_flag story3d_wrong_choice\nlabel end"
	bridge.play(skipped)
	await get_tree().process_frame
	bridge._dialogue.skipped.emit()
	bridge._dialogue._advanced.emit()
	for i in 8:
		if not bridge.playing:
			break
		await get_tree().process_frame
	if bridge.playing or not GameState.has_flag("story3d_skip_choice") or GameState.has_flag("story3d_wrong_choice") or not DialogueLibrary.is_seen(skipped):
		_fail("skip did not resolve choice, flag and seen state")
		return
	if get_tree().paused:
		_fail("skip left world paused")
		return
	print("PASS story3d branch, seen flag, skip choice and pause restoration")
	get_tree().quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	get_tree().paused = false
	get_tree().quit(1)
