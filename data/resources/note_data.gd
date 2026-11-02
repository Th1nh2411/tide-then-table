class_name NoteData
extends Resource
## A handwritten note pinned up somewhere (horror build), read up close with
## PaperReader: a title, short lines, a signature.

@export var title: String = ""
@export_multiline var lines: Array[String] = []
@export var signature: String = ""


## The note's words as they appear on the paper: one line per rule.
func body() -> String:
	var words := "\n".join(lines.map(func(line: String) -> String: return "- " + line))
	return words + ("\n\n" + signature if signature != "" else "")
