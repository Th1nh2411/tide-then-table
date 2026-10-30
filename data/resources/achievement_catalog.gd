class_name AchievementCatalog
extends Resource
## All achievements, in the order the phone lists them.

@export var achievements: Array[AchievementData] = []


func find(achievement_id: String) -> AchievementData:
	for achievement in achievements:
		if achievement.id == achievement_id:
			return achievement
	return null
