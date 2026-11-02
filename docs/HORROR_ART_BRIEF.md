# Horror build: art brief for Codex

Branch `try-horror-1st`. The game (PLAN.md §10) is a first-person, PS1-style folk-horror game in an
invented Vietnamese fishing village, Xóm Đèn, during the 7th lunar month ("tháng cô hồn", ghost month).
Three places: Rin's small room, the waterfront outside his house (house, pier, the sea), the sidewalk
seafood restaurant. Everything is placeholder boxes right now; this brief lists the art that replaces them.

## How to deliver

- One image per item, PNG. Follow the size and background in each item.
- Put files where the item says. Next to each PNG write `<name>.md` with the prompt used, the tool, the
  date and any post-processing (same as `assets/textures/sea3d/*.md`).
- Do not wire anything into the game. Claude Code integrates after review.
- Never put readable text in an image unless the item asks for it; the game draws its own text.
- Never use or echo real place names, real brands, logos or real people.

## Shared style (paste at the start of every prompt)

```text
Style: late-1990s PS1 survival-horror look for a low-poly 3D game. Low detail, readable shapes,
slightly desaturated colours, soft grainy noise, no photographic sharpness. Rural coastal Vietnam
in the 1990s, poor fishing village, humid and worn. Palette: faded lime-wash yellow and green
plaster, rust, dark wet wood, grey-blue sea, warm oil-lamp amber as the only bright accent.
No text, no logos, no watermark.
```

## Priority 1: what the player sees every day

| # | Name | Use | Size / background | Save to |
|---|---|---|---|---|
| 1 | `wall_plaster_old` | Bedroom and house walls | 512×512, tileable, opaque | `assets/textures/horror/` |
| 2 | `floor_wood_planks` | Bedroom floor, pier deck | 512×512, tileable | `assets/textures/horror/` |
| 3 | `ground_village` | Waterfront ground | 512×512, tileable | `assets/textures/horror/` |
| 4 | `roof_tin_rusty` | House and neighbour roofs | 512×512, tileable | `assets/textures/horror/` |
| 5 | `door_wood_old` | Bedroom door, house door | 512×1024, opaque, not tileable | `assets/textures/horror/` |
| 6 | `calendar_sheet` | Tear-off wall calendar page | 512×640, opaque | `assets/textures/horror/` |
| 7 | `newspaper_front` | The morning paper Rin reads | 1024×1400, opaque | `assets/textures/horror/` |
| 8 | `sky_dawn_overcast` | Morning sky at the waterfront | 4096×2048 equirectangular | `assets/textures/sea3d/` |

1. **wall_plaster_old**
```text
<shared style> Seamless tileable texture, flat front view: old lime-washed plaster wall of a poor
Vietnamese fishing house, faded mustard yellow, damp stains rising from the bottom, small cracks,
patches where the paint peeled to grey render. Even lighting, no shadows, no objects.
```
2. **floor_wood_planks**
```text
<shared style> Seamless tileable texture, top-down: dark worn wooden floor planks running vertically,
salt-bleached grain, a few nail heads, gaps between boards, slightly damp. Even lighting.
```
3. **ground_village**
```text
<shared style> Seamless tileable texture, top-down: packed sandy earth of a fishing village path,
grey-brown, scattered broken shells, small pebbles, faint footprints, damp patches. Even lighting.
```
4. **roof_tin_rusty**
```text
<shared style> Seamless tileable texture, flat view: corrugated tin roof sheets, ridges running
vertically, uneven rust streaks and patches, dull grey metal between. Even lighting.
```
5. **door_wood_old**
```text
<shared style> Front view of a single old wooden house door, flat on, filling the frame: vertical
planks painted faded green over dark wood, paint worn off near the handle, a simple iron latch and
a small ring handle at the right, a dark gap at the bottom. No wall around it.
```
6. **calendar_sheet**
```text
<shared style> Front view of one blank page of a Vietnamese tear-off daily wall calendar ("lịch
bloc"): off-white thin paper, a red band across the top, a large empty white area in the middle where
a big date number will go, a smaller empty strip near the bottom, slightly curled corners, a torn
edge at the top where yesterday's page was ripped off. Leave every text area empty.
```
7. **newspaper_front**
```text
<shared style> Front page of a cheap 1990s provincial newspaper, flat scan: yellowed newsprint, a bold
masthead band at the top left EMPTY (the game writes the title), one large empty headline box, a
grainy black-and-white photo of fog over a calm sea with a small empty round basket boat, columns of
unreadable grey lines of body text. No readable words anywhere.
```
8. **sky_dawn_overcast**
```text
<shared style> Seamless 360-degree equirectangular sky panorama, exactly 2:1, horizon at the
vertical centre: heavy grey overcast dawn over the sea, low clouds, a pale washed-out sun disc
barely visible behind the clouds at about 15 degrees elevation, cold blue-grey, no land, no sea,
no birds. The top and bottom 3% a uniform colour; left and right edges must match.
```

## Priority 2: omens and the night (the core of the game)

These are **concept images for image-to-3D** (Hunyuan, see `docs/ART_PIPELINE.md`): one object,
centred, three-quarter view from slightly above, plain light-grey background, no cast shadow, nothing
cropped. 1024×1024. Save to `assets/concepts/horror/<name>.png`.

| # | Name | What it is in the game |
|---|---|---|
| 9 | `offering_tray_normal` | The mâm cúng cô hồn in front of the shop on calm nights |
| 10 | `offering_tray_eaten` | The same tray on its omen night |
| 11 | `joss_paper_bucket` | Vàng mã burning by the curb |
| 12 | `hoa_dang_lantern` | Floating paper lantern at the pier |
| 13 | `pier_lamp_post` | Post at the pier head with an oil lantern |
| 14 | `drowned_figure` | The figure standing on the water / at the pier head |
| 15 | `drowned_hand` | The hands that take the thúng on a wrong night |
| 16 | `bottle_letter` | Calm-night errand: ông Tư's letter in a bottle |
| 17 | `rin_house` | Rin's house on the waterfront (ông Tư's) |
| 18 | `wooden_bed` | Bed in Rin's room |

9. **offering_tray_normal**
```text
<shared style> Concept for image-to-3D, single object, three-quarter view, plain light-grey
background: a low red-lacquered wooden tray on a small folding table, a Vietnamese ghost-month
street offering: a plate of fruit (bananas, oranges), three small bowls of plain white rice porridge,
two tiny cups of salt and raw rice, a few wrapped sweets, a bowl of sand with three burning incense
sticks, two short red candles lit. Neat and respectful.
```
10. **offering_tray_eaten**
```text
<shared style> Concept for image-to-3D, single object, same tray and table as a ghost-month street
offering but ravaged: fruit gone except chewed peels, porridge bowls tipped over and empty, salt and
rice spilled across the tray, sweet wrappers torn open, incense sticks snapped, candles out with
dripping wax. Wet dark smudges like hand marks on the tray edge.
```
11. **joss_paper_bucket**
```text
<shared style> Concept for image-to-3D, single object: a dented rusty metal bucket on the ground with
burning Vietnamese votive paper (vàng mã: gold and red paper sheets) inside, low flames and grey ash
curling over the rim.
```
12. **hoa_dang_lantern**
```text
<shared style> Concept for image-to-3D, single object: a small floating paper lantern shaped like a
lotus, pink and white folded petals around a short candle in the centre, on a thin flat base, as used
for river and sea lantern releases. Clean simple shape.
```
13. **pier_lamp_post**
```text
<shared style> Concept for image-to-3D, single object: a weathered wooden post about 1.5 m tall, the
kind fixed at the end of a small fishing pier, with an old glass-and-tin kerosene lantern hanging
from an iron hook near the top, a coil of rope tied around the base.
```
14. **drowned_figure**
```text
<shared style> Concept for image-to-3D, full body, standing straight with arms hanging, front
three-quarter view, plain light-grey background: a thin human figure who drowned long ago, soaked dark
fisherman clothes clinging to the body, long wet black hair hanging over the face so no face is
visible, pale bluish grey skin on the hands and feet, water dripping. Unsettling but not gory.
```
15. **drowned_hand**
```text
<shared style> Concept for image-to-3D, single object: a pale, swollen human hand and forearm reaching
upwards out of water, fingers slightly curled as if grabbing a boat rim, bluish grey skin, wrinkled
fingertips, torn wet sleeve at the forearm. Not gory.
```
16. **bottle_letter**
```text
<shared style> Concept for image-to-3D, single object: an old greenish glass bottle with a cork, a
rolled yellowed paper letter tied with string visible inside, a little barnacle growth on one side.
```
17. **rin_house**
```text
<shared style> Concept for image-to-3D, single building, three-quarter view: a small one-storey house
in a poor Vietnamese fishing village, lime-washed yellow walls faded and stained, a rusty corrugated
tin roof with a short overhang, one green wooden door at the left, one window with wooden shutters,
a narrow porch step, a clay water jar by the door. About 7 m wide, 5 m deep.
```
18. **wooden_bed**
```text
<shared style> Concept for image-to-3D, single object: a simple low wooden bed frame of a poor
Vietnamese home, a woven straw sleeping mat (chiếu) on top, a thin folded blanket and a flat pillow,
a mosquito net tied up in a bundle at one corner post.
```

## Priority 3: reading close-ups and the wrong night

| # | Name | Use | Size / background | Save to |
|---|---|---|---|---|
| 19 | `paper_letter_old` | Bottle letter shown when picked up | 1024×1024, transparent | `assets/textures/horror/` |
| 20 | `paper_diary_page` | Lighthouse keeper's diary page | 1024×1400, transparent | `assets/textures/horror/` |
| 21 | `notebook_page` | Rin's notebook (sổ tay) of clues | 1024×1400, opaque | `assets/textures/horror/` |
| 22 | `sky_dark_night` | Đêm âm sky (wrong night at sea) | 4096×2048 equirectangular | `assets/textures/sea3d/` |

19. **paper_letter_old**
```text
<shared style> A single sheet of old cheap paper, rolled for a long time and flattened again, salt
water stains, torn edge, faint ruled lines, EMPTY (no writing), soft shadow-free scan. Transparent
background around the paper.
```
20. **paper_diary_page**
```text
<shared style> A single page torn from a small notebook, faint blue ruled lines, coffee-coloured
water stains, one corner burnt or torn, EMPTY (no writing), flat scan. Transparent background around
the page.
```
21. **notebook_page**
```text
<shared style> A two-page spread of a cheap student notebook lying open, flat, top-down: squared or
ruled light-blue lines, a red margin line, worn paper edges, a pencil lying in the fold. Both pages
EMPTY. Opaque.
```
22. **sky_dark_night**
```text
<shared style> Seamless 360-degree equirectangular night sky panorama, exactly 2:1, horizon at the
vertical centre: a large blood-red full moon low over the horizon at about 12 degrees elevation,
sickly green-grey fog clouds drifting across the lower sky, almost no stars, everything dim and wet.
No land, no sea. The top and bottom 3% a uniform colour; left and right edges must match.
```

## Not needed now

Restaurant food models, guests, Bảo, Cô Năm, the boats and the sea props already exist
(`assets/models/ready/`). The existing night sky and island strip stay for calm nights.
