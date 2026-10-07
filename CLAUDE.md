# Rin The Fisher — notes for coding agents

2D Godot game: fish at sea at night (top-down, limited by lamp oil, Dave the
Diver style — no ticking clock), sleep, then cook and sell at a Vietnamese
seafood restaurant 15:00–24:00 (side view), upgrade, repeat. `PLAN.md` is the
design source of truth (data tables, phase list, progress table, out-of-scope
list). The user is a solo dev new to Godot and writes in Vietnamese; reply in
Vietnamese, keep code comments in short English.

## Engine & language
- Godot **4.7.2**, binary: `/Applications/Godot.app/Contents/MacOS/Godot`.
- Typed GDScript only. "Inferred from Variant" is an error here: annotate
  (`var x: float = dict.get(...)`), including in throwaway test scripts.
- No plugins. Placeholder art only (`ColorRect`, `_draw()`); no images/audio.
- 640x360 viewport, stretch `viewport`, integer scaling.

## Conventions (from PLAN.md §3)
- One responsibility per script, aim for < ~200 lines; split when growing.
- Balance numbers as `@export` or in Resources, never scattered literals.
- Game data = custom Resources in `data/` (`FishData`, `DishData`,
  `BoatData`, `UpgradeData`, catalogs). New fish/dish/upgrade = new `.tres`
  + append to its catalog, no code change.
- Signals between nodes (past-tense names); node refs via `@export` + NodePath,
  not long `get_node("../..")` chains.
- Pure logic lives in `systems/` (no nodes): `GridInventory`, `KitchenLogic`,
  `MenuPlan`, `DayRating`, `SaveSystem`, `Story`, `BoatCondition`,
  `PhoneReports`, `CatchRoll`, `FishOrders`.
- Every big system has a standalone test scene in `scenes/test/` (F6).
- Vietnamese for all player-facing text. Money is shown as "70k".

## Testing
- Run everything: `tools/run_tests.sh` (imports, runs `scenes/test/*_test.tscn`,
  smoke-runs main scenes, exit code ≠ 0 on FAIL/script errors).
- Test scenes print `PASS ...` / `FAIL ...` lines; the runner counts them.
- Ad-hoc headless checks: write `scenes/test/_tmp_*.gd/.tscn`, run with
  `--headless --path . --fixed-fps 60 --quit-after N res://... -- --no-autosave`,
  then delete them. Always pass `-- --no-autosave` when a run can reach the sea
  scene, otherwise it overwrites the user's real `user://save.json`
  (`~/Library/Application Support/Godot/app_userdata/Rin The Fisher/`).
- After adding a `class_name` script, run `--import` once or other scripts
  fail to parse ("Could not find type"). The editor may segfault on exit after
  `--import`; harmless.
- macOS has no `timeout`; rely on `--quit-after`.
- Simulate input with `Input.parse_input_event(InputEventAction)` (reaches
  `_unhandled_input`); `Input.action_press` only affects polling.
- Bots that read minigame internals are the way to check difficulty; a bot
  with perfect info losing means humans can't win.

## Godot gotchas hit in this project
- Sibling `_ready` order: a node calling into a later sibling must handle
  `@onready` vars not being set yet (`if not is_node_ready(): await ready`).
- A lambda bound to a node that gets freed (scene change) never runs; keep
  test watchers on the root, not inside the changing scene.
- `create_timer()` keeps running while the tree is paused (process_always).
- JSON turns ints into floats; accept both when loading.
- `JSON.parse_string` prints an engine ERROR on bad input; use `JSON.new().parse()`.
- The fallback font has no ★/emoji glyphs.
- Left click is also the `cast` action: minigames use `_cast_just_pressed()` /
  `_cast_held()` (ignore clicks over buttons); buttons on overlays get
  `focus_mode = FOCUS_NONE` so Space can't press them.

## Map of the game
- Autoloads: `GameState` (money, day, storage, upgrades, flags, boat_hp,
  rating, last_catch), `DayClock` (display-only time of day: driven by
  `LampOil` at sea and by shift progress in the restaurant; `running` = night
  trip in progress), `SceneRouter` (`go_to(path, fade_color)`).
- Flow: main menu → sea night trip (`scenes/sea/sea_scene.tscn`, autosave at
  start) → dock / rescue (broken hull or no oil) → rest card
  (`scenes/rest/rest_scene.tscn`) → restaurant (menu planning → shift →
  summary + rating → upgrade shop) → next day (freshness loss) → sea …
  ending via fog whirlpool.
- Sea scene controllers: `FishingController` (rod spots → `FishingMinigame`:
  BiteGame then Timing/Tension; spot picks species via its featured fish +
  depth, `CatchRoll` rolls size: deeper = pricier/bigger, size scales price
  and difficulty; records in `GameState.best_sizes`), `NetController` (Q nets → HaulGame),
  `HoldManager` + `HoldUI` (grid hold, overflow queue, Tab), `HullController`
  (collision damage, F repair at dock), `LampOil` (trip limit + displayed
  time; no burn in minigames or at the dock), `BoatLamp` (light radius from
  oil; the night tint is dark, so lamps are how the player sees), `FogArea` (story), `DayTint` (night → dawn), `SeaHud`,
  `OffscreenMarkers` (edge arrows), `TutorialHints` (day 1), `PauseMenu` (Esc;
  must sit before `HoldUI` in the tree so the hold can eat Esc first).
- Places (`scenes/sea/poi/`, under `Places` in the sea scene): subclasses of
  `PointOfInterest` (own lamp, E to visit, `_interact()` awaits
  `PoiDialog.ask()`): `WhaleShrine`, `OldManHut`, `Lighthouse`, `LobsterRaft`.
  Lines follow `Story.stage()`. `PoiDialog` sits before `PhoneApp`.
- Fish orders (`FishOrders`, `GameState.orders`): rolled when the next day
  starts (restaurant), shown on the sea HUD + phone tab, delivered/expired
  on the rest card.
- Restaurant: `MenuSetupPanel` + `MenuPlan`, `CustomerManager`,
  `CookingOverlay` (Grill/Steam/Stir), `UpgradeShop`, `RepairButton`.
- Phone app "Rin's Catch" (`scenes/ui/phone_app.tscn`, J): in both sea and
  restaurant, LAST in the tree; text from `PhoneReports` (pure). Lore: Rin is
  an ex-developer who wrote the app; story clues appear as `[WARN]`/`[ERR]`
  log lines and glitched aberrant-fish names.

## Workflow the user expects
- Propose first when asked for ideas; implement after they agree.
- After a chunk of work: run tests, update `PLAN.md` (progress/notes), summarize
  in Vietnamese with how to test, suggest a commit message.
- Don't add things from PLAN.md "Ngoài phạm vi" without asking.
