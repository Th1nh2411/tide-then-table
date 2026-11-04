# Horror build: Codex brief 6 (UV / material pass on the brief-5 models)

Same rules as earlier briefs. A Claude agent works in parallel in its own worktree: it swaps the
restaurant furniture (table, stools, cart, stove, ice box) to the brief-5 models in
`scenes/restaurant3d/restaurant_room_builder_3d.gd` and puts `thung_boat` on the sea
(`scenes/sea3d/*`, `scenes/fishing3d/*`). Do not edit those files. It only places meshes; the look of
each model is yours, so when you fix a model, re-export the same `assets/models/ready/<id>/` paths and
the game picks it up.

## 1. Fix what the brief-5 review showed (in priority order)

1. `tube_house_a/b/c`: the side and back faces stretch the concept into streaks. Keep the projected
   front; give side / back / roof faces a tiled worn texture (plaster, moss stain, tin roof) with real
   UVs instead of the stretched projection. Check from the street at eye height (1.6 m), not only
   the 3-view sheet.
2. `food_cart_glass`: the "BẢO" lettering on the back is mirrored. Fix it on the model / texture.
3. `planter_tree_street`: reads as a bonsai. A street bàng (Terminalia) has a straight trunk and
   flat horizontal tiers of big round leaves; taller than Rin (~3.5-4.5 m). Keep the planter.
4. `altar_tray_offerings` and thin parts (clothesline, fish rack slats, lamp post arm): clean up the
   rough / broken thin geometry.
5. Still white from brief 4: rod, bed, tea table, fence (the baked Hunyuan textures).
6. Any brief-5 model whose sides show the same streaking: same treatment as 1.
7. Seen in game after the furniture swap (`a880e35`, placement is done, only the look):
   - `table_stall_folding`: under the street lamps the top and X-legs come out almost white; the
     concept's floral cloth / rusty legs should show on the top and the sides Rin sees.
   - `thung_boat`: pale grey-white patches on the rim / walls (the top-down projection picks up the
     concept's grey background); the model has a paddle lying inside, remove it (the game has its own
     `ThungPaddle3D`, so two paddles show at sea).
   - `food_cart_glass`: side panels pale and streaky (plus the mirrored "BẢO" in 2).

Stay inside `StyleGuide` ranges (`data/art/style_guide.tres`, style_test checks it). Budgets unchanged.
Review 3 views each plus one in-game screenshot per house (street at night, windowed
`--resolution 1280x720`).

## 2. Done when

`tools/run_tests.sh` → ALL OK, `tools/run_bot.sh` → BOT OK, commit, report in
`docs/HORROR_CODEX_DELIVERY_6.md` with before / after images. `-- --no-autosave` on every run,
`git checkout project.godot` after `--import`, no push.
