class_name Achievements
extends RefCounted
## Lifetime achievements over GameState.stats (LifetimeStats keys).
## Unlocked = story flag "ach_<id>" (saved); each pays its reward once.
## Pure logic, no nodes.

const FLAG_PREFIX := "ach_"


static func is_unlocked(achievement: AchievementData) -> bool:
	return GameState.story_flags.has(FLAG_PREFIX + achievement.id)


## Current value toward the target (capped).
static func progress(achievement: AchievementData, stats: Dictionary) -> int:
	return mini(LifetimeStats.value(stats, achievement.stat), achievement.target)


## Unlocks (and pays) everything newly reached. Returns those, catalog order.
static func check(catalog: AchievementCatalog, stats: Dictionary) -> Array[AchievementData]:
	var fresh: Array[AchievementData] = []
	for achievement in catalog.achievements:
		if is_unlocked(achievement) or LifetimeStats.value(stats, achievement.stat) < achievement.target:
			continue
		GameState.set_flag(FLAG_PREFIX + achievement.id)
		GameState.add_money(achievement.reward_k)
		fresh.append(achievement)
	return fresh


static func unlocked_count(catalog: AchievementCatalog) -> int:
	return catalog.achievements.filter(func(a: AchievementData) -> bool: return is_unlocked(a)).size()
