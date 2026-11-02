class_name LinesData
extends Resource
## Lines a character says in turn when Rin walks up and presses E
## (on-screen text, no portrait). `speaker` prefixes each line.

@export var speaker: String = ""
@export_multiline var lines: Array[String] = []


func line(index: int) -> String:
	if lines.is_empty():
		return ""
	return "%s: %s" % [speaker, lines[index % lines.size()]] if speaker else lines[index % lines.size()]
