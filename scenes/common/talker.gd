class_name Talker
extends Node
## Makes its parent someone Rin can talk to. Add it as a child of a character
## node that has `talk_x() -> float` (where it stands) and optionally
## `can_talk() -> bool`. Picks the next story conversation (DialogueLibrary),
## or a random small-talk line when there's nothing new.

@export var display_name: String = ""
@export var dialogues: Array[Dialogue] = []
## Small talk once every conversation is used up (random each time).
@export_multiline var idle_lines: Array[String] = []


func _ready() -> void:
	add_to_group("talkers")


func talk_x() -> float:
	return get_parent().call("talk_x")


func can_talk() -> bool:
	var owner_node := get_parent()
	return owner_node.call("can_talk") if owner_node.has_method("can_talk") else true


## True if a new (story) conversation is waiting — shown as a "!" marker.
func has_news() -> bool:
	return DialogueLibrary.pick(dialogues) != null


## Plays the next conversation (or small talk) in `box`.
func talk(box: DialogueBox) -> void:
	var dialogue := DialogueLibrary.pick(dialogues)
	if dialogue:
		await box.play(dialogue)
	elif not idle_lines.is_empty():
		var line: Array[Dictionary] = [{"speaker": display_name, "text": idle_lines.pick_random()}]
		await box.play_lines(line)
