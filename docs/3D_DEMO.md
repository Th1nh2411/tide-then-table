# Xóm Đèn — vòng chơi 3D

Cập nhật 2026-10-28 trên nhánh `try-3d`. Ưu tiên của đợt này là chơi liên tục
**câu cá → về quán → phục vụ → nâng cấp → ra khơi**, dùng dữ liệu thật của game.

## Chạy

Bấm **F5** trong Godot. Menu ghi **XÓM ĐÈN • BẢN 3D**. Chơi mới qua intro rồi
vào biển 3D; Tiếp tục dùng điểm resume trong save hiện tại.

- Biển: `scenes/sea3d/sea_scene_3d.tscn`.
- Quán: `scenes/restaurant3d/restaurant_scene_3d.tscn`.
- Hướng dẫn trong game: Esc → Hướng dẫn → **Bản 3D**.

## Một vòng chơi

1. **Ra biển:** W/S tiến-lùi, A/D bẻ lái. Không có phao hay mũi tên chỉ đàn cá:
   chỉ có **bọt khí** nổi trên mặt biển (`BubbleSpot3D`), thấy được trong tầm đèn
   (tầm này co lại khi dầu cạn), nhiều cá thì nhiều bọt. Giảm tốc rồi E:
   cảnh quăng cần (`CastCinematic3D`, ~1,5 s, khóa input, phím bất kỳ để tua nhanh)
   rồi camera cúi xuống mặt nước, ripple-wipe sang minigame 2D; xong thì wipe ngược.
   Số cá trong minigame = số cá còn lại của đàn (tối đa 6); mỗi lượt đàn mất 1 con,
   hết cá thì bọt tan. Cần câu và đèn nâng cấp có ảnh hưởng tới độ khó/thời lượng.
2. **Câu:** dùng minigame 2D trong viewport; có thể Tab mở khoang, trận câu
   dừng trong khi sắp xếp. Nhả phím sau kết quả để thuyền chạy tiếp. Choáng
   giữ giữa các lượt; bất tỉnh được cứu về bến. Q thả lưới, E gần lưới để kéo.
3. **Về bến:** theo mũi tên Bến, E dỡ cá vào kho bờ, R kết thúc chuyến. F sửa
   thuyền ở bến. J mở điện thoại, M bản đồ; ghim bản đồ có chỉ dẫn ngoài biển.
4. **Nghỉ:** xem mẻ cá, thời tiết và món mới, rồi tới quán.
5. **Trước ca:** Rin đi lại tự do (WASD, Shift lướt). E ở bảng THỰC ĐƠN (hoặc nút
   Thực đơn) mở bảng lên món (`MenuPanel3D`: ô món có ảnh/giá/HOT/số phần, chọn món bằng số 1-9, Q tự xếp, Esc đóng; chỉ hiện món đã biết cá và bếp nấu được; nút Mua ở Cô Năm, Sửa quán, Mở cửa, Ra khơi khi hết hàng), không khóa Rin; E ở Cô Năm mua rau/bia, E ở tủ
   lạnh cất đồ. Nút Sửa quán luôn có khi chưa phục vụ.
6. **Phục vụ:** HUD (`RestaurantHud3D`) hiện ngày, giờ, tiền, bộ đếm ca và phiếu
   gọi món. Bảo tự nấu món thường; E tại bàn NHẬN MÓN để cầm đĩa, tới bàn có đơn
   rồi E. E tại NƯỚNG hoặc RÓT BIA làm món thủ công. E cạnh bàn bẩn để dọn.
7. **Hết ca:** nút Đóng sớm (bấm hai lần) hoặc T ngừng nhận khách mới, phục vụ
   nốt khách. Tổng kết hiện một lần (nút Đóng); sau đó Rin vẫn đi lại, dùng nút
   Sửa quán và Ra khơi ghim trên màn hình. Đồ nghề biển và nhân viên trong J.

## Kiểm tra đã có

- `tools/run_tests.sh`: logic 2D hiện có, các regression 3D và smoke scene.
- `tools/run_bot.sh`: bot native 3D chạy nhiều ngày tới ending, mua nâng cấp và
  kiểm lưu/tải ở save tạm. `POLICY=balanced tools/run_bot.sh` đổi ưu tiên nâng cấp.
- `scenes/test/game3d_loop_test.tscn`: 18 kiểm tra một vòng liên cảnh thật, từ
  minigame tới ca bán, nâng cấp, ngày kế và save/load.
- `scenes/test/fishing3d_inventory_test.tscn`: pause lồng nhau khi mở kho giữa
  trận câu, giữ choáng và thứ tự phát tín hiệu bất tỉnh.
- `scenes/test/cast_cinematic_3d_test.tscn`: quăng cần khóa input, bàn giao cho
  minigame đúng số cá của đàn, chuyển cảnh ngược về biển.
- `scenes/test/sea3d_parity_test.tscn`: dầu/đèn/cần câu, lượt đàn cá, Dex,
  phần thưởng, overflow và tọa độ ghim.
- `scenes/restaurant3d/restaurant_flow_check.tscn`: nấu/nhận/phục vụ/ăn/trả
  tiền/dọn, Rin đi được trước/sau ca, nút Đóng sớm, pantry-only, chống thanh toán trùng và thuê Vy từ lựa chọn.

Các lệnh kiểm tra luôn chạy `-- --no-autosave`; save roundtrip dùng file tạm.
Bot dịch chuyển nhanh giữa địa điểm và tạo kết quả minigame thành công có chủ
đích để kiểm tra tích hợp. Kết quả bot không phải đánh giá độ khó cho người chơi.

## Phần chưa bằng bản 2D

- Biển 3D đã dùng đúng bố cục 2D (`SeaLayout3D`, 160x107 đơn vị, 12 px/đơn vị:
  vùng gần bờ/rạn/khơi/sương, bến, miếu, chòi, hải đăng, bè, xoáy, đá) và sinh
  đàn cá mỗi đêm bằng `SeaShoals3D` (số đàn theo vùng, độ sâu, cá nổi bật, bóng
  lớn, giới hạn `max_depth`). Bản đồ điện thoại và ghim dùng tọa độ 2D.
  12 đá ngầm như 2D (`SubmergedRock3D`): luôn có collider, đá + bọt chỉ hiện
  trong tầm đèn (co lại khi cạn dầu). Sương mở thì có mây trôi (`SeaFog3D`).
  Đầu đêm có các câu như 2D (cá hư, NEO chào, món hot, sương), câu được cá thu
  phát sáng thì NEO báo `[WARN]`; thoại xếp hàng, mỗi câu chờ câu trước. F2 mở sương.
- StoryBridge3D chạy cutscene .tres với dàn cảnh 3D (CutsceneStage3D: marker,
  actor đi bộ, camera, emote, mưa, slow, remove); actor rin/bao/vy/co_nam/guest/cat dựng bằng `PersonRig3D` (cùng rig với
  gameplay: đi bộ, cầm đĩa; emote hiện biểu tượng); nhân vật gameplay cùng loại bị
  ẩn trong cảnh và hiện lại khi hết (Rin cưỡi thuyền ở biển cũng thuộc `person_rin`,
  diễn viên đứng đúng độ cao sàn thuyền); `tint dawn` nhuộm thế giới 3D (không nhuộm UI);
  `rin_faint` là model Rin chạy clip `Faint`; marker trong CutsceneMarkers3D, kiểm bằng story3d_stage_test.
- Còn cần playtest bàn phím thực tế, cân chỉnh pacing và hoàn thiện art 3D.

Bộ sprite/portrait approved và scene tham khảo art gốc không bị thay trong đợt này.

## Art 3D hiện hành

Flow đã chốt: gen-image → Hunyuan → giảm mesh/material/rig → Godot.
Đã tích hợp Rin, bàn/ghế, thuyền thúng và đủ **45 model batch** (2026-10-29).
Model nguồn nằm ở `assets/models/batch/`; model thành phẩm ở
`assets/models/ready/<id>/<id>.glb`. Quán đổi cart/fridge theo nâng cấp; biển dùng
ghe, bến, công trình và sự kiện mới; nhân vật giữ API PersonRig gameplay/cutscene.
Chi tiết flow và cách rebuild: `docs/ART_PIPELINE.md`.

Rin dùng palette portrait approved: da `#d79c6b`, áo ngà `#eee5d5`, tóc `#151d28`,
kính `#090a14`, bạc `#cac0b7`. Không sửa sprite/portrait gốc.

Preview còn giữ (F6): `scenes/art_pilots/rin_pilot_preview.tscn` (Rin, phím
1/2/3/5) và `scenes/art_pilots/rin_pilot2_compare.tscn`. Các scene preview/review
cũ (`scenes/art_preview/`, preview batch/thuyền/đồ nội thất) đã xoá 2026-10-29;
xem asset trực tiếp trong game.

Nhân vật người có skin 20 xương và Idle/Walk/Carry; chưa có rig mặt/ngón
tay. Mèo giữ dáng ngồi từ inference, chỉ bob/sway, chưa có rig đi bốn chân.
Các model dùng palette phẳng, chưa có texture chi tiết; kính/mặt còn đơn giản,
fridge cấp 2 còn mặt trước kín từ geometry nguồn. Bản active trước sửa được
sao lưu recoverable trong `build/batch_integration/backups/`.


### Animation — cập nhật 2026-10-29

Đã bỏ Raised khỏi Rin và 11 nhân vật batch; emote cutscene chỉ hiện biểu tượng.
Giữ Idle, Walk, Carry. Ném cần đang dùng bone override trong CastCinematic3D,
chưa có clip riêng cho chờ cá/kéo cá. Ưu tiên tiếp: Cast, FishingIdle, Reel.

### Rin Walk — sửa từ Blender, 2026-10-29

Đã export đè `assets/models/ready/rin/rin_pilot.glb` từ bản Blender người dùng
đang chỉnh: giữ material/geometry, trả Skin.001 về #D79C6B; bỏ Raised khỏi export.
Walk mới có chân trụ giữ đế ngang, chân bước nhấc lên, hông chuyển nhẹ và tay vung
đối nhịp. Đỉnh ngoài mép dép trước đây bị gán Hips đã chuyển về Foot tương ứng.
Nguồn chỉnh tiếp: `build/rin_export/rin_walk_fixed.blend` (local); script chỉnh
Walk trong Blender: `tools/art/fix_rin_walk_blender.py`. Backup GLB nằm dưới
`build/batch_integration/backups/`. Không chạy lại builder shape khi muốn giữ
các chỉnh tay từ Blender; builder không chứa toàn bộ chỉnh sửa thủ công này.

Nguồn Rin mới nhất: `/Users/nguyenthinh/WorkSpace/blender/rin.blend` do người dùng
chỉnh màu; đã export mesh/material trực tiếp vào Rin pilot ngày 2026-10-29.
Snapshot nguồn local: `build/rin_source_update/rin_source.blend`. Không ép lại
palette khi export; giữ Walk đã sửa và loại Raised khỏi GLB runtime.

### Clip câu cá — 2026-10-29

Rin hiện có `Idle`, `Walk`, `Carry`, **`Cast`** (1,5 giây, không loop).
Đã thêm Cast vào `/Users/nguyenthinh/WorkSpace/blender/rin.blend` và GLB runtime;
source trước khi thêm được backup tại `build/rin_cast/source_before_cast.blend`.
Mở `scenes/art_pilots/rin_pilot_preview.tscn`, F6 và nhấn **5** để xem ném cần.
Trong game: tới đàn cá, tương tác để ném cần; camera cận Rin rồi theo phao vào
minigame. Cinematic sample clip bằng clock, cần bám cổ tay, giữ skip và return.
Nếu Blender đang mở bản cũ, mở lại rin.blend để thấy action `Rin_Cast` trong track
`Cast` (cất riêng mọi chỉnh sửa chưa lưu trước). Chưa có FishingIdle/Reel riêng.

### Walk — chỉnh chân ngày 2026-10-29

Đã thay Walk trong `rin.blend` và `assets/models/ready/rin/rin_pilot.glb`:
60% chu kỳ chân trụ, 40% chân bước; gót chạm trước, mũi đẩy sau, chân bước nhấc
khỏi sàn; chân trụ duỗi hơn, bề ngang bước hẹp hơn, tay vung theo chân đối bên.
Giữ material, hình học, Idle/Carry/Cast và trọng số dép. Nguồn trước/sau tại
`build/rin_walk_refine/source_before.blend` và `source_after.blend`; ảnh review
ngang/chính diện ở cùng thư mục. F6 preview, phím 2 xem Walk, ←/→ xoay.

### Rin hiện hành: base pilot2 — 2026-10-29

Theo lựa chọn mới, active `assets/models/ready/rin/rin_pilot.glb` dùng thân, mặt,
rig 62 xương và 24 animation gốc của `rin_pilot2.glb`; file nguồn 2 giữ nguyên.
Chỉ đổi màu áo/quần/da/dép theo Rin trước và ghép mesh tóc thật, vừa scalp.
Không thêm kính hoặc sửa mặt/thân; native Walk được đối chiếu 8 thời điểm với
bản 2 nguồn (sai số vị trí khớp dưới 0,003 m). Giữ alias Idle/Walk và thêm riêng
Carry/Cast tương thích game. Preview F6: 1 đứng, 2 Walk gốc, 3 bưng, 5 ném cần.

Nguồn chỉnh mới là `build/rin2_finish/rin_pilot2_finished.blend`; không dùng
`rin.blend` hoặc builder Walk cũ để export đè base mới. Donor màu/tóc và bản
active trước thay đã backup; xem `assets/models/ready/rin/provenance.json`.
Quy trình export Blender này đã được thay bằng cách patch GLB trực tiếp ở mục dưới.

### Giữ nguyên base 2, chỉ tóc/màu/kính

Bản hiện hành sửa trực tiếp GLB gốc bằng `tools/art/finish_rin2_exact.py`, không
export lại thân/mặt. Binary gốc, nodes, rig và 24 clip native giữ nguyên từng byte;
material gốc chỉ đổi Base Color, giữ metallic/roughness và các thuộc tính khác.
Chỉ bỏ primitive tóc cũ, ghép tóc Rin và thêm kính chữ nhật có gọng/cầu/càng kính.
Xem `scenes/art_pilots/rin_pilot2_compare.tscn` bằng F6 để đối chiếu bản gốc/bản
mới cùng ánh sáng/camera/animation (1 đứng, 2 đi, Space dừng, ←/→ xoay).
Tổng 5.349 tam giác, 6 mesh; nguyên bản `rin_pilot2.glb` giữ nguyên. Không dùng
builder export Blender cũ để ghi đè bản này.

### Tóc, tay bưng/ném cần, Walk chung — 2026-10-29

- Tóc Rin dựng lại theo portrait 2D (`portrait_hair()` trong
  `finish_rin2_exact.py`): đỉnh phồng, mái rủ chéo qua trán, mai che tai, gáy phủ.
  Tổng còn 5.338 tam giác.
- Carry / CarryWalk / Cast của Rin viết lại bằng `tools/art/make_rin_arm_clips.py`:
  thân/chân/ngón lấy từ Idle/Walk gốc của pilot2, chỉ Torso và chuỗi tay được key
  (bưng đĩa hai tay trước bụng; ném cần: cầm → vung ra sau qua vai → quất tới →
  theo đà → hạ). PersonRig dùng `CarryWalk` khi bưng mà đi (chân không trượt).
  Hướng cần (`hand_basis`) tính so với tư thế Idle vì rest node của pilot2 là T-pose.
- 11 nhân vật batch giữ mesh/rig 20 xương riêng; clip `Walk` được làm lại cho giống
  Walk của Rin bằng `tools/art/retarget_walk.py` (delta xoay theo từng xương so với
  Idle của Rin, giữ nhịp nhún hông).

### Mắt và màu nhân vật ngoài Rin — 2026-10-29

Đã sửa 11 người (`bao`, `vy`, `vy_sau`, `co_nam`, `ong_tam`, `guest_1`,
`guest_2`, `guest_3`, `guest_rich`, `guest_regular`, `staff`) và `cat`.
Rin và metadata Rin không bị sửa, đã đối chiếu SHA-256 trước/sau.

- Thay hai khối mắt đen nhô khỏi mặt bằng lòng mắt, iris, pupil, mí và chân mày
  nhỏ; đặt theo mặt từng model và skin 100% theo Head. Kính khách/staff theo concept.
- Bảo/Vy/Cô Năm/Ông Tám/khách quen lấy màu từ portrait approved; các khách khác
  theo concept. Mèo Mỡ giữ màu cam theo ART_PLAN và concept, sửa mắt/mảng kem.
- Sửa các mảng tóc bị gán nhầm màu da trên Vy, Vy sau và khách nữ. Giữ vị trí
  vertex, normals, trọng số thân, xương và các clip Idle/Walk/Carry.
- Không sửa PNG portrait/sprite hoặc output Hunyuan gốc.

Xem **`scenes/art_pilots/character_faces_review.tscn` → F6**:
1 mặt trước, 2 góc nghiêng, 3 toàn thân. Ảnh review ở
`build/character_face_refine/after_1.png`, `after_2.png`, `after_3.png`.
Backup trước sửa ở `build/character_face_refine/source_before/` và backup builder.

Palette/điểm đặt mắt: `PROFILES` và `EYE_ANCHORS` trong
`tools/art/refine_character_faces.py`. Chạy lại script không chồng thêm mắt;
builder nhân vật/mèo tự áp bước này sau khi dựng source. Thân mỗi người vẫn
3.000 tam giác; mặt thêm 88 tam giác, hoặc 124 khi có kính; mèo thêm 64.

Đã PASS kiểm 45 asset, GPU deformation/head attachment cho 11 người, flow quán
và cutscene; kiểm rerun không đổi GLB; dữ liệu binary thân/rig/clip giữ nguyên.
Mắt là mesh chi tiết tĩnh, chưa có clip chớp mắt hoặc điều khiển hướng nhìn.

### Walk: chỉ thu hẹp bề ngang — 2026-10-29

Theo điều chỉnh của người dùng, 11 người batch chỉ thu hẹp đường chân theo X
(khoảng cổ chân chuẩn 0,386 → 0,240 m). Giữ nguyên sải trước–sau, độ nhấc chân,
foot roll, nhịp bước và chuyển động hông từ bản gốc trước khi chỉnh Walk.
Không bóp ngang mesh; chỉ thêm translation X ở gối/cổ chân trong Walk. Các clip
khác đặt lại translation gốc để không giữ nhầm độ rộng Walk khi chuyển động tác.

Đã đối chiếu 65 thời điểm/nhân vật: Y/Z khớp bản gốc dưới 0,000001 m;
tất cả rotation gốc và duration được giữ nguyên. Màu, mắt, mesh và rest rig không
đổi. Rin/mèo giữ nguyên. F6 `character_faces_review.tscn`: 4 đi trước, 5 đi nghiêng.
Tool: `tools/art/narrow_character_walk.py`; kiểm: `tools/art/check_lateral_walk.py`.
Nguồn sải gốc được ghi ở `walk_refinement.source_snapshot` trong provenance;
backup tại `build/character_walk_narrow/`, log mới tại `build/character_walk_lateral/`.

### Mắt Bảo theo model Rin — 2026-10-29

Riêng Bảo chuyển sang mắt đen low-poly như Rin: lấy đúng primitive `Eye` và
material từ `assets/models/ready/rin/rin_pilot.glb`, thu theo tỷ lệ đầu Bảo và
giữ vị trí/góc mắt đang chỉnh. Không dùng lòng trắng/iris của mẫu trước; giữ
lông mày Bảo. FaceDetails còn 40 tam giác (16 mày + 24 mắt), tổng Bảo 3.040.
Tool: `tools/art/match_bao_eyes_to_rin.py`. Palette/body/rig/Walk/Carry không đổi;
Rin và toàn bộ model khác không đổi. Mở character_faces_review, F6, phím 1/2.
Backup/log: `build/bao_rin_eyes/`. Bộ refine mặt tự áp lại kiểu này riêng Bảo.


### Đồng bộ mắt/tóc theo Bảo và Vy tô tay — 2026-10-29

- Hai mẫu tóc người dùng xác nhận là Bảo và Vy. Giữ nguyên body, palette và
  toàn bộ phân mảng tóc/áo của hai GLB người dùng đã export.
- Sửa mắt Bảo bị chìm dưới da, đổi mắt Vy và chín người còn lại sang đúng
  primitive/material `Eye` của Rin. Căn độ nghiêng/độ sâu riêng từng mắt trên
  bề mặt da; khoảng hở nhỏ nhất 1,5 mm ở mẫu kiểm. Giữ XY, chân mày và kính.
- Chín người còn lại sửa những tam giác bị lẫn material tóc theo ranh giới hai
  mẫu. Không đổi vị trí vertex, normals, trọng số, xương, clip hoặc kiểu tóc riêng.
- Rin và mèo được đối chiếu hash, giữ nguyên. Các bản export có action copy
  `.001` của Vy được giữ lại; game tiếp tục chọn Idle/Walk/Carry chuẩn.

F6 `scenes/art_pilots/character_faces_review.tscn`: **1** trước, **2/6** hai góc
nghiêng, **3** toàn thân, **4/5** Walk. Ảnh mới:
`build/character_face_refine/style_follow_{1,2,3,6}.png`; Walk ở
`build/character_walk_narrow/style_follow_*.png`.

Tool mắt: `tools/art/match_character_eyes_to_rin.py` (wrapper Bảo cũ cũng gọi
bộ fit mới). Tool tóc: `tools/art/follow_manual_hair.py`, chạy trước bước mắt.
`refine_character_faces.py` nhận biết bản tô tay để chỉ sửa mắt, không dựng lại
phân mảng body. Với model có tag builder, bộ refine áp tóc rồi mắt sau khi dựng.

Backup: `build/character_style_follow/source_before/`; mỗi lần thay file còn có
backup trong `build/batch_integration/backups/`. PASS 45 asset (76.234 tam giác),
GPU skin/head attachment + Walk/Carry của 11 người, kiểm dữ liệu gốc/rig/clip và
bản tóc Bảo/Vy không đổi. Chạy lại bước mắt không đổi GLB hoặc chồng thêm mắt.
Bằng chứng kiểm tra: `build/character_style_follow/{assets_check.log,gpu_check.log,preservation.json}`.


### Thêm lại mắt Cô Năm sau export thủ công — 2026-10-29

Bản `co_nam.glb` mới của người dùng không còn `CharacterFaceDetails`. Đã thêm
lại riêng hai mắt đen từ primitive/material Rin, vị trí X ±0,052 m, Y 1,421 m,
đặt thấp hơn mái tóc mới. Phần trước mắt áp sát da; mặt bên/sau chìm vào đầu,
tránh hiệu ứng hai khối mắt nhô ra. Giữ nguyên body/tóc/màu/rig và tất cả clip
của bản export thủ công. Tổng Cô Năm: 3.024 tam giác (3.000 thân + 24 mắt).

Đã thêm mắt vào scene Blender đang mở, skin 100% Head. Bản editable có mắt:
`build/co_nam_eye_restore/co_nam_eyes.blend`; backup trước sửa:
`build/co_nam_eye_restore/live_before.blend` và `before_co_nam.glb`.
Không export lại cả scene Blender nên object Icosphere thử nghiệm không vào game.

PASS kiểm riêng geometry/weights/bảo toàn dữ liệu và GPU Walk/Carry/head attachment.
Kiểm 45 asset vẫn từ chối các action phụ có sẵn trong export Cô Năm (ví dụ
CarryWalk/Cast/CharacterArmature|...), vì quy tắc cũ chỉ cho Idle/Walk/Carry;
các action này được giữ nguyên theo bản người dùng. Ảnh game:
`build/character_face_refine/co_nam_restored_{1,2,3,6}.png`.


### Tỷ lệ người/ghế và ánh sáng quán — 2026-10-29

Theo điều chỉnh cuối của người dùng, chỉ đổi tương quan **người với ghế**;
giữ nguyên scale nhân vật, bàn và người/thuyền ngoài biển. Ghế nhựa trong quán
thu còn 85%: footprint khoảng 0,47 × 0,47, mặt ghế cao 0,44 thay vì 0,52.
Collider thu theo đúng mesh để không va vào mép ghế vô hình. GLB nguồn không sửa.

Quán dùng ánh sáng nền xanh xám nhẹ, ánh sáng chính ấm từ phố, sáu đèn rọi xuống
bàn/bếp/quầy và ánh sáng phụ phía khuất. Có vỏ đèn/panel phát sáng nhìn thấy được.
Giảm sáng chồng từ hệ omni cũ để giữ chi tiết mặt bàn và tạo vùng sáng/tối.
Forward+ thêm SSAO ở điểm tiếp xúc; Compatibility dùng bóng thật từ đèn, không
phụ thuộc SSAO. Đèn rọi được cân năng lượng riêng cho hai renderer.

Nhân vật (kể cả đổi variant), mèo, bàn/ghế và model prop được bật shadow casting
khi load. Ánh sáng chính phủ toàn quán; đèn bàn/bếp có shadow riêng. Ngoài biển
giữ bố cục và tỷ lệ hiện tại, tiếp tục bóng từ trăng/đèn thuyền và bật caster trên
model load mới. Bọt khí/vệt nước vẫn là hiệu ứng không đổ bóng.

Chỉnh ghế: `WorldPresentation3D.RESTAURANT_STOOL_SCALE` tại
`scenes/world3d/world_presentation_3d.gd`. Đèn/camera quán:
`RestaurantRoomBuilder3D._lighting()` / `_shop_light()`.

Bản kiểm hình ở `build/world_scale_lighting/`: `before_*` là Compatibility trước
sửa; `verified_*` là Forward+/Metal sau sửa (camera gameplay + cận bàn/thuyền).
`verified_restaurant_no_shadows.png` tắt riêng shadow để đối chiếu cùng ánh sáng.
Scene chụp: `scenes/art_pilots/world_scale_lighting_review.tscn`, chạy với
`--no-autosave --world-review-tag=verified`. Backup script trước sửa:
`build/world_scale_lighting/source_before/`.

Kiểm: `scenes/test/world_presentation_check.tscn` kiểm scale/collider ghế, các
caster, sáu đèn và tỷ lệ rider/hull/cinematic; `restaurant_flow_check.tscn`,
`traffic_check.tscn`, `sea_scene_3d_smoke.tscn` kiểm gameplay liên quan.

Kết quả: PASS cả bốn kiểm tra trên; render review trên Forward+/Metal và
Compatibility. Đối chiếu bật/tắt shadow map trên Metal thay đổi 45.553 pixel ở
vùng gameplay, xác nhận có bóng thật. Sàn nhận bóng, không tự cast để tránh
shadow acne giữa các viên gạch. Log: `build/world_scale_lighting/*.log`.


### Di chuyển bám đất — 2026-10-29

Rin, khách, nhân viên và diễn viên cutscene dùng nhịp chân theo **quãng đường
thực tế**, không dựa vào giữ phím hay đồng hồ chung. Đụng tường thì dừng chân;
trượt dọc vật cản chỉ phát bước theo phần đường thực sự đi được.

- Rin tăng/giảm tốc ngắn, xoay mềm theo hướng di chuyển; tốc độ thường 3,0,
  bưng món 2,3 đơn vị/giây. Khi đủ nhanh dùng Run native của pilot2. Dash giữ
  tốc độ burst 11 và kết thúc về tốc độ thường, không trôi thêm do dư vận tốc.
  Wave Power vẫn bù thời gian riêng cho Rin.
- Nhân viên/khách dùng đường A* đã rút các đoạn thừa theo tầm nhìn có kiểm tra
  clearance; tăng tốc, hãm lúc gần đích/góc và xoay mềm. Đường đi vẫn cache theo
  đích, không tìm lại A* mỗi frame khi đã đến nơi.
- `GroundGait3D` đo tốc độ chân trụ của clip rồi cache theo resource. Khi đi,
  clock animation tiến theo đoạn đường thực tế; khi đứng dùng thời gian bình
  thường. Callback manual tránh render FPS tự đẩy lệch nhịp với bước physics.
- `GroundFootPlant3D` giữ điểm tiếp đất trong world space, giải IK hai xương
  đùi/cẳng chân và giữ hướng cổ chân từ clip. Xử lý riêng Foot control ở Root
  của Rin/pilot2 và bàn chân thuộc cẳng chân của rig batch. Nhả khi nhấc chân,
  đổi trạng thái hoặc quá xa, tránh kéo giãn khi dash/teleport. Mặt đất hiện
  phẳng, lấy cao độ từ origin actor và độ cao chân trong Idle.
- Batch có `GroundCarryWalk` tạo **trong RAM**: chân từ Walk, tay từ Carry;
  sửa lỗi bưng món mà chân vẫn đứng. Đĩa theo vị trí hai cổ tay ở cả Rin và NPC.
- Bỏ rung Y theo bậc của khách đứng ở bàn. Cutscene di chuyển cũng dùng cùng
  nhịp chân theo đoạn đường thay vì Walk tốc độ cố định.

Không ghi đè GLB, tóc, màu, rig hay các clip nguồn. Backup script:
`build/ground_motion/source_before/`. Scale người/ghế/thuyền và ánh sáng giữ
như đợt trước.

Xem **`scenes/art_pilots/ground_motion_review.tscn` → F6**: Rin, Vy bưng đĩa,
nhân viên bưng đĩa, khách đi/dừng/quay lại trên sàn có lưới. Ảnh Metal tại
`build/ground_motion/review_*.png`. `character_faces_review` vẫn là scene xem mặt
và clip tại chỗ; dùng scene mới để đánh giá tiếp xúc chân với quãng đường đi.

Kiểm mới: `scenes/test/ground_motion_check.tscn`, gồm tất cả 12 model người
(Rin + 11 batch), Walk/CarryWalk, Run của Rin, pha bước ở 30/120 FPS, tránh vật
cản, dừng khi bị tường chặn và hết dash. Đo ở 2,2 đơn vị/giây trên đường thẳng:
độ trượt trung bình lúc chân trụ giảm khoảng 64–91%; ví dụ Rin Walk 0,999 →
0,361, Vy 1,324 → 0,206, staff bưng đĩa 2,2 → 0,223. Run Rin ở 3,0 giảm
0,663 → 0,229. Đây là phép đo trong đoạn tiếp đất, không phải bảo đảm triệt tiêu
mọi trượt ở mọi tình huống đổi hướng.

PASS flow quán, traffic/pathing, story bridge, staging/camera và cinematic ném
cần. Log tại `build/ground_motion/{check,flow,traffic,story,stage,cast,review}.log`.


### Camera gần hơn và bố cục chơi — 2026-10-30

Quán dùng `RestaurantCamera3D`: orthographic size **12** thay vì 14, giữ một
vùng chết nhỏ quanh Rin, bám mềm và giới hạn focus trong phạm vi quán. Camera
ngừng cập nhật khi camera cutscene đang hoạt động. Không đổi scale nhân vật,
bàn, ghế hoặc thuyền. Có thể chỉnh `VIEW_SIZE`, `OFFSET` và dead zone trong
`scenes/restaurant3d/restaurant_camera_3d.gd`.

Biển: offset theo thuyền **(0,6.2,8.4)** thay vì (0,7.3,10), FOV **56°** thay
vì 58°. Dùng cùng cấu hình lúc khởi tạo và khi lái; bám camera theo hàm mũ để
không phụ thuộc FPS. Giữ toàn bộ tọa độ POI, đá/collider, bản đồ và vùng câu.
Đã kiểm khung hình cho cả thúng và ghe máy, cùng chuyển tiếp cinematic câu.

Bố cục: bảng thực đơn ở (0.4,0,4.8) gần lối vào, bảng bếp ở (5.8,0,-1.7).
Collider và footprint A* cùng đọc vị trí mới. Bảo chuyển sang mép trái xe bếp,
Cô Năm sang mép trái quầy để nhìn rõ người; không đổi vùng tương tác bếp/quầy.
Hải đăng trang trí và biển tên ở bến dời lệch sang bên để nhường trục nhìn thuyền.
Phần đèn của agent khác được giữ nguyên.

Hoàn tất kiểm phần khách ngồi: SitDown → SitIdle → StandUp tại đúng ghế;
đổi walker sang guest ngồi trong cùng frame để không nháy mất model. Hủy lượt
trong lúc ngồi xuống vẫn đứng/rời đi và trả chỗ đậu xe. Clip tạo runtime, GLB
nguồn giữ nguyên. `restaurant_seating_check.tscn` kiểm cả chuỗi đến/rời/hủy.

Ảnh camera gameplay: `build/world_composition/restaurant_{spawn,dining,kitchen,counter}.png`,
`seating_close.png`, `sea_0.png`, `sea_2.png`. Scene chụp:
`scenes/art_pilots/world_composition_review.tscn` (dùng `--no-autosave`). Backup:
`build/world_composition/source_before/`.

PASS `world_composition_check` (khung người/ghế/chân, mép phòng, nhường camera,
nav footprint và hai cỡ thuyền), `restaurant_seating_check`, flow quán, traffic,
sea smoke, staging/camera và cast cinematic. Log tại `build/world_composition/`.


### Bàn ăn xoay dọc — 2026-10-30

Toàn bộ bàn ăn xoay 90° quanh Y, trục dài theo Z. Ghế, hướng ngồi/đứng lên và
đường tiếp cận quay cùng cụm bàn; giữ nguyên tâm các bàn và hệ đèn. Collider
mặt bàn đổi footprint sang 1,2 × 1,5; footprint A* cả bàn/ghế sang 1,2 × 2,6.
Nhân viên phục vụ/dọn từ cạnh X dương (offset 1,15), tránh đi vào ghế ở hai đầu.
Preview nâng cấp bàn cũng dùng cùng hướng và scale ghế 0,85.

Cấu hình chung ở `RestaurantLayout3D.TABLE_YAW`, `TABLE_COLLISION_SIZE`,
`TABLE_NAV_SIZE`, `TABLE_SERVICE_OFFSET`, helper `table_offset()`.
Backup: `build/tables_vertical/source_before/`; so hình `before.png`/`after.png`.
PASS flow phục vụ/renovation, traffic/pathing và chuỗi khách ngồi/rời/hủy.


### Quán nhỏ trước tủ, thuê gian bên cạnh và hai khách qua chiều rộng — 2026-10-30

Bốn bàn đầu được gom trước xe/tủ quán, hai cột X=1 / 4,6 và hai hàng Z=0 / 3,6.
Bàn giữ trục dài theo Z; hai ghế đặt ở X ±0,95 để hai khách ngồi đối diện **qua
chiều rộng**, thay vì ngồi hai đầu. Mỗi bàn có hai model khách; cả hai đi từ xe
vào đúng ghế, ngồi/đứng lên và đi ra. Vẫn dùng một order/bill của bàn theo logic
phục vụ hiện có. Điểm phục vụ ở cạnh trước Z+1,25; A* và collider theo footprint mới.

Nâng cấp `seats` nay hiển thị **Mặt bằng**, giữ nguyên ID/save, mức giá 450/1.200
và tiến trình 4 → 6 → 8 bàn. Quán ban đầu có rào thấp chặn gian chưa thuê, phần
sàn đó chưa lát/không đi vào được. Lối đi công cộng phía đường vẫn mở để khách
đậu xe và vào quán. Mỗi lần mua nâng cấp mở thêm gian phía trái (thêm 2 bàn),
dịch ranh giới, mở sàn và cập nhật A*; bàn mới hoạt động ngay sau xác nhận.
Hủy preview không mở đất hay trừ tiền. Preview tô cả diện tích thuê mới và bàn mới.

Dây đèn hiện có được dịch theo cụm bàn; nhân viên về chờ ở lối chuẩn bị bên trái,
bảng thực đơn chuyển ra cạnh lối vào để không chồng ghế. Cấu hình ở
`RestaurantLayout3D`; ranh giới/sàn ở `RestaurantLease3D`. Không đổi mesh GLB.

PASS `restaurant_lease_check`: quyền thuê, hủy/xác nhận, tiền, collider, nav cache,
khả năng phục vụ mới và reload 6/8 bàn; `restaurant_seating_check` kiểm cả đôi khách;
flow quán, traffic, ground motion và camera/khung hình cũng qua. Ảnh 4/6/8 bàn:
`build/leased_layout/level_{0,1,2}.png`. Backup và log trong `build/leased_layout/`
và `build/seats_across_width/`. Mục này thay bố cục ghế ở hai đầu bàn của đợt trước.

Bảng thực đơn ngoài quán nay hiển thị ảnh và tên món đã chọn, cùng món bán kèm
đã mở khóa trong ngày. `WorldMenuBoard3D` dùng lại sprite món của UI, cập nhật qua
`MenuPlan.changed` khi thêm/xóa/hết món; SubViewport chỉ vẽ lại khi thực đơn đổi.
Giữ nguyên GLB bảng và sprite gốc. Đã kiểm tra đồng bộ thêm/xóa món, texture,
flow quán và ảnh camera thật: `build/menu_board/{close,gameplay}.png`.


### Biển 3D tách file, đá ngầm, sương, cảnh ngất — 2026-10-30

`sea_scene_3d.gd` (1112 → ~470 dòng) chỉ còn điều phối; phần dựng cảnh ở
`SeaWorldBuilder3D`, địa điểm/sự kiện đêm ở `SeaPlaces3D`, câu/lưới/khoang ở
`SeaCatch3D`, HUD/chỉ dẫn ở `SeaHud3D`. Scene giữ các hàm cũ (`_try_fish`,
`_visit_poi`...) làm lớp bọc để test/bot không đổi. Thoại biển chuyển xuống góc
dưới trái, tự xuống dòng. Rin ở biển không đội nón.

Cảnh `wave_faint` (và nhánh dự phòng của `fog_omen`): Rin ngất bằng chính model
Rin, clip `Faint` trong `rin_pilot.glb` tạo bởi `tools/art/make_rin_faint.py`
(chạy bằng `/usr/bin/python3`, cần numpy). Clip dựa trên `Death` của pilot2 nhưng
khuỵu gối, ngả ra sau, hông giữ tại chỗ (chân trượt ra trước) để nằm gọn trong
thúng, không bật nhảy; `Faint`, `Death`, `Cast` không loop. Lệnh `tint dawn` của
cutscene 3D đã có hiệu lực. Test: `sea3d_hazards_test` (13), `story3d_stage_test`.
