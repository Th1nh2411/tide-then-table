class_name ServiceTuning
extends Resource
## Balance numbers for the restaurant's guests: how often they come and what
## parties order. One .tres per stage in res://data/restaurant/;
## RestaurantShift3D.pick_tuning picks today's by `from_day`.

## First day this stage applies.
@export var from_day: int = 1

## Spawning: seconds between parties (random in range), first one sooner.
@export var first_spawn_delay: float = 1.5
@export var min_spawn_interval: float = 6.0
@export var max_spawn_interval: float = 11.0
## Spawn interval multiplier by yesterday's rating (index = stars, 0 unused).
@export var interval_scale_by_rating: Array[float] = [1.0, 1.3, 1.15, 1.0, 0.85, 0.7]

## Parties and orders.
## Chance a party is two guests.
@export var pair_chance: float = 0.15
## Chance of one more dish than guests in the first order (max `max_lines`).
@export var extra_dish_chance: float = 0.35
@export var max_lines: int = 3
## Chance to order another round once everything is eaten, and how many.
@export var more_round_chance: float = 0.35
@export var max_more_rounds: int = 1

