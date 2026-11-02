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
## Early days only pick obvious omens (OmenData.subtlety up to this);
## subtle ones come later, once the player knows what to look for.
@export var early_last_day: int = 3
@export_range(0.0, 1.0) var early_max_subtlety: float = 0.4


## Whether an omen may show on `day` (early days: obvious ones only).
func allowed(omen: OmenData, day: int) -> bool:
	return day > early_last_day or omen.subtlety <= early_max_subtlety


## Subtle omens (past early_max_subtlety) need a second tell that night.
func is_subtle(omen: OmenData) -> bool:
	return omen.subtlety > early_max_subtlety


func find(id: String) -> OmenData:
	for omen in omens:
		if omen.id == id:
			return omen
	return null
