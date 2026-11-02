class_name OmenCatalog
extends Resource
## Every omen plus how often nights carry one (OmenPicker).

@export var omens: Array[OmenData] = []
## Chance that a night between first_day and last_day has an omen.
@export_range(0.0, 1.0) var chance: float = 0.5
## Day 1 (mùng 9) is always calm; the last night (rằm) is the ending's.
@export var first_day: int = 2
@export var last_day: int = 6
## Normal-but-eerie customs shown on a calm night (OmenPicker.customs).
@export var customs_min: int = 1
@export var customs_max: int = 2
## On an omen night, besides the omen itself.
@export var customs_on_omen_night: int = 1


func find(id: String) -> OmenData:
	for omen in omens:
		if omen.id == id:
			return omen
	return null
