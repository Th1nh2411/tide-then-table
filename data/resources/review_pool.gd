class_name ReviewPool
extends Resource
## Words for "Xóm Đèn Review" guest posts (XomDenReview): invented nicknames
## and short captions (<= 6 words) by mood. Extend the lists in
## data/social/review_pool.tres, no code change.

## Avatar art id (assets/sprites/ui/avatars/<id>.png) and nickname, same order.
@export var author_ids: Array[String] = []
@export var author_names: Array[String] = []
@export var happy_captions: Array[String] = []
@export var neutral_captions: Array[String] = []
@export var angry_captions: Array[String] = []
## Used instead of a happy caption when the post is about today's HOT dish.
@export var hot_captions: Array[String] = []
## Used instead of a happy caption when the table tipped.
@export var tip_captions: Array[String] = []
## Chance a fitting HOT / tip caption replaces the plain happy one.
@export var special_caption_chance: float = 0.6


func captions(mood: String) -> Array[String]:
	match mood:
		"happy":
			return happy_captions
		"angry":
			return angry_captions
	return neutral_captions
