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
- No plugins. Placeholder art (`ColorRect`, `_draw()`) until PNGs exist:
  `Art` (scenes/common/art.gd) draws `assets/sprites/<name>.png` stretched
  into the thing's in-game rect and returns false when missing, so every
  hook is `if not Art.draw(...): <placeholder>` (palette "Xóm Đèn": 38 colours
  from Apollo + 5 in assets/palette/, F7 in debug builds shows the game in it
  (`PalettePreview`), `tools/pixelize.py` cleans AI drafts into sprites; PixelLab MCP is set up for
  this project, the next steps are in ART_PLAN.md;
  sheets: `draw_frame`,
  `draw_sheet`, `draw_person` (standing plays `<sheet>_idle` if present: breath + blink, `tools/make_idle.py`; look at sheets in `scenes/test/sprite_viewer.tscn`); names listed in ASSETS.md "Tên file"). No
  audio files. Sounds are built in code: autoload `Sfx` (`Sfx.play("catch")`,
  `Sfx.hold("sizzle", on)`, `Sfx.ambience("sea")` per scene; recipes in
  `Sfx.SOUNDS` / `LOOPS`, synth `SfxSynth`; every Button clicks; mute in the
  pause menu, saved in user://settings.cfg; silent when headless). Quit via
  `SceneRouter.quit_game()` (stops sounds first, else playbacks leak).
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
- Notices are speech, not system text: `SeaHud.flash_message` / the
  restaurant's `_show_message` show a `SpeechLine` bubble over the speaker,
  Rin talking to himself by default ("Sóng to quá... phải nâng cấp thuyền"),
  "Bảo: ..." / "Cô Năm: ..." over them; "NEO: ..." / "[...]" is NEO, the AI
  assistant in Rin's Catch (JARVIS-like, says "tôi" / "anh Rin"; bottom-left
  with its `NeoAvatar` hologram, "[WARN]"/"[ERR]" in red): system reminders
  (oil, hold, repairs, orders, rush, closing time, today's dish, rewards) are
  NEO's, Rin keeps the emotional ones (catches, spills, "sóng to quá"). One bubble per
  speaker, a speaker's next line waits for the current one (1-2.5 s). Write
  new ones in Rin's voice (first person, short); situational ones say it
  once per trip / shift (oil 25% / 10%, hold 80%, first guest lost, 15% of
  the shift left), never a permanent HUD warning.
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
- Whole game: `tools/run_bot.sh` (`tools/bot/game_bot.gd`: New Game → ending
  through the real scenes, prints a line per day + minutes of human play,
  exit ≠ 0 on STUCK / SAVE MISMATCH / no ending; `POLICY=balanced` for the
  other upgrade order). Run it after changing pacing, the day flow or saves;
  it reads scene internals (`_closer`, `_menu_panel`...), keep it in sync.
- Playtest builds: `tools/export.sh` (runs the tests, then the presets in
  `export_presets.cfg` → `build/mac/RinTheFisher.zip`, `build/windows/
  RinTheFisher.exe`; needs export templates for this exact Godot version,
  in ~/Library/Application Support/Godot/export_templates/<version>; macOS
  universal needs `import_etc2_astc` on, already set in project.godot).
  Hand out `PLAYTEST.md` with it.
- Debug keys (debug builds): sea 1-3 boat, F2 open the fog; restaurant F1
  fish, F2 beer; both F3 play this scene's cutscenes one by one, F4 toggle
  Nhịp Sóng (`CutsceneDebug`); anywhere F9 = `DebugJumpMenu`: jump to any
  day's night / restaurant or any cutscene, state rebuilt by `StoryTimeline`
  (pure; a new cutscene needs its [day, slot] in `StoryTimeline.WHEN`,
  story_timeline_test checks it); autosave stays off after a jump.
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
  rating, last_catch, pantry, staff, play_seconds), `Sfx`, `DayClock` (display-only time of day: driven by
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
  ending via fog whirlpool (omen on day 4 or the first glowing mackerel,
  fog opens the next day; a full run is ~5 days / ~45 min, measured by a
  whole-game bot). The ending shows a run card (`EndingStats`: days +
  minutes, fish, guests, earnings) and a thank-you for playtesters.
- Sea view matches the restaurant: the boat camera zooms x2 (Rin is 16x32
  on screen, standing in a nón lá; `Boat._draw` is 3/4: the deck turns, the
  hull side always faces the bottom of the screen, Rin and the cat stay
  upright). World coordinates / speeds are unchanged; art for the sea is
  drawn at screen size and placed at scale 0.5.
- Sea scene controllers: `FishingController` (rod spots → `FishingMinigame`:
  `FishFightGame` directly: one cast shows six fish; A/D moves boat/line,
  W/S raises/lowers the hook, Space hooks the aimed fish, then W reels and S
  gives slack; E spins a green/yellow/red all-in wheel; trip stun reaches 100%
  = Rin faints and is rescued); spot picks species via its featured fish +
  depth; the rod fight is full screen, side view (`FishFightView` + `FishFightBackdrop` per zone + `FishFightGauges`: reel, level, daze, wheel; art list docs/ui_art_needed_fishing.md), `FishPortrait` on a card top right (nets keep the crate panel, portrait standing up): a shadow + "?" while waiting for the
  bite and for species not in the Dex yet, named "???"), `CatchRoll` rolls size: deeper = pricier/bigger, size scales price
  and difficulty; records in `GameState.best_sizes`), `NetController` (Q nets → HaulGame; nets bring shrimp / crab / snails, each rolled from the zone with its own size: near shore mostly shrimp, reef mostly crab — rods catch fish and squid only),
  `HoldManager` + `HoldUI` (grid hold, overflow queue, Tab; a species caught
  for the first time is tagged NEW and `new_species_caught` shows
  `NewCatchCard`: shadow → slow reveal → "NEW!", name, weight), `HullController`
  (collision damage, F repair at dock; the first hit of a trip makes Rin say how to repair, SeaGuide points at the hull readout, then "F: sửa thuyền" at the dock; a nearly full hold → Rin + pointer "Về bến dỡ bớt cá"), `LampOil` (trip limit + displayed
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
  `GameState.map_pins` (saved, also edge markers at sea). `open_map` (M)
  opens the big map (`MapOverlay`, owned by PhoneApp: zone names, legend,
  distance home). Boat repair is a button in the phone's "Thuyền" tab
  (`RepairButton`; at sea only at the dock via `HullController.repair`, or
  F at the dock) — no repair button on the restaurant HUD.
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
  (player = the waiter: WASD, Space dash (3D: Shift runs on stamina, `StaminaBar3D`), E on the faced cell; carries plates,
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
  (`portion_units`), needs no cooking (`instant_serve`) and never spoils (`keeps_overnight`); rau
  is kept in freshness batches that age every night like the fish
  (`MarketStock.age` in `GameState.advance_day`), oldest cooked first,
  older = cheaper, thrown away at 0),
  `StaffCrew` + `StaffWorker` + `StaffRoster` (from day 3: hired helpers
  carry plates and clean tables; hiring / job ads live in the phone tab
  "Nhân viên" (`PhoneStaff`, `GameState.staff_changed` tells the crew); wages
  at closing; `GameState.staff`, data in `data/staff/`; Vy, the heroine,
  applies on day 4),
  `MenuSetupPanel` + `MenuPlan`, `CustomerManager` (spawning, ordering,
  payment; seats/decor upgrades, rich customers, regulars; balance numbers in
  `ServiceTuning` `data/restaurant/service_tuning.tres`; helpers
  `OrderPicker`, `TableBill`, `PartyWalker`, `FloatingText`), `DishShelf`
  (pure: plate-table slots + arrival-order matching), `DiningTables` (pure:
  free/taken/dirty), `KitchenStation` (no dish buttons: E on the charcoal
  grill "N" grills the oldest waiting grilled dish — Rin steps behind it, the
  compact `CookingOverlay` runs over the road, the dish lands in his hands; E
  on the beer tap "U" by the ice box pours a tower for the oldest beer order
  (Rin's grill dishes carry a small flame on tickets, bubbles and the LED
  board, `StreetProps.rin_grills` / `draw_flame`; the grill glows while one
  waits) (`BeerPourGame` in the same overlay: hold to pour, short bursts keep the
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
  `CutsceneMarkers` (`CutsceneCamera` resolves them and moves the camera;
  `CutsceneNamePrompt` is the cat's name box; `emote <actor> !|?|...|heart|note`
  gives that speaker's next line a portrait mood), play with
  `CutscenePlayer.play()` (sea scene plays
  `trip_end_cutscenes` after a trip; the restaurant plays
  `after_shift_cutscenes` when the summary closes; the intro scene plays
  `intro_call`; the restaurant plays `arrival_cutscenes` before the menu
  (`ArrivalCutscenes`): `opening_day`, `wave_awaken` (day 3), `vy_arrives` (day
  4, a choice can hire her: flag `vy_hire_now`); and
  `after_shift_cutscenes`: `beer_day` (after the first shift: a guest asks
  for beer, sold from day 2), `nam_fog_tale` (after day 3), `regular_thanks` (after the first fish order is
  served, flag `regular_served_once`); `vy_stands_up` (after Vy's first shift, flag `worked_vy`
  set by `ShiftCloser` for every hired person; sets `vy_warmed`: Vy turns from spoiled to warm); the sea's trip-end list has `wave_faint` (night 3), `cat_arrival`
  (night 2) and `fog_omen` (night 4)). Commands include `remove <actor>`; actor kinds rin, bao, vy,
  co_nam, guest, cat, crate, rin_bed, glow. dialogue_test checks every marker
  a cutscene uses exists in its scene. Effects (`CutsceneEffects`): `rain
  on|off`, `slow <factor> <s>` (0.02 = frozen rain, teal tint, heartbeat),
  `sfx`, `ambience`, `if_flag <flag> <label>`; markers may be "@group"
  (e.g. @boat). Anything that would double an actor
  must hide while it plays: `hidden_nodes` (restaurant: Rin, Bảo, Cô Năm),
  `hidden_groups` (restaurant: "staff", "customers"), and things drawn
  inside another node check `CutscenePlayer.playing` + redraw on `started` /
  `finished` (Rin and the cat on the boat). It pauses the tree; its actors,
  camera, tweens and DialogueBox run PROCESS_MODE_ALWAYS.
- Nhịp Sóng (Rin's power, `WaveMark` pure + `WavePower` node in both
  scenes, key C). How he gets it: trip-end cutscene `wave_faint` (end of
  night 3, Rin still on his boat by the dock, markers "@boat+x,y"): a glowing
  mackerel by the hull, Rin tries one more cast, it bites his hand and swims off (story only: never in the hold /
  Dex, no omen), he passes out, Bảo finds him. The real glowing mackerel far
  out stays rare / hard and still triggers the omen. `fog_omen` (night 4)
  makes the mark glow (its touch-and-faint branch is only a fallback). Both set "wave_fainted"; the
  restaurant arrival cutscene `wave_awaken` (late, running in the rain
  without an umbrella, the rain freezes mid-air) sets "wave_mark".
  Slows the world (Engine.time_scale) a few real seconds: at sea only during
  the fishing minigame, in the restaurant the whole street while Rin keeps
  his speed (`WavePower.rin_unslowed`, RinChef divides delta back). Charges
  per night / per shift (2, +1 per 3 aberrant fish, max 4). Once he has it:
  big / aberrant fish fight harder, grill dishes from 80k are trickier, and
  the restaurant has a rush hour (`ServiceTuning.rush_*`). Lines: vy_mark,
  cat_mark, Ông Tám once (flag "tam_mark"). First-time pointers "wave" (SeaGuide)
  / "wave_shop" (RestaurantGuide) on the mark (`Guide.wave_badge_target`).
  Test: scenes/test/wave_test.tscn.
- The cat: `PetCat` (restaurant: on top of the fridge), rides at the stern at sea (`Boat._draw_cat`), flags `cat_adopted` / `cat_gone` /
  `pet_name`; use `{pet}` in dialogue/cutscene text.
- Dialogue: write a `Dialogue` .tres in `data/dialogues/` ("Name: line" per
  line, "Name (mood): line" picks a portrait mood; `DialogueBox` is Nine Sols
  style: `DialoguePortrait` bust in a bottom corner — Rin left, others right —
  art `portraits/<slug>[_<mood>]`, placeholder drawn otherwise — and a bubble
  with a tail; no speaker = narration box; min_day / requires_flag / blocked_by_flag / once / sets_flag / priority) and add it to
  a `Talker` child of the character (character needs `talk_position()`, optional
  `can_talk()`). `DialogueLibrary` picks and marks seen (story_flags →
  saved); `DialogueBox` shows it (pauses). Rin talks with E next to them.
- Today's dish (`DailyTrend`, Dave-style): rolled when the night starts
  among dishes Rin can really serve (caught + cookable; first night:
  near-shore seafood), sells x1.5 and is ordered x3 as often (TableBill,
  OrderPicker), NEO announces it at sea and in the restaurant, red ring on
  the LED board, "HOT" in the menu panel; story flags trend_dish / trend_day.
  Collection rewards (`CollectionRewards`): new species, Dex milestones (3, 6
  species, flag "dex_reward_<n>"), big size records pay money, NEO says it;
  aberrant fish never count; the phone Dex shows the next milestone.
- Dishes: each seafood has 2-3 dishes by cooking method (`DishData.cook_type`
  BOIL / GRILL from the start, STEAM at kitchen 1, STIR at kitchen 2 =
  `kitchen_level`). `DishBook` (pure): known = its seafood was caught once,
  cookable = kitchen level; `MenuPlan.kitchen_level` blocks the rest (menu
  panel and phone hide dishes the kitchen can't cook yet); regulars eat the priciest
  cookable dish; the rest card shows "Món mới!" once per dish (flag
  "dish_<id>"). Rin grills GRILL dishes (GrillGame + `GrillView`: the
  seafood big on the coals, browning, flipped on each press); Bảo cooks the rest.
- Sea gear upgrades (boat, rod, lamp) are bought in the phone's "Nâng cấp"
  tab (`PhoneShop`); restaurant upgrades only via "Sửa quán".
- `QuestTracker` (sea + restaurant, top-left): faded one-line "next step"
  box, the full main quest + fish orders on hover, never takes clicks;
  content from `QuestLog` (pure: Story stage + boat upgrades, FishOrders).
  The phone has no orders tab any more.
- Restaurant helpers (keep restaurant_scene.gd an orchestrator):
  `RestaurantEvening` (Sửa quán / Ra khơi buttons, renovation, next day),
  `RestaurantTools` (WavePower, QuestTracker, RestaurantDebug F1/F2,
  CutsceneDebug F3/F4), `ShiftCloser` (the shift's money / guests / market
  counters and closing: clears the kitchen, wages, rating, day record,
  summary), `ShiftReport` (pure: summary text),
  `ArrivalCutscenes`, `StreetRoomPainter` (StreetRoom's drawing),
  `PartyFactory` / `PartyOrders` / `PartyCheckout` / `PartyWalker`
  (CustomerManager's parties). Staff can have lines (`StaffData.dialogues`,
  `idle_lines`, `later_flag` + `later_idle_lines` for small talk after a mood change: StaffCrew adds a Talker; Vy has 6 by day/flag).
- Art to replace the placeholders is listed in `ASSETS.md`.
- Phone app "Rin's Catch" (`scenes/ui/phone_app.tscn`, J): in both sea and
  restaurant, LAST in the tree; text from `PhoneReports` (pure). Lore: Rin is
  an IT graduate (male) whose failed startup (with friend Bảo, now the
  restaurant's chef — he cooked the best instant noodles in their dorm) left
  this app; story (PLAN.md §1, keep lines in line with its timeline + fog rules: Rin's grandpa ông Tư vanished in the fog two years ago, Vy is ông Tám's granddaughter): the fog hides a portal to a
  parallel sea, cá Ông are its guardians, the Thâm Lam corporation exploits
  it. Clues appear as `[WARN]`/`[ERR]`
  log lines and glitched aberrant-fish names.

## Workflow the user expects
- Propose first when asked for ideas; implement after they agree.
- After a chunk of work: run tests, update `PLAN.md` (progress/notes), summarize
  in Vietnamese with how to test, suggest a commit message.
- Don't add things from PLAN.md "Ngoài phạm vi" without asking.
