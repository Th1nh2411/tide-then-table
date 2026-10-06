class_name SeaZone
extends ColorRect
## Water area belonging to one fishing zone. The rect is both the visual
## (shallow = light, open sea = dark) and where the spawner places spots.

@export var zone: FishData.Zone = FishData.Zone.NEARSHORE
## Fishing spots spawned here at the start of each day.
@export var spot_count: int = 4
