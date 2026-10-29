# Xóm Đèn — vòng chơi 3D

Cập nhật 2026-10-28 trên nhánh `try-3d`. Ưu tiên của đợt này là chơi liên tục
**câu cá → về quán → phục vụ → nâng cấp → ra khơi**, dùng dữ liệu thật của game.

## Chạy

Bấm **F5** trong Godot. Menu ghi **XÓM ĐÈN • BẢN 3D**. Chơi mới qua intro rồi
vào biển 3D; Tiếp tục dùng điểm resume trong save hiện tại. Scene mẫu đứng yên
`scenes/art_preview/psx_quan_preview.tscn` vẫn là bản tham khảo art, không phải game.

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
  lớn, giới hạn `max_depth`). Bản đồ điện thoại và ghim dùng tọa độ 2D. Còn lại:
  chưa có đá ngầm ẩn và cổng sương/nghiền lưới như 2D.
- StoryBridge3D chạy cutscene .tres với dàn cảnh 3D (CutsceneStage3D: marker,
  actor đi bộ, camera, emote, mưa, slow, remove); actor rin/bao/vy/co_nam/guest/cat dựng bằng `PersonRig3D` (cùng rig với
  gameplay: đi bộ, cầm đĩa; emote hiện biểu tượng); nhân vật gameplay cùng loại bị
  ẩn trong cảnh và hiện lại khi hết; `tint` chưa có; biển chưa có rig người riêng; marker trong CutsceneMarkers3D, kiểm bằng story3d_stage_test.
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

Mở scene và F6 để xem từng nhóm:

- `scenes/art_pilots/rin_pilot_preview.tscn`: Rin cạnh portrait 2D.
- `scenes/art_pilots/batch_characters_preview.tscn`: 11 người và mèo.
- `scenes/art_preview/restaurant_batch_preview.tscn`: 20 prop quán/đồ nhỏ.
- `scenes/art_preview/batch_sea_review.tscn`: 13 asset biển.

Nhân vật người có skin 20 xương và Idle/Walk/Carry; chưa có rig mặt/ngón
tay. Mèo giữ dáng ngồi từ inference, chỉ bob/sway, chưa có rig đi bốn chân.
Các model dùng palette phẳng, chưa có texture chi tiết; kính/mặt còn đơn giản,
fridge cấp 2 còn mặt trước kín từ geometry nguồn. Bản active trước sửa được
sao lưu recoverable trong `build/batch_integration/backups/`.

Shape Rin baseline còn giữ ở `scenes/art_preview/rin_hunyuan_study.tscn`:
F6, ←/→ xoay, 4 cận, B đổi gốc/3k. Đây là shape chưa có texture/rig.
Mẫu phối màu quán: `scenes/art_preview/psx_quan_preview.tscn`.
Các preview Rin cũ đã archive, không còn là lựa chọn hiện hành.

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
