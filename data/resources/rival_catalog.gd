class_name RivalCatalog
extends Resource
## The rival eateries of the weekly ranking (RivalRanking).

@export var rivals: Array[RivalData] = []
## Days in the ranking window.
@export var week_days: int = 7


func find(rival_id: String) -> RivalData:
	for rival in rivals:
		if rival.id == rival_id:
			return rival
	return null
