class_name SoundCaptions
extends Resource
## Closed captions for story sounds, keyed by Sfx recipe name. Describe the
## sound, never what it means. CaptionLayer shows them in [brackets] with a
## direction word when the sound is placed in the world.

## recipe -> caption (anywhere).
@export var captions: Dictionary = {}
## recipe -> caption used instead while the sea's bed plays (on the thúng).
@export var sea_captions: Dictionary = {}
## Captioned only when placed in the world (Sfx.play_at): the player's own
## steps / gameplay splashes are plain Sfx.play.
@export var positional_only: PackedStringArray = []
## recipe -> seconds before the same caption may show again.
@export var cooldowns: Dictionary = {}


## "" = no caption for this sound here.
func text_for(sound: String, positional: bool, at_sea: bool) -> String:
	if positional_only.has(sound) and not positional:
		return ""
	if at_sea and sea_captions.has(sound):
		return str(sea_captions[sound])
	return str(captions.get(sound, ""))


func cooldown_for(sound: String, fallback: float) -> float:
	var value: Variant = cooldowns.get(sound, fallback)
	return float(value) if (value is float or value is int) else fallback
