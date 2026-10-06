class_name DayRating
extends RefCounted
## Restaurant rating for one shift (1-5 stars).

const MIN_STARS: int = 1
const MAX_STARS: int = 5
## Stars when nobody came at all.
const EMPTY_SHIFT_STARS: int = 1


## Mostly the share of customers that got served; a monotonous menu (variety
## penalty active) costs one star.
static func stars(served: int, left_angry: int, monotonous_menu: bool) -> int:
	var total := served + left_angry
	if total == 0:
		return EMPTY_SHIFT_STARS
	var result := MIN_STARS + roundi(float(served) / total * (MAX_STARS - MIN_STARS))
	if monotonous_menu:
		result -= 1
	return clampi(result, MIN_STARS, MAX_STARS)
