class_name SpeakerTable
extends Resource
## Who speaks in the subtitles: name colours, and which speakers are dead
## (pale trembling text, slow, name shown as "..."). Writers mark a speaker
## dead by adding its name (or its slug, "ong_tu") to `dead`.

@export var colors: Dictionary = {}
@export var other_color := Color("c0503f")
@export var dead: PackedStringArray = []
## Unnamed lines wrapped in "..." ("...về đi...") are a dead voice too.
@export var unnamed_ellipsis_is_dead := true
## Name shown over a dead voice.
@export var dead_label := "..."


func color_of(speaker: String) -> Color:
	var picked: Color = colors.get(speaker, other_color)
	return picked


func is_dead(speaker: String) -> bool:
	if speaker == "":
		return false
	return dead.has(speaker) or dead.has(DialoguePortrait.slug(speaker))


## A line with no speaker that sounds like a whisper from the dead.
func is_dead_whisper(text: String) -> bool:
	var t := text.strip_edges()
	return unnamed_ellipsis_is_dead and t.length() > 6 and t.begins_with("...") and t.ends_with("...")
