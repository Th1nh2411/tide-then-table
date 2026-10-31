# Hàng đợi gen 3D — prompt ảnh đầu vào

Mỗi asset: gen **một** ảnh bằng prompt bên dưới (copy nguyên khối), lưu PNG đúng tên vào đúng
thư mục con, rồi chạy batch qua đêm. Prompt viết tiếng Anh cho model ảnh; giọng giống các
prompt đã dùng cho Rin / ghế / bàn / thuyền thúng (`assets/models/ready/*/prompt.txt`).

```
assets/concepts/3d_queue/
  characters/<id>.png   nhân vật, giảm còn 3000 tam giác
  props/<id>.png        đồ lớn, thuyền, công trình, giảm còn 1500
  small/<id>.png        đồ nhỏ, giảm còn 600
```

Chạy (mỗi asset ~3,5 phút, cả danh sách ~2,5 giờ):

```
powershell -File tools/art/hunyuan_local.ps1 -InputDir assets/concepts/3d_queue/characters -OutDir assets/models/batch/characters -Faces 3000
powershell -File tools/art/hunyuan_local.ps1 -InputDir assets/concepts/3d_queue/props -OutDir assets/models/batch/props -Faces 1500
powershell -File tools/art/hunyuan_local.ps1 -InputDir assets/concepts/3d_queue/small -OutDir assets/models/batch/small -Faces 600
```

## Kiểm ảnh trước khi bỏ vào hàng đợi

- Một vật / một người, một góc nhìn, nền trong suốt (hoặc xám nhạt trơn: tool tự xoá nền).
- Thấy rõ các khoảng trống (gầm bàn, giữa chân ghế, nách và giữa hai chân người): Hunyuan
  hay lấp kín khoảng trống bị che.
- Nhân vật đứng thẳng chính diện, tay dang khoảng 30° (A-pose) để gắn rig sau này.
- Không chữ, không logo, không tên địa danh thật.
- Màu không quan trọng với hình khối (tool chỉ lấy hình), nhưng giữ đúng màu giúp bước
  tô material phẳng sau đó.

## Đã có, không cần gen lại

Rin (`rin_pilot`), ghế đẩu xanh (ghế đỏ = đổi màu material), bàn inox, thuyền thúng.

## Không gen bằng Hunyuan

Ô gạch vỉa hè, lề, đường, mặt tiền nhà, mái hiên sọc, dây đèn, nước biển, sương, xoáy nước,
UI, chân dung: dựng bằng mesh/shader trong Godot hoặc giữ 2D. Món ăn và hải sản để đợt sau.

---

## characters/ (3000 tam giác)

Khối chung đã nằm sẵn trong từng prompt: một người, chính diện, A-pose, low-poly mảng lớn
giống Rin, nền trơn.

### bao — Bảo (đầu bếp)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: Bao, a Vietnamese man in his early 20s, a bit chubby with a soft rounded belly, round cheerful face, short black hair with a blunt straight fringe, no hat, orange short-sleeve t-shirt, cream knee-length cook's apron tied at the waist, dark gray trousers, simple black sandals. Height about 1.72 metres. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi, not muscular), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns, no fabric detail. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### vy — Vy (bản đầu arc: tiểu thư)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: Vy, a young Vietnamese woman in her early 20s, long glossy dark hair with soft waves falling BEHIND the shoulders (hair must not cover the arms), a small pastel hair clip, fair skin, light makeup, chin slightly raised, a little haughty expression, pastel pink fitted short-sleeve blouse, cream mini skirt, spotless white sneakers, a tiny crossbody bag with a thin strap across the chest and the bag resting at the hip. Height about 1.60 metres, slim. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### vy_sau — Vy (bản sau khi mở lòng, tuỳ chọn)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: Vy, a young Vietnamese woman in her early 20s, dark hair tied up in a neat high ponytail with a plain hair tie, fair skin, warm relaxed smile, pastel pink short-sleeve blouse with the sleeves rolled up, a cream work apron tied tightly at the waist with one small stain, cream skirt to the knee, simple Vietnamese plastic honeycomb sandals. Height about 1.60 metres, slim. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### co_nam — Cô Năm (tạp hoá)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: Co Nam, a friendly Vietnamese woman about 40 years old with a youthful modern look, simple dark hair tied back in a low bun with a few silver strands, warm smile, green short-sleeve blouse, loose dark brown trousers, plain plastic sandals. Height about 1.58 metres, average build. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### ong_tam — ông Tám (ông chài già)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: Ong Tam, an old Vietnamese fisherman about 70, thin and wiry, deeply sun-tanned, short silver-white hair, kind weathered face, faded brown long-sleeve shirt with the sleeves rolled to the elbows, loose dark gray trousers rolled up to mid-shin, simple worn sandals. Height about 1.62 metres, shoulders slightly rounded with age but standing upright. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### guest_1 — khách nam (áo đổi màu bằng material)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: an ordinary Vietnamese man in his 30s, a restaurant customer, short black hair, plain short-sleeve polo shirt in one flat light-blue colour, beige trousers, simple sneakers. Height about 1.70 metres, average build. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### guest_2 — khách nữ

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: an ordinary young Vietnamese woman in her 20s, a restaurant customer, shoulder-length straight black hair tucked behind the ears, plain short-sleeve t-shirt in one flat white colour, straight blue jeans, simple sneakers. Height about 1.58 metres, slim. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### guest_3 — khách trung niên

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: an ordinary middle-aged Vietnamese man in his late 40s, a restaurant customer, slightly heavy with a small belly, short black hair receding a little, plain short-sleeve button shirt in one flat gray colour untucked, dark trousers, plastic sandals. Height about 1.68 metres. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### guest_rich — khách sang

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: a wealthy Vietnamese businessman in his 40s, neat side-parted black hair, confident face, mustard-yellow long-sleeve dress shirt tucked in, red necktie, dark trousers with a belt, black leather shoes, a simple wristwatch. Height about 1.72 metres, average build. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### guest_regular — khách quen

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: a friendly Vietnamese regular customer in his 50s, short salt-and-pepper hair, easy smile, moss-green short-sleeve shirt, khaki trousers, plain sandals. Height about 1.68 metres, average build. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

### staff — nhân viên thuê (dùng chung, đổi màu)

```
Use case: image-to-3D input for a 3D game character. ONE full-body character, FRONT VIEW ONLY, relaxed A-pose: arms held about 30 degrees away from the body with clear empty gaps at the armpits and between arms and torso, palms facing the thighs, legs straight and slightly apart with a visible gap between them, feet flat. Character: a young Vietnamese restaurant helper around 20, short black hair, plain white short-sleeve t-shirt, dark green waist apron tied at the front, black trousers, simple sneakers. Height about 1.68 metres, slim. Style: polished low-poly stylized game character with broad angular planar facets, natural human proportions about 7 heads tall (not chibi), very sparse facial features, hair as a few large polygon masses with no strands, flat solid-colour materials with soft simple shading, no textures, no patterns. Camera at chest height, no perspective distortion, the whole body in frame with generous margin. Transparent background (or flat plain light gray), no floor, no cast shadow, nothing in the hands, no other people, no text, no logo, no watermark. One single view, not a turnaround sheet.
```

---

## props/ (1500 tam giác)

### cat — mèo Mỡ

```
Use case: image-to-3D input for a 3D game. ONE chubby orange cat sitting upright, front three-quarter view, tail curled around the front paws, round body, small ears, calm half-closed eyes, flat orange fur with a cream belly and paws, no stripes. Body length about 0.45 metres, sitting height about 0.30 metres. Style: faceted low-poly game model with broad planar shapes, flat solid colours, no fur strands, no texture. Camera slightly above the cat, no perspective distortion, whole cat in frame with generous margin. Transparent background, no floor, no shadow, no other objects, no text. One view only.
```

### food_cart_0 — xe đẩy cấp 1 (bếp than)

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE Vietnamese stainless-steel street food cart: a rectangular steel counter cabinet 1.60 metres long, 0.70 metres deep, 0.90 metres high, with a small glass display case on the left half of the countertop, a small round clay charcoal stove on the right half, closed steel doors on the front, four small caster wheels. Old but clean, matte brushed steel, no shiny reflections. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no fine texture, no text, no logo. Composition: whole cart in a single three-quarter front view, camera about 25 degrees above the counter, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no food, no people, no other objects. One view only.
```

### food_cart_1 — xe đẩy cấp 2 (bếp gas)

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE Vietnamese stainless-steel street food cart: a rectangular steel counter cabinet 1.60 metres long, 0.70 metres deep, 0.90 metres high, with a glass display case on the left half of the countertop, one cast-iron gas burner on the right half, a blue gas cylinder standing in an open shelf under the counter, four small caster wheels. Matte brushed steel, no shiny reflections. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no fine texture, no text, no logo. Composition: whole cart in a single three-quarter front view, camera about 25 degrees above the counter, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no food, no people, no other objects. One view only.
```

### food_cart_2 — xe đẩy cấp 3 (bếp gas đôi)

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE larger Vietnamese stainless-steel street food cart: a rectangular steel counter cabinet 1.90 metres long, 0.75 metres deep, 0.90 metres high, with a wide glass display case on the left of the countertop, two cast-iron gas burners side by side on the right, a small steel splash guard behind the burners, a blue gas cylinder in an open shelf under the counter, four small caster wheels. Matte brushed steel, no shiny reflections. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no fine texture, no text, no logo. Composition: whole cart in a single three-quarter front view, camera about 25 degrees above the counter, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no food, no people, no other objects. One view only.
```

### charcoal_grill — lò than nướng của Rin

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE low rectangular steel charcoal grill: an open trough 0.80 metres long, 0.40 metres wide, standing on four short legs, total height 0.70 metres, a wire grilling grate across the top, a bed of glowing charcoal visible under the grate shown as flat orange-red chunks. Dark sooty steel. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no fine texture, no smoke, no text. Composition: whole grill in a single three-quarter front view, camera about 30 degrees above, no perspective distortion, generous margin, the open space between the legs clearly visible. Transparent background, no floor, no cast shadow, no food, no people, no other objects. One view only.
```

### beer_keg — bình bia + vòi

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE draft beer keg with tap: a squat steel keg about 0.40 metres in diameter and 0.55 metres tall standing on a small square base, with a short chrome tap tower and lever on top, total height 0.85 metres. Matte steel, no reflections. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no fine texture, no text, no brand, no logo. Composition: whole object in a single three-quarter front view, camera about 20 degrees above, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no glasses, no people, no other objects. One view only.
```

### plate_bench — bàn kê món

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE long plain wooden serving bench-table: tabletop 2.00 metres long, 0.50 metres deep, 0.75 metres high, made of a few broad planks, four square legs with one low stretcher bar along the length. Warm weathered brown wood. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no wood grain texture, no text. Composition: whole object in a single three-quarter front view, camera about 25 degrees above, no perspective distortion, generous margin, empty space under the tabletop clearly visible. Transparent background, no floor, no cast shadow, no plates, no food, no people, no other objects. One view only.
```

### fridge_0 — thùng xốp (cấp 1)

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE white styrofoam cooler box with its lid closed, rectangular, 0.60 metres long, 0.40 metres wide, 0.40 metres high, slightly rounded edges, a little worn. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text, no logo. Composition: whole box in a single three-quarter front view, camera about 25 degrees above, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no other objects. One view only.
```

### fridge_1 — thùng đá nhựa xanh (cấp 2)

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE blue plastic ice cooler chest with a white hinged lid closed and two side handles, 0.80 metres long, 0.45 metres wide, 0.50 metres high. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text, no brand, no logo. Composition: whole chest in a single three-quarter front view, camera about 25 degrees above, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no other objects. One view only.
```

### fridge_2 — tủ đông nắp kính (cấp 3)

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE white chest freezer with a sliding glass top lid, 1.20 metres long, 0.60 metres deep, 0.85 metres high, small base feet. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, the glass lid shown as a flat pale blue-gray panel, no texture, no text, no brand, no logo. Composition: whole freezer in a single three-quarter front view, camera about 25 degrees above, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no other objects. One view only.
```

### menu_board — bảng LED menu

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE small standing LED menu sign: a flat rectangular black panel 0.90 metres wide and 0.60 metres tall with a thin dark metal frame, mounted on two thin metal legs with small feet, total height 1.40 metres. The screen face is blank and dark (the game draws the text). Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, NO text, no letters, no logo. Composition: whole sign in a single three-quarter front view, camera at about 15 degrees above the middle of the panel, no perspective distortion, generous margin, open space between the legs visible. Transparent background, no floor, no cast shadow, no other objects. One view only.
```

### grocery_counter — quầy tạp hoá Cô Năm

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE small grocery stall counter: a low wooden counter 2.40 metres long, 0.60 metres deep, 0.90 metres high, with a slanted display top holding four simple open produce crates (bundles of water spinach, a pile of tomatoes, onions, chili) shown as broad simple shapes, a small cash box on one end. Warm wood and muted produce colours. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text, no signboard, no logo. Composition: whole counter in a single three-quarter front view, camera about 25 degrees above, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no people, no other objects. One view only.
```

### motorbike — xe máy đỗ (đổi màu bằng material)

```
Use case: image-to-3D input prop for a 3D Vietnamese street game. ONE ordinary Vietnamese step-through motorbike (scooter) parked on its side stand, no rider, about 1.85 metres long and 1.10 metres tall, body panels in one flat solid red colour, black seat, black tyres, simple round headlight, two small mirrors. Generic design, no brand. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text, no logo, no number plate text. Composition: whole motorbike in a single three-quarter front-side view, camera about 20 degrees above, no perspective distortion, generous margin. Transparent background, no floor, no cast shadow, no people, no helmet, no other objects. One view only.
```

### sidewalk_tree — cây xanh vỉa hè

```
Use case: image-to-3D input prop for a 3D Vietnamese street game. ONE small street tree growing out of a square concrete planter box: planter 0.80 metres wide and 0.40 metres high, a straight trunk, crown made of 4-6 large rounded low-poly leaf masses, total height about 3.0 metres. Muted green leaves, gray-brown trunk, light gray concrete. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no individual leaves, no texture, no text. Composition: whole tree in a single front three-quarter view, camera about 15 degrees above the planter, no perspective distortion, generous margin. Transparent background, no ground, no cast shadow, no other objects. One view only.
```

### ghe_cheo — ghe chèo

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game. ONE small wooden Vietnamese rowing boat, viewed from a slightly elevated three-quarter angle (about 35 degrees above the gunwale) so the OPEN HOLLOW interior, two plain thwart benches and the inner floor are clearly visible. Length 3.6 metres, beam 1.2 metres, depth 0.5 metres, pointed raised bow, flat narrow stern, weathered blue-green painted hull with a thin red stripe below the rim, brown wooden interior, a simple painted eye on each side of the bow. Style: faceted low-poly game art, broad planar facets, flat solid colours, a few broad plank bands, no fine wood grain. Entire boat centred with generous margin, no perspective distortion. Transparent background, no water, no oars, no people, no rope, no lantern, no text. One view only; the interior must look like an empty boat, never a solid hull.
```

### ghe_may — ghe máy

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game. ONE wooden Vietnamese motor fishing boat, viewed from a slightly elevated three-quarter angle (about 35 degrees above the deck): length 6.0 metres, beam 1.8 metres, raised pointed bow, a small open-front wooden wheelhouse with a flat roof toward the stern, a low engine box behind it, an open working deck in front with low side rails. Weathered blue hull with a red band near the waterline, cream wheelhouse, brown deck, a simple painted eye on each side of the bow. Style: faceted low-poly game art, broad planar facets, flat solid colours, no fine detail. Entire boat centred with generous margin, no perspective distortion. Transparent background, no water, no wake, no people, no nets, no flags, no text, no number. One view only.
```

### lighthouse — hải đăng Đá Canh Đêm

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game (invented location). ONE small coastal lighthouse standing on a chunky rock base: rock base about 5 metres wide and 1.5 metres high, a slightly tapered round white tower with two broad red bands, a small iron balcony and a glass lantern room on top, total height about 9 metres, small wooden door at the bottom. Style: faceted low-poly game art, broad planar facets, flat solid colours, no texture, no text. Camera about 15 degrees above the base, three-quarter view, no perspective distortion, whole structure in frame with generous margin. Transparent background, no sea, no sky, no light beam, no people, no other buildings. One view only.
```

### whale_shrine — Miếu Cá Ông

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game (invented location). ONE small Vietnamese seaside whale shrine: a 3 x 3 metre single-room shrine on a low stone platform with three steps, red wooden pillars, an open front, a curved terracotta tile roof with gently upturned corners, a simple altar table inside, total height about 3.5 metres. Weathered warm colours. Style: faceted low-poly game art, broad planar facets, flat solid colours, no texture, no writing, no characters, no text. Camera about 15 degrees above the platform, three-quarter front view, no perspective distortion, whole building in frame with generous margin. Transparent background, no ground, no sea, no people, no incense smoke. One view only.
```

### old_man_hut — chòi ông Tám (Gò Vỏ Ốc)

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game (invented location). ONE small fisherman's hut on wooden stilts: a 3 x 3 metre bamboo-walled hut with a steep thatched palm-leaf roof, raised about 1 metre on six wooden stilts, a short wooden ladder to the open doorway, a narrow front porch, total height about 4 metres. Warm bamboo and dry thatch colours. Style: faceted low-poly game art, broad planar facets, flat solid colours, no individual leaves or strands, no texture, no text. Camera about 15 degrees above the stilts, three-quarter front view, no perspective distortion, whole hut in frame with generous margin, open space under the floor visible. Transparent background, no ground, no sea, no people. One view only.
```

### lobster_raft — bè tôm hùm

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game. ONE small floating fish-farm raft: a square grid of wooden walkway planks about 6 x 6 metres resting on rows of blue plastic barrel floats, four square open cage holes in the walkway, a tiny tin-roofed hut on one corner, and one thin wooden lamp pole with a small lamp, total height about 3.5 metres. Style: faceted low-poly game art, broad planar facets, flat solid colours, no nets detail, no texture, no text. Camera about 35 degrees above, three-quarter view, no perspective distortion, whole raft in frame with generous margin. Transparent background, no water, no people, no animals. One view only.
```

### dock — đoạn cầu tàu

```
Use case: image-to-3D input for a 3D Vietnamese coastal fishing game. ONE straight section of a simple wooden pier: plank deck 6 metres long and 2 metres wide on thick round wooden posts, deck 1.2 metres above the post bottoms, low side rail on one side, one wooden lamp post with a small lantern at the far end. Weathered gray-brown wood. Style: faceted low-poly game art, broad planar facets, flat solid colours, no wood grain, no texture, no text. Camera about 25 degrees above, three-quarter view, no perspective distortion, whole section in frame with generous margin, open space under the deck visible. Transparent background, no water, no boats, no people. One view only.
```

### rock_1 — đá ngầm (to)

```
Use case: image-to-3D input for a 3D coastal fishing game. ONE large angular sea rock, about 2.5 metres wide and 1.2 metres tall, a few big broken planar faces, slightly flat top, dark blue-gray stone with a lighter top. Style: faceted low-poly game art, broad planar facets, flat solid colours, no texture, no moss detail. Camera about 25 degrees above, three-quarter view, whole rock in frame with generous margin. Transparent background, no water, no other rocks. One view only.
```

### rock_2 — đá ngầm (cụm nhỏ)

```
Use case: image-to-3D input for a 3D coastal fishing game. ONE cluster of three jagged sea rocks fused at the base, overall about 1.8 metres wide and 1.5 metres tall, tallest rock pointed, big broken planar faces, dark blue-gray stone. Style: faceted low-poly game art, broad planar facets, flat solid colours, no texture. Camera about 25 degrees above, three-quarter view, whole cluster in frame with generous margin. Transparent background, no water, no other objects. One view only.
```

### dolphin — cá heo (sự kiện đêm)

```
Use case: image-to-3D input for a 3D coastal fishing game. ONE dolphin in a gentle arched leap pose, side three-quarter view, body length about 2.2 metres, smooth gray-blue back and pale belly, clear dorsal fin, flippers and tail flukes. Style: faceted low-poly game art, broad planar facets, flat solid colours, no texture. Camera level with the body, no perspective distortion, whole dolphin in frame with generous margin. Transparent background, no water, no splash, no other animals. One view only.
```

---

## small/ (600 tam giác)

### bin — thùng rác

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE round blue plastic bucket-style trash bin with a fitted lid and two small side handles, 0.40 metres in diameter, 0.45 metres tall. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text, no logo. Composition: whole bin in a single three-quarter front view, camera about 25 degrees above, generous margin. Transparent background, no floor, no shadow, no other objects. One view only.
```

### plant_pot — chậu cây

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE terracotta flower pot with a small leafy green plant, pot 0.35 metres wide and 0.30 metres tall, plant crown made of 3-5 large rounded leaf masses, total height 0.60 metres. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no individual leaves, no texture, no text. Composition: whole pot in a single three-quarter front view, camera about 20 degrees above, generous margin. Transparent background, no floor, no shadow, no other objects. One view only.
```

### beer_tower — tháp bia 3 lít

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE 3-litre beer tower: a tall clear plastic cylinder about 0.15 metres wide and 0.70 metres tall on a round black base, a thin central ice tube, a small black tap near the bottom, filled with amber beer and a white foam head at the top, black lid. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, the plastic shown as opaque pale amber, no reflections, no texture, no text, no brand. Composition: whole tower in a single three-quarter front view, camera about 15 degrees above, generous margin. Transparent background, no floor, no shadow, no glasses, no other objects. One view only.
```

### grocery_crate — két rau Cô Năm

```
Use case: image-to-3D input prop for a 3D Vietnamese seafood sidewalk restaurant game. ONE open green plastic produce crate, 0.50 metres long, 0.35 metres wide, 0.30 metres tall, filled with bundles of water spinach and a few tomatoes shown as broad simple shapes. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text, no logo. Composition: whole crate in a single three-quarter front view, camera about 30 degrees above, generous margin. Transparent background, no floor, no shadow, no other objects. One view only.
```

### plastic_bag — túi nilon đồ chợ

```
Use case: image-to-3D input prop for a 3D Vietnamese street game. ONE tied pink plastic grocery bag with two loop handles on top, bulging with groceries inside, about 0.30 metres tall. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no wrinkles detail, no texture, no text, no print. Composition: whole bag in a single three-quarter front view, camera about 15 degrees above, generous margin. Transparent background, no floor, no shadow, no other objects. One view only.
```

### crate — thùng gỗ đựng cá (cutscene)

```
Use case: image-to-3D input prop for a 3D Vietnamese coastal fishing game. ONE open wooden fish crate made of a few broad slats with gaps, 0.60 metres long, 0.40 metres wide, 0.30 metres tall, empty. Weathered light brown wood. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no wood grain, no texture, no text. Composition: whole crate in a single three-quarter front view, camera about 30 degrees above, generous margin. Transparent background, no floor, no shadow, no fish, no other objects. One view only.
```

### non_la — nón lá (ĐÃ BỎ: không vẽ / không dùng; nhân vật không đội nón lá)

```
Use case: image-to-3D input prop for a 3D Vietnamese coastal fishing game. ONE Vietnamese conical palm-leaf hat (non la), 0.42 metres in diameter and 0.18 metres tall, pale straw colour with a few faint concentric rings, a thin chin strap hanging below. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text. Composition: the hat alone seen from a three-quarter side view, camera about 20 degrees above the brim, generous margin. Transparent background, no head, no person, no shadow, no other objects. One view only.
```

### net_buoy — phao lưới có đèn

```
Use case: image-to-3D input prop for a 3D coastal fishing game. ONE fishing net float buoy: a round orange foam float about 0.35 metres in diameter with a short thin pole on top carrying a tiny lamp, total height 0.70 metres, a short rope end hanging below. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no texture, no text. Composition: whole buoy in a single three-quarter front view, camera about 15 degrees above, generous margin. Transparent background, no water, no shadow, no other objects. One view only.
```

### bottle — chai thư

```
Use case: image-to-3D input prop for a 3D coastal fishing game. ONE old glass message bottle lying on its side, about 0.30 metres long, pale green glass shown as an opaque flat colour, a cork in the neck, a rolled paper note visible inside as a simple cream shape. Style: faceted low-poly game prop, broad planar shapes, flat solid colours, no reflections, no texture, no text. Composition: whole bottle in a single three-quarter view, camera about 20 degrees above, generous margin. Transparent background, no sand, no water, no shadow, no other objects. One view only.
```

### jellyfish — sứa (sự kiện đêm, phát sáng bằng material)

```
Use case: image-to-3D input for a 3D coastal fishing game. ONE jellyfish: a dome-shaped bell about 0.40 metres wide with 6-8 thick ribbon tentacles hanging below in a loose bundle, total length 0.80 metres, pale cyan colour shown as an opaque flat colour. Style: faceted low-poly game art, broad planar facets, flat solid colours, no transparency, no glow effect, no texture. Camera level with the bell, three-quarter view, generous margin. Transparent background, no water, no other animals. One view only.
```
