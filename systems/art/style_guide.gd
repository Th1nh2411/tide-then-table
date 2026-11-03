class_name StyleGuide
extends Resource
## The one shared look of every 3D model (PLAN §10 "Đồng bộ style"): worn,
## desaturated PS1 fishing village at night, "Xóm Đèn" palette. StylePass3D
## grades materials with these numbers (data/art/style_guide.tres);
## GhostLook3D uses the ghost block. Ranges are HSV (0..1).

const PATH := "res://data/art/style_guide.tres"

@export_group("Colour range")
## Chroma kept from the source (1 = unchanged), before the caps.
@export var saturation := 0.78
## Hard cap on HSV saturation per pixel.
@export var max_saturation := 0.5
## Hard cap on HSV value per pixel (no clean white).
@export var max_value := 0.72
## Floor lift: no pure black (value never below this).
@export var black_lift := 0.03
## Pull of each pixel towards the nearest "Xóm Đèn" palette colour.
@export_range(0.0, 1.0) var palette_pull := 0.18
## "Xóm Đèn" (assets/palette/xom_den.hex), copied in so exports keep it.
@export var palette := PackedColorArray()

@export_group("Phase tint")
## Albedo multiplier per time of day (VillageLighting3D phases + the sea).
@export var tint_morning := Color(0.93, 0.95, 0.97)
@export var tint_shift := Color(0.98, 0.95, 0.89)
@export var tint_night := Color(0.88, 0.93, 1.0)
@export var tint_sea := Color(0.88, 0.94, 1.0)

@export_group("Surface")
## Roughness is clamped into this range (nothing shiny).
@export var roughness_min := 0.8
@export var roughness_max := 1.0
## Source metallic at or above this counts as real metal and is kept.
@export var metal_threshold := 0.6
## Grime: big soft blotches (metres per blotch) and how dark they get.
@export var grime_scale := 0.5
@export var grime_amount := 0.18
## Fine speckle (cells per metre) and its strength.
@export var speckle_cells := 24.0
@export var speckle_amount := 0.08
## Darkening at the base of vertical faces near the ground (AO / dirt).
@export var base_height := 0.4
@export var base_dark := 0.4

@export_group("Texels")
## Target texels per metre; sharper textures are blocked down to this.
@export var texels_per_metre := 64.0
## Never block more than this many source texels into one.
@export var max_texel_step := 8.0

@export_group("Concept models")
## ConceptModel3D (shader kept): channel balance of its tint towards grey.
@export_range(0.0, 1.0) var concept_balance := 0.45

@export_group("Worn props")
## Props from the old bright build: "<node name prefix>|<source hex>" ->
## worn colour (before the grade). The prefix is matched on the mesh or any
## parent (RestaurantBatchVisuals "Batch_<id>", tables, stools).
@export var recolor := {
	"DiningTable|c7cfcc": Color("8d907f"),  # oilcloth top, yellowed
	"DiningTable|577277": Color("4a4740"),  # rusty legs
	"PilotStool|a53030": Color("7b3b33"),  # sun-faded red plastic
	"PilotStool|3c5e8b": Color("3f5461"),  # faded blue plastic
	"Batch_bin|3c5e8b": Color("3c4c52"),
	"Batch_bin|526f9b": Color("4a5a60"),
	"Batch_food_cart_0|c7cfcc": Color("9b937b"),  # greasy cream steel
	"Batch_food_cart_0|9ca9a8": Color("727568"),
	"Batch_food_cart_0|a9c4ca": Color("6f7c78"),  # smeared glass
	"Batch_food_cart_0|a86447": Color("7d5640"),
	"Batch_beer_keg|c7cfcc": Color("7d7f76"),  # dull dented aluminium
	"Batch_beer_keg|9daead": Color("6c716b"),
	"Batch_grocery_counter|a7513a": Color("74473a"),
	"Batch_grocery_counter|c5a172": Color("8e7a5c"),
	"Batch_grocery_crate|b96543": Color("80553f"),
	"Batch_plate_bench|a57e52": Color("6f5640"),
	"Batch_crate|a57e52": Color("6f5640"),
	"Batch_bottle|d5c8a7": Color("8f8670"),
	"Batch_motorbike|a9473e": Color("74423b"),
	"Batch_dock|e3c77c": Color("8a7b5a"),
	"Batch_lobster_raft|d5ba75": Color("86775a"),
	"Batch_lighthouse|d9d3bd": Color("9a9584"),
	"Batch_lighthouse|d4b66d": Color("8f7f58"),
	"ShopFish|3d6b8a": Color("3f5461"),
}

@export_group("Ghost")
## The dead: pale grey-blue-green skin, wet dark clothes, dithered edges.
@export var ghost_skin := Color(0.47, 0.56, 0.57)
@export var ghost_cloth := Color(0.12, 0.15, 0.16)
## Source luminance above this reads as skin, below as cloth.
@export var ghost_skin_from := 0.55
## Dithered fade at silhouette edges (0 = none, 1 = strong).
@export var ghost_edge_fade := 0.65
## Vertex wobble (metres) and its speed.
@export var ghost_wobble := 0.012
@export var ghost_wobble_speed := 1.3
## Water drops falling off the body per second.
@export var ghost_drips := 7.0


static func load_default() -> StyleGuide:
	return load(PATH) as StyleGuide


func phase_tint(phase: String) -> Color:
	match phase:
		"morning":
			return tint_morning
		"shift":
			return tint_shift
		"sea":
			return tint_sea
	return tint_night

