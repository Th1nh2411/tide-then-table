# Horror build: Codex brief 5 (build the brief-4 models)

Same rules as earlier briefs. Two Claude agents are working in parallel in their own worktrees and will be
merged into try-horror-1st: a WORLD agent (geometry/placement in `scenes/village3d/*`, `scenes/home3d/*`,
`restaurant_room_builder_3d.gd` shell/street ends, `sea_world_builder_3d.gd`, `restaurant_hud_3d.gd`) and
a STYLE agent (one colour/material pass for every model, restaurant prop colours, ghost look). Do not edit
those areas; the world agent already uses a model automatically when
`assets/models/ready/<id>/<id>_reduced.glb` exists (coconut_palm, lamp_post_village, tube_house_a/b/c,
motorbike_cub, fish_drying_rack, clothesline, boat_pulled_up, thung_boat, shed_tin, boat_upturned,
buoy_pile, planter_tree_street).

## 0. Finish brief 4

Fix of white areas (bamboo_fence, power_pole, roadside_shrine, fishing_nets_drying) checked with 3 views,
`tools/run_tests.sh` → ALL OK, `tools/run_bot.sh` → BOT OK, then commit (concepts + textures + drafts in
one commit, the white fix in another).

## 1. Build the 25 brief-4 models

Same pipeline as the first 25 (`tools/art/hunyuan_job.py` on the free Space; if the ZeroGPU quota runs
out, stop and list the remaining ids for the local Windows batch, see `docs/LOCAL_HUNYUAN_TONIGHT.md`).
Face budgets: small 2000 (dishes, glasses, tray, buoy_pile), medium 3000 (furniture, cart, stove, ice box,
offering tray, lamp post, palm, motorbike, rack, clothesline, boats, thung, shed, planter tree),
big 5000 (tube_house_a/b/c). Output `assets/models/ready/<id>/` like the others, add them to
`horror_models.gd/.json`, review 3 views each, record triangles in `docs/HORROR_MODEL_INTEGRATION.md`.

## 2. Wire only these (no conflict with the agents)

- Food Rin carries and serves: replace the primitive plate / bowl / beer tower / glass shapes in Rin's
  hands and on the tables / plate table with `dish_plate_fish`, `dish_bowl_soup`, `beer_tower`,
  `beer_glass_ice`, `tray_aluminium` (find them: `grep -rlE 'BoxMesh|CylinderMesh' scenes`, start with
  `scenes/story3d/person_rig_3d.gd` carry visuals and the restaurant service / seating visuals).
- Omen offering tray: `altar_tray_offerings` where `scenes/omens3d/*` / `omen_props_3d.gd` draws the
  ghost-month tray with primitives (keep the eaten / normal variants logic).
- Leave tables, stools, cart, stove, ice box (restaurant furniture) for after the STYLE agent is merged;
  list in your report how you'd swap them.

Keep everything typed GDScript, small scripts, `-- --no-autosave` on runs, `git checkout project.godot`
after `--import`. Tests + bot must pass; commit; report triangles, review images and what's left.
