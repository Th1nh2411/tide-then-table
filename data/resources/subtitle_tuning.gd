class_name SubtitleTuning
extends Resource
## Numbers of the subtitles (SpeechStrip, DialogueBox): typing
## pace, how long a line stays, the fade, the dead voices' look.

@export_group("Typing")
## Speaking pace, letters per second (words appear whole).
@export var chars_per_second := 16.0
## Extra pause after a word ending in , ; :
@export var comma_pause := 0.15
## Extra pause after a word ending in . ! ? or …
@export var stop_pause := 0.3

@export_group("Timing")
## A typed line stays this long + per letter, capped.
@export var hold_base := 1.3
@export var hold_per_char := 0.045
@export var hold_max := 6.0
## A line with another queued behind it stays at least this long once typed.
@export var min_seconds_queued := 0.9
## clear() during typing: the full line shows this long before it fades.
@export var clear_grace := 0.7
@export var fade_seconds := 0.4

@export_group("Dead voices")
@export var dead_color := Color("9fb3c8")
@export var dead_name_color := Color("8a9cb0")
## Typing pace of the dead (slower).
@export var dead_chars_per_second := 9.0
## Per-letter tremble ([tremble] level / rate, TrembleEffect); ~0.35 px per level.
@export var dead_shake_level := 2
@export var dead_shake_rate := 9.0


## How long a typed line of `length` letters stays before it fades.
func hold_for(length: int) -> float:
	return minf(hold_base + hold_per_char * length, hold_max)
