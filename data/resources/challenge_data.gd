class_name ChallengeData
extends Resource
## One daily challenge template (Dave the Diver style "today's goals").
## `text` uses {n} for the target. One .tres per challenge in
## res://data/challenges/, listed in challenge_catalog.tres.

enum Kind {
	PARTIES,      ## serve n tables
	NOBODY_LEFT,  ## serve n tables, nobody walks out (checked at closing)
	GRILL,        ## n grilled dishes (Rin's grill)
	BEER,         ## n beer towers
	HOT,          ## n of today's HOT dish
	EARN,         ## take in at least n k
	FAST,         ## n tables served with patience to spare
	TIPS,         ## n tips
}

@export var id: String = ""
## Short (fits the HUD card): "Phục vụ {n} bàn".
@export var text: String = ""
@export var kind: Kind = Kind.PARTIES
## Icon id for the HUD card (GoalIcons / UiIcons: guest, fire, beer, chili...).
@export var icon: String = "star"
@export var target: int = 3
## Extra target per day after day 1 (rounded down).
@export var target_per_day: float = 0.0
## Reward on day 1 (k) and extra per day after it (income grows fast).
@export var reward_k: int = 30
@export var reward_per_day: int = 0
@export var min_day: int = 1


func target_on(day: int) -> int:
	return maxi(target + floori(target_per_day * float(maxi(day - 1, 0))), 1)


func reward_on(day: int) -> int:
	return reward_k + reward_per_day * maxi(day - 1, 0)


func describe(day: int) -> String:
	return text.replace("{n}", str(target_on(day)))
