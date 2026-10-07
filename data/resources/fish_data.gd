class_name FishData
extends Resource
## One catchable species. One .tres per species lives in res://data/fish/.

enum Zone { NEARSHORE, REEF, OPEN_SEA, FOG }
enum Minigame { TENSION, TIMING, HAUL }
## ROD = bites at fishing spots. NET = only from nets the player drops and hauls.
enum CatchMethod { ROD, NET }

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
@export var catch_method: CatchMethod = CatchMethod.ROD
## 0..1. Drives needle speed, green zone size and struggling in the minigame.
@export_range(0.0, 1.0) var difficulty: float = 0.5
@export var base_price: int = 10
## Relative chance among species of the same zone.
@export var spawn_weight: float = 1.0
## Aberrant (mutated) fish: story clue, special minigame look.
@export var is_aberrant: bool = false
## Weight of an average-size catch (size 1.0), only for display and records.
@export var typical_kg: float = 1.0


func lives_in(zone: Zone) -> bool:
	return zones.has(zone)


func weight_kg(size: float) -> float:
	return typical_kg * size


## "3.4kg" or "350g".
func weight_text(size: float) -> String:
	var kg := weight_kg(size)
	return "%.1fkg" % kg if kg >= 1.0 else "%dg" % roundi(kg * 1000.0)
