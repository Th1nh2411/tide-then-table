# Horror build: Codex brief 8 (fix 4 regressions + the last primitive props)

Same rules as earlier briefs. A Claude agent works in parallel on the sea water shader
(`scenes/sea3d/sea_water.gdshader`, sea moon glint) and `scenes/restaurant3d/restaurant_fish_3d.gd`;
don't edit those. Placement of new models is ours (we wire them after you deliver), so only build
`assets/models/ready/<id>/` + catalog, like brief 5.

## 1. Fix (seen in the 3-view render at `1e93ff6`)

1. `beer_glass_ice`, `beer_tower`: lost the glass look, now read as opaque brown / orange clay. They
   should be clear glass (see-through, alpha like the cart glass ~0.15-0.3) with yellow beer, foam on
   top, ice cubes visible in the glass; tower: clear tube with beer inside, red base / cap, tap.
2. `stone_steps`: now a lumpy mossy rock, the steps are gone. Must read as 3-4 worn stone steps
   (clear treads and risers), moss only in the corners.
3. `ice_box_styrofoam`: blue blotches look like cow print. White-grey styrofoam with dirt, scuffs,
   brown tape, maybe a faded marker scrawl; no big coloured spots.
4. `planter_tree_street`: now a round lollipop crown. A street bàng: short thick trunk, branches
   spreading horizontally in 2-4 flat tiers (pagoda shape), each tier a wide flat layer of big
   leaves, gaps between tiers. ~4.2 m tall in the street slot, crown wider than tall.
5. Small: `tray_aluminium` reads as flat blue-grey plastic: dented dull aluminium, scratches, a bit of
   grease.

## 2. New models for the last primitive props (concept -> Hunyuan -> catalog)

| ID | What | Budget | Replaces |
|---|---|---:|---|
| `float_buoy` | old fishing float: orange / white styrofoam block or plastic can, rope, algae | 800 | floating boxes off the village shore (`waterfront_life_3d.gd`) |
| `sea_rock` | dark wet rock pile breaking the surface, barnacles, a little foam stain | 2000 | sea rocks (`submerged_rock_3d.gd`) |
| `shop_awning` | faded striped canvas awning (green / cream), 1 m wide module, sagging, torn edge | 1000 | awning strips over the restaurant shop row |
| `shop_signboard` | long rusty tin signboard frame, blank face (text is drawn in game), 9 x 0.65 m | 1000 | "HẢI SẢN XÓM ĐÈN" board |
| `chalk_menu_board` | wooden A-frame / leaning chalkboard with smudged chalk scribbles (no readable text) | 1000 | kitchen board next to the cart |
| `beer_keg` | dented steel beer keg on a plastic crate, wet, label faded | 1500 | the pale barrel next to the ice box |
| `bamboo_stake` | thin weathered bamboo mooring stake with rope ties | 400 | stakes off the shore |

Scale / pivot: base at y 0, front +Z, real-world metres. Same provenance / license / review files as
brief 5. If the free Space quota runs out, stop and list remaining ids for the local Windows batch.

## 3. Done when

3-view sheet for every fixed / new model (look at them yourself: no white / lavender areas, no
picture-in-picture), `tools/run_tests.sh` ALL OK, `tools/run_bot.sh` BOT OK, commit, report in
`docs/HORROR_CODEX_DELIVERY_8.md`. `-- --no-autosave`, `git checkout project.godot` after `--import`,
no push.
