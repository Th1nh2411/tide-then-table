class_name ServiceTuning
extends Resource
## Balance numbers for the restaurant's customers (CustomerManager): how
## often they come, what parties order, patience bonuses, tips. One .tres in
## res://data/restaurant/; CustomerManager.stages picks today's by `from_day`.

## First day this stage applies.
@export var from_day: int = 1

## Spawning: seconds between parties (random in range), first one sooner.
@export var first_spawn_delay: float = 1.5
@export var min_spawn_interval: float = 6.0
@export var max_spawn_interval: float = 11.0
## Spawn interval multiplier by yesterday's rating (index = stars, 0 unused).
@export var interval_scale_by_rating: Array[float] = [1.0, 1.3, 1.15, 1.0, 0.85, 0.7]
## Share of parties who come on foot instead of by motorbike.
@export var walk_in_chance: float = 0.2

## Parties and orders.
## Chance a party is two guests (regulars come alone).
@export var pair_chance: float = 0.15
## Chance of one more dish than guests in the first order (max `max_lines`).
@export var extra_dish_chance: float = 0.35
@export var max_lines: int = 3
## Chance a line is a side (rau muống, beer) while seafood is left; extra
## rounds pick a side more often.
@export var side_order_chance: float = 0.25
@export var round_side_chance: float = 0.6
## Chance to order another round once everything is eaten, and how many.
@export var more_round_chance: float = 0.35
@export var max_more_rounds: int = 1

## Rush hour (only once Rin has Nhịp Sóng, WaveMark): between these shift
## seconds walk-ins come this much more often.
@export var rush_from: float = 70.0
@export var rush_to: float = 110.0
@export var rush_interval_scale: float = 0.4
## Decor upgrade (index = its level): spawn interval and well-off customers.
@export var decor_interval_scale: Array[float] = [1.0, 0.85, 0.72]
@export var rich_chance_by_decor: Array[float] = [0.0, 0.15, 0.3]
@export var rich_price_scale: float = 1.5
@export var rich_patience_scale: float = 0.75
## Regulars wait longer, and come this many seconds into the shift.
@export var regular_patience_scale: float = 2.0
@export var regular_delay: float = 6.0
## Patience multiplier while the restaurant cat is around ("mèo chiêu tài").
@export var cat_patience_scale: float = 1.1

## Tip = price × tip_ratio, only if patience is above the threshold.
@export var tip_ratio: float = 0.2
@export var tip_patience_threshold: float = 0.5
