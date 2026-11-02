# Prompt: apply research items 1–8 to the horror build

Copy everything below the line into the coding agent.

---

You are working on "Rin", a Godot 4.7.2 first-person folk-horror game, repo `/Users/nguyenthinh/WorkSpace/tide-then-table`,
branch `try-horror-1st`. Work on a new branch `research-1-8` from the current `try-horror-1st` HEAD.

READ FIRST
- `CLAUDE.md` (conventions; note the "Removed in the horror build" section) and `PLAN.md` §10 (design, loop rules, story).
- `docs/HORROR_RESEARCH.md`: the design research. You implement its "Top 10" items 1–8; the numbers in brackets
  point to the lesson that explains each one. Read those lessons.
- Code you will touch: `systems/loop_calendar.gd`, `systems/story/omen_picker.gd`, `data/resources/omen_data.gd` +
  `data/omens/*.tres`, `scenes/home3d/bedroom_builder_3d.gd` + `bedroom_scene_3d.gd` + `nightmare_wake_3d.gd`,
  `systems/audio/horror_bed.gd` + `autoload/sfx.gd`, `scenes/sea3d/dark_night_3d.gd` + `dark_night_figure_3d.gd`,
  `scenes/ram3d/ram_reveal_3d.gd`, the 3D fishing (`scenes/fishing3d/*`, `systems/fishing/reel_logic.gd`,
  `data/resources/reel_tuning.gd`), `scenes/omens3d/*`, `data/story/news.tres` + `data/resources/news_data.gd`,
  `scenes/world3d/horror_materials.gd`, `scenes/ui/paper_reader.gd`.

THE GAME IN ONE PARAGRAPH
A 7-day loop (mùng 9 → rằm tháng Bảy, ghost month) in an invented Vietnamese fishing village. Each day: bedroom →
waterfront → restaurant shift → waterfront evening: sleep in the house, or row out and bring back at least 3 fish.
One omen per night at most (`OmenPicker`); an omen means stay home. Wrong night = nightmare wake and back to mùng 9.
Information only comes from what is read or overheard; Rin never explains rules. PS1 look, first person,
sounds synthesised in code (`SfxSynth`, `HorrorBed`), no audio files.

TASKS (research Top 10, items 1–8)
1. "Những điều kiêng" in the bedroom: a sheet of paper pinned on the wall near the door (reuse
   `HorrorMaterials.picture` with an existing paper texture, e.g. `paper_diary_page`), readable with E through
   `PaperReader`. Text: 4–6 short folk rules of the ghost month written as a grandmother's note, e.g. "Đêm trăng yên
   thì ra khơi, đừng để quán thiếu cá.", "Thấy lạ ở bến thì đừng xuống thúng.", "Mâm cúng mà bị đụng tới thì ở nhà.",
   "Ai gọi tên lúc khuya thì đừng dạ.". Content in a data file (`LinesData` or `NewsData`-like), not in code.
   It must teach the loop rule without saying "anomaly" or naming the game mechanics.
2. Ducking before stingers: add `HorrorBed.duck(seconds, level)` (or an equivalent in `Sfx`) that lowers the bed
   and ambience to near silence for 1–2 s, then restores. Call it right before the hull knocks, the name call,
   the door knocks in `NightmareWake3D`, and before anh Út's reveal. Make the reveal in `RamReveal3D` the ONE moment
   of full silence (bed and ambience fully off for ~1.5 s).
3. Directional omen sounds: play the name call, the hull knocks and the door knocks as 3D positional sounds
   (`AudioStreamPlayer3D`) placed in the world (towards the raft / the dock / the door), not as flat UI sounds.
   Keep `Sfx` as the single source of sound recipes; add a small helper there to play a recipe at a position.
   Keep everything silent when headless (tests).
4. Fishing without a fail state on calm nights: on a night without an omen the line cannot snap (tension caps
   below the snap threshold) and each fight lasts at most ~15 s; snapping stays possible on đêm âm only.
   Numbers in `reel_tuning.gd`; update `reel_logic_test` / `fishing3d_test`.
5. False sounds on calm nights: at random intervals on calm nights at sea play harmless but uncertain sounds —
   a fish slapping the water out of sight, the paddle knocking the thúng, the bobber twitching with no bite,
   a distant splash. Make them rare (one every 25–60 s) and never the exact đêm âm knock sound. Put it in its
   own small node added only on calm nights (next to `NightErrand3D`).
6. Omen subtlety: add `subtlety` (0 = obvious, 1 = subtle) to `OmenData`; set it on every omen `.tres`. Make
   `OmenPicker` prefer obvious omens on early days and allow subtle ones later (e.g. day ≤ 3: subtlety ≤ 0.4),
   keeping it deterministic per (loop, day). Every subtle omen must have a second tell elsewhere that night
   (e.g. a Cô Năm line, a sound at the waterfront); add those tells where missing. Update `omen_test`.
7. A hint after a reset: when the loop resets because the player missed an omen, the mùng 9 paper (or the
   "Những điều kiêng" note) carries one extra vague line about that kind of omen, e.g. "Người già dặn: tháng này
   thấy mâm cúng xô lệch thì đừng đi đâu xa." Store which omen was missed in a kept flag (prefix `note_` survives
   resets). Never name the mechanic. Keep `NightmareWake3D` under 5 s total.
8. Dread that grows by day: add `LoopCalendar.dread_level()` (0..1 from the day). `DarkNight3D` and the calm-night
   false sounds read it: on mùng 9–10 only sounds; figures can come close only from day 5 (13 tháng Bảy) on;
   anh Út's face appears only in the rằm reveal (check no earlier scene shows it).

RULES
- Typed GDScript only ("Inferred from Variant" is an error). Short English comments, short Vietnamese player text.
  Never real place names. Balance numbers in `@export` or Resources. Scripts under ~200 lines; split if larger.
- Pure logic in `systems/` with a standalone test scene in `scenes/test/` printing `PASS ...` / `FAIL ...` lines.
- Godot binary: `/Applications/Godot.app/Contents/MacOS/Godot`. After adding a `class_name` script run
  `"$G" --headless --path . --import`; it rewrites `project.godot`: run `git checkout project.godot` afterwards.
- Ad-hoc headless checks: `scenes/test/_tmp_*.gd/.tscn`, run with `--headless --path . --fixed-fps 60 --quit-after N
  res://... -- --no-autosave`, delete them afterwards. Always pass `-- --no-autosave`.
- Before finishing: `tools/run_tests.sh` must print `ALL OK` and `tools/run_bot.sh` must print `BOT OK`.
- Update `PLAN.md` §10 (one row: "Research 1–8" with what changed) and commit on `research-1-8` with a clear message.
  Do not push and do not merge into `try-horror-1st`.

REPORT
Branch and commit hash; one line per task (done / changed / skipped and why); new tests and the last lines of the
test and bot runs; anything you were unsure about.
