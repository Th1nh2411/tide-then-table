# Horror build: Codex brief 4

Same rules as [HORROR_ART_BRIEF.md](HORROR_ART_BRIEF.md) ("How to deliver", "Shared style") and brief 3
(image-to-3D concepts: 1024×1024, one object, three-quarter view from slightly above, plain light-grey
background, no cast shadow, nothing cropped; `assets/concepts/horror/<name>.png` + `<name>.md` sidecar).
Invented place names only. Do not wire new things into scenes: Claude's world agent edits the builders
(`scenes/village3d/*`, `scenes/home3d/*`, `restaurant_room_builder_3d.gd`, `sea_world_builder_3d.gd`) next.

## 0. Finish the current work first

1. `tools/run_bot.sh` fails on the working tree: `STUCK 3D scene ["res://scenes/sea3d/sea_scene_3d.tscn"]`
   on the first night after a loop reset (log: "LOOP RESET ... HOME | Mùng 9 ... DAY 1 | served 8 ... STUCK").
   HEAD 9292313 without your changes gives BOT OK. Suspects: `scenes/fishing3d/rod_3d.gd`,
   `fish_basket_3d.gd`, or the audio changes. Fix, then `tools/run_tests.sh` → ALL OK and bot → BOT OK.
2. Commit in two commits: (a) models + their code (assets/models/ready/*, concept_model_3d.gd,
   concept_projection.gdshader, village3d / home3d / fishing3d builders, restaurant_hud_3d.gd, docs),
   (b) audio. Note: try-horror-1st moved (paper/notebook/subtitles, Vy) — rebase/merge first; PLAN.md
   conflicts: keep both sides.

## 1. Fix white baked into model textures

The world survey found white, untextured areas (background baked into the texture or projection):
`bamboo_fence` (white strip along the base), `power_pole` (white halo), `roadside_shrine` (white trim),
`fishing_nets_drying` (white legs and cloth). Fix in the asset / projection side (cut the grey/white
background out of the concept before projecting, or repaint those UV areas), keep file names. Check with
3 views per model.

## 2. Concepts for models still missing (image-to-3D)

| # | Name | Prompt subject |
|---|---|---|
| 1 | `dish_plate_fish` | an enamel plate with a grilled fish on banana leaf, chilli and lime, as served at a sidewalk stall |
| 2 | `dish_bowl_soup` | a chipped porcelain bowl of sour fish soup with herbs, a tin spoon |
| 3 | `beer_tower` | a plastic beer tower (3 L tube with a tap) half full, ice cubes, condensation |
| 4 | `beer_glass_ice` | a ribbed glass of beer with a big ice cube, a cheap plastic coaster |
| 5 | `tray_aluminium` | a dented aluminium serving tray |
| 6 | `table_stall_folding` | a low folding metal sidewalk table with a worn floral oilcloth, rust spots |
| 7 | `stool_plastic_stack` | a stack of 4 faded red and blue plastic stools, scuffed |
| 8 | `charcoal_stove_clay` | a clay charcoal stove (bếp lò) with a grill rack, ash, glowing coals |
| 9 | `food_cart_glass` | an old street food cart with a glass display case, dented tin, hand-painted invented name "BẢO" |
| 10 | `ice_box_styrofoam` | a cracked white styrofoam ice box taped with packing tape |
| 11 | `altar_tray_offerings` | a ghost-month offering tray on a low table: rice, salt, sugarcane, small cakes, paper clothes, incense |
| 12 | `lamp_post_village` | a thin concrete street lamp post with a bent arm and a tin-shaded bulb |
| 13 | `coconut_palm` | a tall tilted coconut palm with a few coconuts, ragged fronds |
| 14 | `motorbike_cub` | an old 1990s Honda-Cub-like scooter (no brand), dusty, a plastic basket on the front |
| 15 | `fish_drying_rack` | a bamboo rack with rows of small split fish drying in the sun |
| 16 | `clothesline` | a rope between two bamboo poles with faded clothes and a towel |
| 17 | `boat_pulled_up` | a small wooden fishing boat pulled up on sand, tilted, faded blue and red paint, painted eyes on the bow |
| 18 | `thung_boat` | a round woven bamboo basket boat (thúng chai) with black tar coating, a paddle inside |
| 19 | `tube_house_a` | a narrow 2-storey tube house, peeling yellow paint, rolling metal shutter, small balcony with plants, tin awning |
| 20 | `tube_house_b` | a narrow 3-storey tube house, grey concrete, blue window frames, a hand-painted shop sign with an invented name |
| 21 | `tube_house_c` | a narrow 1-storey shop house with a tin roof, wooden shutters, a faded soft-drink sign (no real brand) |
| 22 | `shed_tin` | a small rusty corrugated-tin shed with a padlocked door |
| 23 | `boat_upturned` | a small dugout boat turned upside down on wooden blocks |
| 24 | `buoy_pile` | a heap of old foam buoys and a coil of rope |
| 25 | `planter_tree_street` | a scraggly street tree (bàng / almond tree) in a cracked concrete ring |

## 3. Textures and sky (save to `assets/textures/horror/`)

| # | Name | Subject |
|---|---|---|
| 26 | `sky_dusk_pano` | 2048×1024 equirectangular dusk sky over the sea, purple-orange low clouds, first stars, matching the existing dawn/night skies |
| 27 | `village_far_strip` | 2048×512 seamless horizontal silhouette strip: far tin roofs, palms, poles and wires, a few lit windows, transparent sky (PNG alpha), for a distant backdrop ring |
| 28 | `sand_packed` | tileable 512 packed wet sand with shells and footprints |
| 29 | `plaster_shopfront` | tileable 512 old shophouse plaster, faded yellow, water stains, peeling to brick |
| 30 | `street_tiles_worn` | tileable 512 worn grey sidewalk tiles with cracks and stains |

## 4. Writing (data drafts, Vietnamese, into `docs/HORROR_TEXTS_DRAFT_2.md`)

For the "every character has a role" pass (PLAN.md §10, "Còn mở"): per character, 7 short lines (one per
day mùng 9 → 14 + rằm), in their own voice, each carrying at most one clue or omen tell as described there,
never explaining rules, Rin never narrating: Bảo, Cô Năm, anh Út (friendly regular, subtle), ông Tám
(old customs; plus one "after a reset" variant per omen kind in `data/omens/`), chú Hai (lane neighbour),
and 6 lines for the uncanny subtitle tricks (a line repeated word for word, someone calling Rin "Tư",
a subtitle with nobody speaking). Mark which lines are clues.
