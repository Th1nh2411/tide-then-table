class_name SubtitleLine
extends RefCounted
## Pure: one subtitle request -> the line SpeechStrip shows, and the queue
## rules shared by every source (Subtitles): a spoken line (named speaker or a
## dead voice) beats an ambient one; ambient lines never wait in the queue;
## the same line is never queued twice.

enum Action { SHOW, QUEUE, DROP }


## `opts`: "seconds", "dead", "name", "key", "ambient" (bool), "fallback"
## (speaker for unnamed lines, overrides `default_speaker`).
static func resolve(speakers: SpeakerTable, default_speaker: String, speaker: String, text: String, opts: Dictionary) -> Dictionary:
	var dead := speakers.is_dead(speaker) or (speaker == "" and speakers.is_dead_whisper(text))
	if opts.has("dead"):
		dead = bool(opts["dead"])
	var fallback: String = str(opts.get("fallback", default_speaker))
	var who := speaker if speaker != "" or dead else fallback
	var shown: String = str(opts.get("name", speakers.dead_label if dead else who))
	var key: String = str(opts.get("key", (speaker + ": " + text) if speaker != "" else text))
	var seconds: Variant = opts.get("seconds", 4.0)
	var ambient := bool(opts.get("ambient", false)) and not dead and speaker == ""
	return {"key": key, "name": shown, "who": who, "text": text, "dead": dead, "ambient": ambient,
		"seconds": float(seconds) if (seconds is float or seconds is int) else 4.0}


## What to do with `line` given the one on screen (empty = none) and the queue.
static func decide(line: Dictionary, showing: Dictionary, queue: Array[Dictionary]) -> Action:
	var key: String = line["key"]
	if (not showing.is_empty() and showing["key"] == key) or queue.any(func(item: Dictionary) -> bool: return item["key"] == key):
		return Action.DROP
	if showing.is_empty():
		return Action.SHOW
	if bool(line["ambient"]):
		return Action.DROP  # busy: an ambient line never stacks
	if bool(showing["ambient"]):
		return Action.SHOW  # spoken cuts the ambient line short
	return Action.QUEUE
