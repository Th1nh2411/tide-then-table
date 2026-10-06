class_name FishData
extends Resource
## One catchable species. One .tres per species lives in res://data/fish/.

enum Zone { NEARSHORE, REEF, OPEN_SEA, FOG }
enum Minigame { TENSION, TIMING }

@export var id: String = ""
## Vietnamese name shown to the player.
@export var display_name: String = ""
## Cells occupied in the hold grid, origin (0,0). x = column, y = row.
@export var shape: Array[Vector2i] = [Vector2i.ZERO]
## Placeholder color (hold blocks, minigame, etc.).
@export var color: Color = Color.WHITE
## Zones where this species can bite.
@export var zones: Array[Zone] = []
@export var minigame: Minigame = Minigame.TIMING
## 0..1. Drives needle speed, green zone size and struggling in the minigame.
@export_range(0.0, 1.0) var difficulty: float = 0.5
@export var base_price: int = 10
## Relative chance among species of the same zone.
@export var spawn_weight: float = 1.0
## Aberrant (mutated) fish: story clue, special minigame look.
@export var is_aberrant: bool = false


func lives_in(zone: Zone) -> bool:
	return zones.has(zone)
