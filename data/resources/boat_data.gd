class_name BoatData
extends Resource
## Stats for one boat type. One .tres per boat lives in res://data/boats/.

@export var id: String = ""
@export var display_name: String = ""
## Top forward speed in pixels/second.
@export var max_speed: float = 100.0
## Speed gained per second at full throttle (pixels/second²).
@export var acceleration: float = 60.0
## Base steering rate in degrees/second.
@export var turn_speed: float = 100.0
## 0..1. How much extra spin builds up while steering and lingers after release.
## High = boat keeps twirling (round basket boat). Low = precise steering.
@export_range(0.0, 1.0) var spin_drift: float = 0.3
## Cargo hold grid size in cells (used in Phase 5).
@export var hold_size: Vector2i = Vector2i(4, 3)

@export_group("Placeholder visuals")
## Hull length (x) and width (y) in pixels. Also sizes the collision circle.
@export var hull_size: Vector2 = Vector2(24, 12)
@export var color: Color = Color(0.55, 0.35, 0.2)
