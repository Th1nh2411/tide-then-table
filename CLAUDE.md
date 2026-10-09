# Rin The Fisher — notes for coding agents

2D Godot game: fish at sea at night (top-down, limited by lamp oil, Dave the
Diver style — no ticking clock), sleep, then cook and sell at a Vietnamese
sidewalk seafood restaurant 15:00–24:00 (top-down 3/4), upgrade, repeat. `PLAN.md` is the
design source of truth (data tables, phase list, progress table, out-of-scope
list). The user is a solo dev new to Godot and writes in Vietnamese; reply in
Vietnamese, keep code comments in short English.

## Engine & language
- Godot **4.7.2**, binary: `/Applications/Godot.app/Contents/MacOS/Godot`.
- Typed GDScript only. "Inferred from Variant" is an error here: annotate
  (`var x: float = dict.get(...)`), including in throwaway test scripts.
- No plugins. Placeholder art only (`ColorRect`, `_draw()`); no images/audio.
- 640x360 viewport, stretch `viewport`, integer scaling; default window
  1920x1080 (x3). F11 toggles fullscreen anywhere (`SceneRouter._input`).
  Top-down art uses Stardew-scale 16 px tiles (characters 16x32).

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
  `PhoneReports`, `CatchRoll`, `FishOrders`, `MarketStock`, `OrderPicker`,
  `TableBill`, `StaffRoster`, `QuestLog`.
- Every big system has a standalone test scene in `scenes/test/` (F6).
- Vietnamese for all player-facing text. Money is shown as "70k".
- Keep on-screen text short. How-to hints are first-time pointers (`Guide`:
  ring + arrow on the thing + 3-6 words, shown once per id, story flag
  "tip_<id>"; rules in `RestaurantGuide` / `SeaGuide`; minigame hints via
  `Guide.once()`), any day a feature first shows up. The full guide is the
  `HelpPanel` ("Hướng dẫn", from the pause menu and the main menu) — add new
  controls there and a Guide rule for a new feature, never permanent HUD text.
- Place names are invented (Xóm Đèn, dải đảo Ngủ Quên, Gò Vỏ Ốc, Đá Canh
  Đêm, Miếu Cá Ông). Never use or echo real place names in game text or docs.

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
  rating, last_catch, pantry, staff), `DayClock` (display-only time of day: driven by
  `LampOil` at sea and by shift progress in the restaurant; `running` = night
  trip in progress), `SceneRouter` (`go_to(path, fade_color)`).
- Flow: main menu → (New Game: `scenes/intro/intro_scene.tscn`, cutscene
  `intro_call`: Rin, jobless in his rented room, calls Bảo to open the
  restaurant) → sea night trip (`scenes/sea/sea_scene.tscn`, autosave at
  start) → dock (E: unload the hold and keep fishing, or go home) / rescue (broken
  hull or no oil) → rest card
  (`scenes/rest/rest_scene.tscn`, autosave #2: Continue resumes at the
  restaurant via `GameState.resume_at`; use `SaveSystem.autosave()`) → restaurant (menu planning → shift →
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
  `OffscreenMarkers` (edge arrows), `SeaGuide` (first-time pointers), `PauseMenu` (Esc;
  must sit before `HoldUI` in the tree so the hold can eat Esc first).
- Night variety: `BoatRange` (foam line from `BoatData.max_depth`, pushes
  back), submerged `Rock`s (LIGHT_ONLY material), `WeatherController` +
  `WeatherData`/`WeatherCatalog` (GameState.weather_id rolled on the rest
  card), `NightEvents` in `scenes/sea/events/` (stranded boat, bottle,
  jellyfish, dolphins; tow pay + `GameState.trip_notes` at trip end).
  Over-bright colors (x3-x5) are how things glow through the night tint.
- Places (`scenes/sea/poi/`, under `Places` in the sea scene): subclasses of
  `PointOfInterest` (own lamp, E to visit, `_interact()` awaits
  `PoiDialog.ask()`): `WhaleShrine`, `OldManHut`, `Lighthouse`, `LobsterRaft` (buys the whole hold, or picked fish in
  `HoldUI.open_sell` sell mode: drag onto "Bán" / right-click).
  Lines follow `Story.stage()`. `PoiDialog` sits before `PhoneApp`.
- Phone map (`PhoneMap`, tab "Bản đồ"): static snapshot captured by the sea
  scene (`_capture_map`), live boat (group "boat") + nets; pins in
  `GameState.map_pins` (saved, also edge markers at sea).
- Fish orders (`FishOrders`, `GameState.orders`): rolled when the next day
  starts, shown on the sea HUD + phone tab; at shift start the fish is set
  aside (`reserve_for_shift`) and the regular comes to the restaurant;
  unserved fish released, overdue orders expire after the shift.
- Restaurant (top-down 3/4 Vietnamese sidewalk, 40x23 tiles of 16 px):
  `StreetRoom` (ASCII map -> `RoomGrid` with A* paths; shop front at the top,
  pavement, only the near part of the road at the bottom; Rin's kitchen =
  in the middle of the pavement: plate table as a bench on the left (next
  to the tables), then bin + food cart with Bảo's stove right of it, the fridge against the wall above the bench (bought groceries
  go into Rin's bag first; E on the fridge puts them away), an open
  aisle in front, then Rin's 2-cell charcoal grill "N" (under the cart's
  left end); the beer tap "U" is the keg on the cart's right end; tables on the left (columns 2 cells
  apart, nearest the stove first) =
  first N slots from the seats upgrade; draws upgrade looks, also previewed
  while renovating), `StreetBackdrop` (shop front + traffic), `StreetProps`
  (static drawings), `StreetPerson` (16x32 body, path walking) -> `RinChef`
  (player = the waiter: WASD, Shift dash, E on the faced cell; carries plates,
  cleans tables, grills, pours beer), `ChefBao` "Bảo" (the chef, behind the
  stove from day 1: cooks every non-grilled dish by himself, oldest ticket
  first, puts plates on the plate table; `ChefBao.cooks(dish)`), `Customer` (a party of 1-2: the leader orders 1-3
  `TableOrder` lines — `CustomerManager.waiting` holds lines, oldest first —
  eats plates as they come, may order another round, pays for the table at
  once; the second guest sits on the spare stool. Most come by motorbike:
  `CustomerBikes` road -> park by the curb -> walk to the table and back).
  `MarketStall` (Cô Năm's grocery next door, right: E in front of the "V"
  counter opens `MarketPanel`, her product list; buying puts goods into a
  `MarketStock` over `GameState.pantry` (saved); rau muống + beer are always
  on the menu; each buy is one pack or a cheaper bulk buy (`bulk_packs`,
  `bulk_cost`; Shift + number); beer is bought by the tower (3 L,
  `market_pack`, stock in litres) or 10 at once, served as 3 L towers
  (`portion_units`), needs no cooking (`instant_serve`) and keeps overnight (`keeps_overnight`), rau is wasted
  at closing),
  `StaffCrew` + `StaffWorker` + `StaffRoster` (from day 3: hired helpers
  carry plates and clean tables; hiring / job ads live in the phone tab
  "Nhân viên" (`PhoneStaff`, `GameState.staff_changed` tells the crew); wages
  at closing; `GameState.staff`, data in `data/staff/`; Vy, the heroine,
  applies on day 3),
  `MenuSetupPanel` + `MenuPlan`, `CustomerManager` (spawning, ordering,
  payment; seats/decor upgrades, rich customers, regulars; balance numbers in
  `ServiceTuning` `data/restaurant/service_tuning.tres`; helpers
  `OrderPicker`, `TableBill`, `PartyWalker`, `FloatingText`), `DishShelf`
  (pure: plate-table slots + arrival-order matching), `DiningTables` (pure:
  free/taken/dirty), `KitchenStation` (no dish buttons: E on the charcoal
  grill "N" grills the oldest waiting grilled dish — Rin steps behind it, the
  compact `CookingOverlay` runs over the road, the dish lands in his hands; E
  on the beer tap "U" by the ice box pours a tower for the oldest beer order
  (`BeerPourGame` in the same overlay: hold to pour, short bursts keep the
  foam thin, release in the band; spilling wastes a litre);
  E on the plate table / tables; `menu_rows()` feeds the LED board),
  `ServiceHud` (order tickets over the shop front), `MenuBoard` (small LED board by the curb in the middle, "E" cells,
  y-sorted: dish pictures + servings left), `ServiceMarkers` (bubbles, carried plate -> its table pulses, "E"
  key over what E acts on — no prompt text), `RepairButton`, `RenovationMode`
  ("Sửa quán": in-place renovation of seats/decor/kitchen/ice box with
  preview, Hủy / Xác nhận); menu planning opens by clicking the LED sign
  (MenuBoard: pulsing gold frame + bouncing arrow while clickable, hover
  lifts it, hand cursor); pinned HUD button "Sửa quán"
  (when not serving) and "Ra khơi" (after the summary) — no automatic scene
  changes.
- Cutscenes (Stardew style): write a `Cutscene` .tres in `data/cutscenes/`
  (commands listed in `CutsceneScript`), add marker Node2Ds under the scene's
  `CutsceneMarkers`, play with `CutscenePlayer.play()` (sea scene plays
  `trip_end_cutscenes` after a trip; the restaurant plays
  `after_shift_cutscenes` when the summary closes; the intro scene plays
  `intro_call`; the restaurant plays `arrival_cutscenes` before the menu:
  `opening_day`, `beer_day` (day 2), `vy_arrives` (day 3, a choice can hire
  her: flag `vy_hire_now`); the sea's trip-end list has `cat_arrival` and
  `fog_omen`). Commands include `remove <actor>`; actor kinds rin, bao, vy,
  co_nam, guest, cat, crate, rin_bed, glow. dialogue_test checks every marker
  a cutscene uses exists in its scene. It pauses the tree; its actors,
  camera, tweens and DialogueBox run PROCESS_MODE_ALWAYS.
- The cat: `PetCat` (restaurant), flags `cat_adopted` / `cat_gone` /
  `pet_name`; use `{pet}` in dialogue/cutscene text.
- Dialogue: write a `Dialogue` .tres in `data/dialogues/` ("Name: line" per
  line; min_day / requires_flag / once / sets_flag / priority) and add it to
  a `Talker` child of the character (character needs `talk_position()`, optional
  `can_talk()`). `DialogueLibrary` picks and marks seen (story_flags →
  saved); `DialogueBox` shows it (pauses). Rin talks with E next to them.
- Sea gear upgrades (boat, rod, lamp) are bought in the phone's "Nâng cấp"
  tab (`PhoneShop`); restaurant upgrades only via "Sửa quán".
- `QuestTracker` (sea + restaurant, top-left): faded one-line "next step"
  box, the full main quest + fish orders on hover, never takes clicks;
  content from `QuestLog` (pure: Story stage + boat upgrades, FishOrders).
  The phone has no orders tab any more.
- Phone app "Rin's Catch" (`scenes/ui/phone_app.tscn`, J): in both sea and
  restaurant, LAST in the tree; text from `PhoneReports` (pure). Lore: Rin is
  an IT graduate (male) whose failed startup (with friend Bảo, now the
  restaurant's chef — he cooked the best instant noodles in their dorm) left
  this app; story (PLAN.md §1): the fog hides a portal to a
  parallel sea, cá Ông are its guardians, the Thâm Lam corporation exploits
  it. Clues appear as `[WARN]`/`[ERR]`
  log lines and glitched aberrant-fish names.

## Workflow the user expects
- Propose first when asked for ideas; implement after they agree.
- After a chunk of work: run tests, update `PLAN.md` (progress/notes), summarize
  in Vietnamese with how to test, suggest a commit message.
- Don't add things from PLAN.md "Ngoài phạm vi" without asking.
