# Horror build: Codex brief 2 (art + writing)

Branch `try-horror-1st`. Same project and rules as [HORROR_ART_BRIEF.md](HORROR_ART_BRIEF.md): read its
"How to deliver" and "Shared style" first and follow them (PNG + `<name>.md` sidecar with prompt, tool,
date, post-processing; no readable text in images; no real place names, brands or people; do not wire
anything into the game; do not edit scenes, scripts or `.tres` files).

Two parts: **A. art** (images) and **B. writing** (Vietnamese text in one Markdown file).

## A. Art

### A1. Concepts for image-to-3D (fishing, rằm)

1024×1024, one object, centred, three-quarter view from slightly above, plain light-grey background, no
cast shadow, nothing cropped. Save to `assets/concepts/horror/<name>.png`.

| # | Name | Use |
|---|---|---|
| 1 | `fish_ca_thu` | Mackerel held in Rin's hand / in the basket |
| 2 | `fish_ca_mu` | Grouper |
| 3 | `fish_muc` | Squid |
| 4 | `fish_cua` | Mud crab |
| 5 | `fish_tom` | Two shrimps |
| 6 | `fish_oc_huong` | A few spotted babylon snails |
| 7 | `fish_glowing` | The aberrant glowing mackerel |
| 8 | `fish_basket` | Woven bamboo fish basket (giỏ cá) in the thúng |
| 9 | `fishing_rod` | Bamboo hand rod with a simple reel |
| 10 | `fishing_bobber` | Float (phao) |
| 11 | `anh_ut` | Anh Út, the lobster-raft owner |
| 12 | `ghost_ong_tu` | Rin's grandfather's ghost |
| 13 | `villager_chu_hai` | An old fisherman neighbour |

1–6. **Fish** (one prompt per species; change the subject line)
```text
<shared style> Concept for image-to-3D, single object, three-quarter view, plain light-grey background:
<SUBJECT>, freshly caught, wet and glistening, lying slightly curved as if just lifted from the water,
natural colours, realistic proportions, life size. No hands, no plate, no water.
```
Subjects: `a Spanish mackerel (cá thu), silver-blue with dark wavy bars`; `a brown-spotted grouper (cá mú)`;
`a pale pinkish squid with tentacles gathered`; `a dark green-brown mud crab with large claws`;
`two grey-blue raw shrimps side by side`; `three spotted babylon sea snails (ốc hương), cream shells with
brown spots`.

7. **fish_glowing**
```text
<shared style> Concept for image-to-3D, single object: a mackerel that is wrong — its skin semi-transparent,
faint cyan-green light glowing from inside along the spine, one eye milky white, a second small eye
beginning to grow behind the gill. Unsettling, not gory.
```
8. **fish_basket**
```text
<shared style> Concept for image-to-3D, single object: a Vietnamese fisherman's woven bamboo fish basket
(giỏ cá), round belly and narrow neck, a rope handle, wet dark bamboo, a little seaweed caught on it. Empty.
```
9. **fishing_rod**
```text
<shared style> Concept for image-to-3D, single object laid diagonally: a simple 2.5 m bamboo fishing rod
with a small worn metal reel taped to the handle, fishing line guides made of wire loops, frayed tape grip.
```
10. **fishing_bobber**
```text
<shared style> Concept for image-to-3D, single object: a hand-made fishing float, a cork body painted half
red half white with a thin bamboo stick through it, slightly chipped paint. Large in frame.
```
11. **anh_ut**
```text
<shared style> Concept for image-to-3D, full body, standing relaxed, front three-quarter view: a Vietnamese
man about 40, friendly face with an easy smile that does not reach his eyes, sun-darkened skin, short hair,
a faded dark-green work shirt with sleeves rolled up, loose khaki trousers, rubber boots, a towel around
his neck, strong forearms. A-pose friendly for rigging (arms slightly away from the body).
```
12. **ghost_ong_tu**
```text
<shared style> Concept for image-to-3D, full body, standing, front three-quarter view: an old Vietnamese
fisherman's ghost, thin, wearing a faded brown shirt and rolled trousers soaked through, a conical palm-leaf
hat (nón lá) hanging on his back, kind tired face, skin pale grey-blue, water dripping. Calm, sad, not scary.
```
13. **villager_chu_hai**
```text
<shared style> Concept for image-to-3D, full body, standing, front three-quarter view: an old Vietnamese
fisherman, lean, white stubble, faded blue shirt, short trousers, barefoot, holding a coil of rope.
```

### A2. Screens (2D)

Save to `assets/textures/horror/`. Opaque unless stated.

| # | Name | Size | Use |
|---|---|---|---|
| 14 | `title_keyart` | 1920×1080 | Main menu background |
| 15 | `ending_true` | 1920×1080 | Ending card: dawn, hoa đăng, ghosts on the pier |
| 16 | `ending_drowned` | 1920×1080 | Ending card: Rin's ghost under the water |
| 17 | `notebook_cover` | 1024×1400 | Rin's notebook closed (cover), for the clue notebook screen |

14. **title_keyart**
```text
<shared style> Wide key art, 16:9: night, a small Vietnamese fishing village pier seen from the water, one
round basket boat (thúng) tied at the end, a single oil lamp on the pier, mist on black water, faint shapes of
people standing on the water far behind the pier, a pale moon behind clouds. Large empty dark area on the left
third for the game title. No text.
```
15. **ending_true**
```text
<shared style> Wide 16:9 painting: dawn over a calm sea, hundreds of pink lotus paper lanterns (hoa đăng)
drifting out, a wooden pier where seven faint translucent figures stand in a row looking out to sea, the last
one an old man with a conical hat on his back, villagers small and dark on the shore. Hopeful, sad. No text.
```
16. **ending_drowned**
```text
<shared style> Wide 16:9 painting from under the water looking up: the dark surface, the round shadow of a
basket boat above, a faint lamp glow through the water, pale shapes of drowned people drifting nearby. Cold,
hopeless. No text.
```
17. **notebook_cover**
```text
<shared style> A cheap student notebook lying closed, top-down, flat: faded blue cardboard cover with an
EMPTY white label box in the middle, worn corners, a water stain, a pencil tucked in the spine. Opaque.
```

## B. Writing (Vietnamese)

One file: `docs/HORROR_TEXTS_DRAFT.md`. Claude Code moves the approved lines into the game's data files.
Rules for every line:
- Tháng cô hồn, Xóm Đèn (invented village), 1990s-feel. Never real place names, brands or people.
- Story facts must match PLAN.md §10 ("Cốt truyện"): anh Út, owner of the lobster raft, killed fishermen who
  saw his smuggling in the fog and hid the bodies under his raft; ông Tư (Rin's grandfather, two years ago)
  and the lighthouse keeper (last year) are among them; the ghosts warn, they do not harm.
- Rin never explains anything. Information comes from what is read and what others say. Keep lines short
  (one or two sentences, spoken Vietnamese of a coastal village: "nghe", "nha", "hông", "con").

Sections:
1. **Newspaper pages** ("Bản tin Ngủ Quên"): for each of the 7 days (mùng 9 … rằm), 3 alternative front pages
   (one headline sentence + one short sentence), so a day reads differently across loops. Clues may only get
   deeper as the days advance (day 1 vague, day 6 near the truth); never name anh Út before day 6.
2. **Found clues at sea** (bottle letters from ông Tư, pages of the lighthouse keeper's diary, objects): 12
   items, each marked with the earliest day it may appear and "letter" / "diary" / "object".
3. **Villager rumours**: 20 lines for Cô Năm, 10 for Bảo, 10 for Chú Hai, each tagged with the earliest day
   and whether it is for calm nights, omen nights or the morning after a wrong night.
4. **Omen lines**: for each omen in `data/omens/` (read the .tres files for ids and current lines), 2 extra
   lines someone could say about it (who says it + line).
5. **Rằm**: 6 extra lines for the villagers releasing hoa đăng, and 4 for anh Út at the restaurant (friendly
   on the surface, wrong underneath).
