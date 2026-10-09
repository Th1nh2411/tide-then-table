class_name CutsceneScript
extends RefCounted
## Parses a Cutscene's text into commands. One command per line:
##   word arg arg "quoted text" ...      (# starts a comment line)
## Commands (run by CutscenePlayer):
##   fade_out <s> / fade_in <s>        screen to black / back
##   tint dawn|night|day               world color
##   camera <marker> [s] [zoom]        move the cutscene camera to a marker
##   spawn <actor> <kind> <marker> [scale]   kinds: rin, bao, vy, co_nam, guest, cat, crate, rin_bed, glow
##   remove <actor>                    take an actor off the stage
##   move_to <actor> <marker> <s>      walk there (waits)
##   face <actor> left|right
##   emote <actor> !|?|...|heart|note [s]
##   speak <name> "text"               dialogue line (waits for the player)
##   narrate "text"                    line without a speaker
##   choice "option" <label> "option" <label> ...   jump by the answer
##   label <name> / goto <name>
##   pause <s>
##   name_pet <default>                ask the pet's name ({pet})
##   set_flag <name>
## Text may use {pet} (the cat's name). Pure logic, no nodes.


## [{"cmd": String, "args": PackedStringArray, "line": int}]
static func parse(text: String) -> Array[Dictionary]:
	var commands: Array[Dictionary] = []
	var lines := text.split("\n")
	for i in lines.size():
		var line := lines[i].strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var tokens := tokenize(line)
		commands.append({"cmd": tokens[0], "args": tokens.slice(1), "line": i + 1})
	return commands


## Splits on spaces, keeping "quoted text" as one token (quotes removed).
static func tokenize(line: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var current := ""
	var quoted := false
	var had_quotes := false
	for c in line:
		if c == "\"":
			quoted = not quoted
			had_quotes = true
		elif c == " " and not quoted:
			if current != "" or had_quotes:
				tokens.append(current)
			current = ""
			had_quotes = false
		else:
			current += c
	if current != "" or had_quotes:
		tokens.append(current)
	return tokens


## label name -> command index.
static func labels(commands: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for i in commands.size():
		if commands[i]["cmd"] == "label":
			result[commands[i]["args"][0]] = i
	return result


## Replaces {pet} in a line.
static func fill(text: String) -> String:
	return text.replace("{pet}", pet_name())


static func pet_name() -> String:
	var value: Variant = GameState.story_flags.get("pet_name", "")
	return value if value is String and value != "" else "Mèo"
