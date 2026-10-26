class_name FishData
extends Resource
## One catchable species. One .tres per species lives in res://data/fish/.

enum Zone { NEARSHORE, REEF, OPEN_SEA, FOG }
## RHYTHM is the save-compatible value for rod fishing (FishFightGame),
## HAUL = hauling a net. Index 1 is no
## longer used (the old timing game); kept so saved values stay the same.
enum Minigame { RHYTHM, UNUSED, HAUL }
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
@export var minigame: Minigame = Minigame.RHYTHM
@export var catch_method: CatchMethod = CatchMethod.ROD
## 0..1. Drives fish speed and line tension in the rod fight.
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


## Whole kg from 1kg up ("4kg"), else grams to the nearest 10 ("520g").
func weight_text(size: float) -> String:
	var kg := weight_kg(size)
	return "%dkg" % roundi(kg) if kg >= 0.995 else "%dg" % (roundi(kg * 100.0) * 10)
