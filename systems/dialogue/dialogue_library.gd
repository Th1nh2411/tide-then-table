class_name DialogueLibrary
extends RefCounted
## Pure helpers for dialogues: split a Dialogue's text into lines, pick which
## conversation plays now, and remember what was seen (GameState.story_flags,
## so it is saved). No nodes.

const SEEN_PREFIX: String = "dlg_"


## [{"speaker": String, "text": String}] — speaker "" = narration.
static func parse(script_text: String) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for raw in script_text.split("\n"):
		var line := raw.strip_edges()
		if line.is_empty():
			continue
		var colon := line.find(":")
		# A short prefix before ":" is a speaker name; longer means plain text.
		if colon > 0 and colon <= 16:
			lines.append({"speaker": line.left(colon).strip_edges(), "text": line.substr(colon + 1).strip_edges()})
		else:
			lines.append({"speaker": "", "text": line})
	return lines


static func is_seen(dialogue: Dialogue) -> bool:
	return GameState.has_flag(SEEN_PREFIX + dialogue.id)


static func can_play(dialogue: Dialogue) -> bool:
	if GameState.day < dialogue.min_day:
		return false
	if dialogue.requires_flag and not GameState.story_flags.has(dialogue.requires_flag):
		return false
	if dialogue.blocked_by_flag and GameState.story_flags.has(dialogue.blocked_by_flag):
		return false
	return not (dialogue.once and is_seen(dialogue))


## The eligible dialogue with the highest priority (first one on ties), or
## null. Works for any Dialogue array (Cutscenes too).
static func pick(dialogues: Array) -> Dialogue:
	var best: Dialogue = null
	for dialogue: Dialogue in dialogues:
		if can_play(dialogue) and (best == null or dialogue.priority > best.priority):
			best = dialogue
	return best


## Call when a dialogue finished playing.
static func mark_done(dialogue: Dialogue) -> void:
	GameState.set_flag(SEEN_PREFIX + dialogue.id)
	if dialogue.sets_flag:
		GameState.set_flag(dialogue.sets_flag)
