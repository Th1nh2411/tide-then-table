class_name SubtitleTyper
extends RefCounted
## Pure: when each word of a subtitle appears at speaking pace. A word shows
## whole once the words before it have been "said" (their letters at
## `cps`, plus a short pause after , . … ! ?).

const COMMA_ENDS := [",", ";", ":"]
const STOP_ENDS := [".", "!", "?", "…"]


## [[visible letters once this word is up, time it appears], ...].
static func beats(text: String, cps: float, comma_pause: float, stop_pause: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var time := 0.0
	var index := 0
	var length := text.length()
	while index < length:
		var word_end := index
		while word_end < length and text[word_end] != " ":
			word_end += 1
		while word_end < length and text[word_end] == " ":
			word_end += 1  # the trailing spaces go with the word
		out.append(Vector2(word_end, time))
		var word := text.substr(index, word_end - index).strip_edges()
		time += float(word.length() + 1) / maxf(cps, 0.1)
		if word != "":
			var last := word[word.length() - 1]
			if STOP_ENDS.has(last):
				time += stop_pause
			elif COMMA_ENDS.has(last):
				time += comma_pause
		index = word_end
	return out


## Letters showing `elapsed` seconds into the line.
static func visible_at(beats_list: Array[Vector2], elapsed: float) -> int:
	var shown := 0
	for beat in beats_list:
		if beat.y > elapsed:
			break
		shown = int(beat.x)
	return shown


## Seconds until the last word is up.
static func duration(beats_list: Array[Vector2]) -> float:
	if beats_list.is_empty():
		return 0.0
	return beats_list[beats_list.size() - 1].y
