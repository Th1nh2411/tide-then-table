class_name NewsData
extends Resource
## The morning paper ("Bản tin Ngủ Quên") pushed under the bedroom door: one
## front page per day of the loop (index 0 = mùng 9). Clues get deeper the
## further a loop gets.

@export var title: String = "BẢN TIN NGỦ QUÊN"
@export_multiline var pages: Array[String] = []


func page(day: int) -> String:
	if pages.is_empty():
		return ""
	return pages[clampi(day - 1, 0, pages.size() - 1)]
