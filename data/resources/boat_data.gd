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
## Repair price per hull point (k). Bigger boats cost more to fix.
@export var repair_cost_per_hp: float = 2.5
## How far out this boat can go: 0 = shore, 1 = far edge (CatchRoll.depth_at).
## Beyond it the waves push the boat back (BoatRange).
@export_range(0.0, 1.0) var max_depth: float = 1.0
## Shown in the phone / shop, e.g. "tới rạn đá".
@export var range_label: String = "ra khơi xa"

@export_group("Rowing (3D sea)")
## Paddled boat: moves only while a stroke pulls (RowStroke), then glides.
@export var rowed: bool = false
## Seconds per paddle stroke (catch -> pull -> lift).
@export var stroke_seconds: float = 1.0
## Forward speed one full stroke adds (world units/second).
@export var stroke_push: float = 5.0
## Spin speed one side stroke adds (radians/second).
@export var stroke_turn: float = 1.6
## Water drag between strokes (higher = shorter glide).
@export var glide_drag: float = 1.5
## Spin drag (higher = stops turning sooner).
@export var spin_drag: float = 2.2

@export_group("Placeholder visuals")
## Hull length (x) and width (y) in pixels. Also sizes the collision circle.
@export var hull_size: Vector2 = Vector2(24, 12)
@export var color: Color = Color(0.55, 0.35, 0.2)
