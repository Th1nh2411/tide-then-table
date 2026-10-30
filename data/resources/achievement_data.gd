class_name AchievementData
extends Resource
## One lifetime achievement: unlocked when GameState.stats[stat] reaches
## `target` (keys in LifetimeStats). One .tres per achievement in
## res://data/achievements/, listed in achievement_catalog.tres.

@export var id: String = ""
@export var title: String = ""
## Badge icon id (GoalIcons / UiIcons).
@export var icon: String = "trophy"
@export var desc: String = ""
@export var stat: String = "served_total"
@export var target: int = 1
@export var reward_k: int = 50
