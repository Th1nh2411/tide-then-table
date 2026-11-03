class_name UncannyDose
extends Resource
## How much "uncanny" each day may carry (UncannyDirector). Days are
## GameState.day: 1 = mùng 9 ... 7 = rằm.

## Light effects -> first day they may play. Light ones can repeat.
@export var light_from_day: Dictionary = {
	"props_turned": 1, "door_closed": 1,
	"extra_figure": 3, "missing_shadow": 3, "glowing_eyes": 3, "reflection": 3, "flicker_pose": 3,
	"stare": 4, "freeze": 4, "choppy": 4, "wrong_walk": 4, "glitch_face": 4,
}
## Heavy effects -> first day. At most one heavy effect per night.
@export var heavy_from_day: Dictionary = {"appear_close": 5, "dash": 5, "flash": 5}
## No heavy effect after this day (rằm has its own reveal).
@export var heavy_last_day: int = 6
## Chance a night that may carry a heavy effect actually gets one.
@export_range(0.0, 1.0) var heavy_chance: float = 0.75
## Light effects per night: base + per_day * (day - 1), capped.
@export var light_base: int = 1
@export var light_per_day: float = 0.75
@export var light_cap: int = 5
## Subtitle tricks (repeated line / wrong name / extra line): once per loop
## on one of these days.
@export var subtitle_days: Array[int] = [5, 6]
## Anh Út's subtle cues (held smile, eyes following) from this day, only
## when he is on screen (he is, before the reveal, only on rằm).
@export var ut_cues_from_day: int = 4
@export_group("Jump scares")
## Ông Tư behind Rin: this day, once per playthrough (rằm is the next day's
## scare, so day 6 would make two scares in a row).
@export var tu_scare_day: int = 5
## The fake scare (a fish slaps into the thúng): one of these calm days.
@export var fake_scare_days: Array[int] = [2, 3]
## Faces for the wrong-night scare, rotated by reset count.
@export var wrong_night_variants: int = 3
