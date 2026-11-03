class_name TrembleEffect
extends RichTextEffect
## [tremble level=3 rate=9]: a tiny smooth jitter per letter for dead
## voices. Keyed by the character's place in the text, so Vietnamese accents
## (separate glyphs) move with their letter.

var bbcode := "tremble"

## Pixels of jitter per level.
const PIXELS_PER_LEVEL := 0.35


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var level: float = float(char_fx.env.get("level", 3.0))
	var rate: float = float(char_fx.env.get("rate", 9.0))
	var seed := float(char_fx.range.x)
	var t := char_fx.elapsed_time * rate
	var amount := level * PIXELS_PER_LEVEL
	char_fx.offset += Vector2(sin(t + seed * 1.7) + 0.5 * sin(t * 2.3 + seed * 3.1),
		cos(t * 1.3 + seed * 2.3) + 0.5 * sin(t * 1.9 + seed * 0.7)) * amount * 0.67
	return true
