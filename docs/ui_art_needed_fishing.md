# Art cần vẽ cho màn câu cá (thay hình vẽ tạm bằng code)

Màn câu cần giờ chiếm toàn màn hình 640x360, nhìn ngang mặt cắt biển:

- trời đêm và bờ xa ở trên;
- thuyền của Rin trên mặt nước, đèn thuyền rọi xuống;
- đàn cá bơi trong lòng nước, đáy biển ở dưới;
- bảng gỗ chỉ số ở góc dưới trái, đĩa quay "tất tay" ở góc dưới phải.

Code nằm ở `scenes/fishing/fish_fight_view.gd`, `fish_fight_backdrop.gd` và
`fish_fight_gauges.gd`.

Phong cách chung: xem `docs/UI_ART_BRIEF_CODEX.md`. Pixel art sắc nét, **chỉ dùng
bảng màu "Xóm Đèn"** (`assets/palette/xom_den.hex`), viền mực `#090a14`, đêm tối,
ánh đèn vàng ấm. Chữ trong art (nếu có) là tiếng Anh.

Cách thay: thả PNG đúng tên vào `assets/sprites/<tên>.png`, **không cần sửa code**.
`Art.draw` kéo giãn ảnh vào đúng ô trong game, chưa có file thì code vẽ hình tạm.
Ảnh được vẽ nearest.

Cá dùng lại sprite có sẵn `assets/sprites/fish/<id>.png` (đầu quay sang phải),
thu nhỏ về ~46 px. Không cần vẽ lại cá.

## Nền (mỗi vùng 3 lớp, 640x360, chồng lên nhau)

Vùng: `near` (gần bờ), `reef` (rạn đá), `open` (ngoài khơi), `fog` (vùng sương).

- Mặt nước nằm ở y = 101 (28% chiều cao).
- Đáy biển cao khoảng 16–40 px tính từ mép dưới.
- Code vẫn vẽ đè lên nền: sóng, rong lay, hạt phù du, quầng đèn, sao nhấp nháy, trăng.
  Vì vậy không vẽ trăng và không vẽ quầng đèn vào nền.

| File | Size | Mô tả | Trạng thái |
|---|---|---|---|
| sprites/fishing/bg_near_sky.png | 640x360 | trời đêm (dải màu có dither), bờ Xóm Đèn xa có vài ô đèn nhà vàng; trong suốt dưới mặt nước | đã vẽ |
| sprites/fishing/bg_near_water.png | 640x360 | nước gần bờ, xanh lam, tối dần theo độ sâu; trong suốt trên mặt nước | đã vẽ |
| sprites/fishing/bg_near_bed.png | 640x360 | đáy cát vàng nâu, vài hòn đá, vỏ ốc; trong suốt phía trên | đã vẽ |
| sprites/fishing/bg_reef_sky.png | 640x360 | trời đêm, đảo đá nhô lên ở chân trời | đã vẽ |
| sprites/fishing/bg_reef_water.png | 640x360 | nước xanh đậm, bóng rạn đá mờ phía xa | đã vẽ |
| sprites/fishing/bg_reef_bed.png | 640x360 | rạn đá nâu đỏ, san hô, đáy nhấp nhô cao hơn ở giữa | đã vẽ |
| sprites/fishing/bg_open_sky.png | 640x360 | trời đêm trống, chân trời phẳng | đã vẽ |
| sprites/fishing/bg_open_water.png | 640x360 | nước sâu xanh đen, gần như đen ở đáy | đã vẽ |
| sprites/fishing/bg_open_bed.png | 640x360 | đáy sâu xám tối, rất ít chi tiết | đã vẽ |
| sprites/fishing/bg_fog_sky.png | 640x360 | trời bị sương xám phủ, chân trời mờ | đã vẽ |
| sprites/fishing/bg_fog_water.png | 640x360 | nước xám lục lạnh | đã vẽ |
| sprites/fishing/bg_fog_bed.png | 640x360 | đáy xám, vài khối đá lạ, hơi ánh teal `#5ff2e0` rất ít | đã vẽ |

## Thuyền và Rin (vẽ ĐÚNG CỠ HIỂN THỊ, 1 pixel art = 1 pixel màn hình)

Nền vẽ ở 1x (640x360), nên thuyền và Rin cũng vẽ ở cỡ hiển thị thật, cùng độ mịn
pixel với nền.
- Đợt 1 đã vẽ ở nửa cỡ rồi game phóng 2x, nên pixel to gấp đôi nền và trông mờ, vỡ; lần này không phóng nữa.
- Game không xoay thuyền và Rin: vẽ thẳng đứng, không cần nghiêng.

Mỗi loại thuyền một file, theo cấp nâng cấp thuyền. Áp cho cả 3 thuyền:
- **Mặt boong (chỗ chân Rin) ở đúng y = 12 trong ảnh.**
  - Ở chỗ Rin đứng, mép mạn hoặc sàn phải chạm y = 12, để chân Rin đặt lên đó.
  - Đợt 1 vẽ mép mạn ở y ≈ 13–14 trên ảnh nửa cỡ, Rin bị lơ lửng: kiểm tra kỹ.
- Phần dưới y = 12 là thân thuyền chìm trong nước. Mặt nước nằm ở mép dưới ảnh trừ khoảng 1/3.
- Không vẽ cột đèn và đèn: code vẽ, ở x = 64 (thúng), x = 114 (ghe chèo), x = 156 (ghe máy).
- Toạ độ "Rin đứng" là tâm chân Rin.
- Ban đêm nhưng thuyền phải đọc rõ:
  - viền mực 1 px quanh hình;
  - mạn thuyền có mảng sáng phía trên (ánh đèn), tối dần xuống nước;
  - ít nhất 3 tông cho thân;
  - không để thân gần trùng màu nước đêm (#172038 / #253a5e).

| File | Size | Mô tả | Trạng thái |
|---|---|---|---|
| sprites/fishing/boat_side_thuyen_thung.png | 80x40 | thuyền thúng tre tròn (đầu game) nhìn ngang, vành tre sáng, nan đan rõ, quét dầu nâu; Rin đứng ở x = 28 | đã vẽ |
| sprites/fishing/boat_side_ghe_cheo.png | 144x48 | ghe gỗ chèo, mũi và đuôi cong lên, ván gỗ có vân, mái chèo gác mạn trái; Rin đứng ở x = 60 | đã vẽ |
| sprites/fishing/boat_side_ghe_may.png | 192x56 | ghe máy dài thân xanh (#3c5e8b / #4f8fba, sáng hơn nước), sọc đỏ, cabin nhỏ trắng có cửa sổ vàng (x ≈ 108–146), máy ở đuôi trái; Rin đứng ở x = 68 | đã vẽ |
| sprites/fishing/rin_side.png | 96x64 | sheet 3 khung 32x64, nhìn ngang quay phải, tóc đen rối, kính đen, áo ba lỗ trắng theo model 3D và portrait Rin (không nón lá): (1) đứng chờ cầm cần, (2) kéo cần, (3) gồng ngả người ra sau. Tay cầm cần ở khoảng (24, 32) trong khung; chân ở giữa mép dưới khung, đứng trên mặt boong; cần câu do code vẽ | đã vẽ |

Bản đợt 1 (bị trả lại) để ở `tmp/fishing_rejected/` để so sánh.

## Chỉ số

| File | Size | Mô tả | Trạng thái |
|---|---|---|---|
| sprites/fishing/reel.png | 32x32 | cuộn dây câu nhìn chính diện: vành kim loại tối, lòng tối ở giữa (code tô màu cá vào lòng theo tiến độ, vẽ tay quay và vòng độ căng bên ngoài) | đã vẽ |
| sprites/fishing/wheel.png | 72x72 | đĩa gỗ khắc tròn có viền mực, vân gỗ; vành trong bán kính ~28 px để code tô lát xanh/vàng/đỏ đè lên | đã vẽ |

Bảng gỗ dưới trái dùng khung `ui/frames/wood.png` có sẵn (theme "WoodPanel").

## Kiểm tra

- Đúng kích thước.
- Chỉ dùng màu trong palette.
- Không dùng alpha bán trong suốt (trừ khi cần sương mờ ở `fog`).
- Chạy `tools/run_tests.sh`.
- Xem trong game: F9 (debug) → một đêm bất kỳ → câu ở bọt khí. Đổi vùng câu để xem từng bộ nền; trong màn câu bấm 1 / 2 / 3 để đổi thuyền.
