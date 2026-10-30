class_name RivalData
extends Resource
## A rival eatery in the weekly revenue ranking (RivalRanking). Its daily
## revenue is a fixed curve: base + growth * (day - 1) + a wobble.
## One .tres per rival in res://data/social/rivals/, listed in the catalog.

@export var id: String = ""
@export var display_name: String = ""
## Logo art id: assets/sprites/ui/rivals/<id>.png (placeholder otherwise).
@export var color: Color = Color.WHITE
## Revenue on day 1 (k), growth per day (k), wobble amplitude (k).
@export var base_k: int = 200
@export var growth_k: int = 30
@export var wobble_k: int = 40
## Shifts the wobble so rivals don't rise and fall together.
@export var phase: float = 0.0
## Paid once, the first time the player's week beats this rival.
@export var beat_reward_k: int = 50


## Revenue (k) of one day (days before 1 = closed).
func revenue(day: int) -> int:
	if day < 1:
		return 0
	return maxi(base_k + growth_k * (day - 1) + roundi(wobble_k * sin(day * 1.7 + phase)), 0)
