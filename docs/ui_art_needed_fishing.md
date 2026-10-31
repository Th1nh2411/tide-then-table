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

| File | Size | Mô tả |
|---|---|---|
| sprites/fishing/bg_near_sky.png | 640x360 | trời đêm (dải màu có dither), bờ Xóm Đèn xa có vài ô đèn nhà vàng; trong suốt dưới mặt nước |
| sprites/fishing/bg_near_water.png | 640x360 | nước gần bờ, xanh lam, tối dần theo độ sâu; trong suốt trên mặt nước |
| sprites/fishing/bg_near_bed.png | 640x360 | đáy cát vàng nâu, vài hòn đá, vỏ ốc; trong suốt phía trên |
| sprites/fishing/bg_reef_sky.png | 640x360 | trời đêm, đảo đá nhô lên ở chân trời |
| sprites/fishing/bg_reef_water.png | 640x360 | nước xanh đậm, bóng rạn đá mờ phía xa |
| sprites/fishing/bg_reef_bed.png | 640x360 | rạn đá nâu đỏ, san hô, đáy nhấp nhô cao hơn ở giữa |
| sprites/fishing/bg_open_sky.png | 640x360 | trời đêm trống, chân trời phẳng |
| sprites/fishing/bg_open_water.png | 640x360 | nước sâu xanh đen, gần như đen ở đáy |
| sprites/fishing/bg_open_bed.png | 640x360 | đáy sâu xám tối, rất ít chi tiết |
| sprites/fishing/bg_fog_sky.png | 640x360 | trời bị sương xám phủ, chân trời mờ |
| sprites/fishing/bg_fog_water.png | 640x360 | nước xám lục lạnh |
| sprites/fishing/bg_fog_bed.png | 640x360 | đáy xám, vài khối đá lạ, hơi ánh teal `#5ff2e0` rất ít |

## Thuyền và Rin (vẽ 1x, game phóng 2x)

| File | Size | Mô tả |
|---|---|---|
| sprites/fishing/boat_side.png | 72x24 | ghe gỗ nhìn ngang, mũi và đuôi cong lên, mép boong ở y≈6. Không vẽ cột đèn: code vẽ cột + đèn ở x≈57, nhô lên trên ảnh |
| sprites/fishing/rin_side.png | 48x32 | sheet 3 khung 16x32, nhìn ngang quay phải, đội nón lá, áo xanh: (1) đứng chờ cầm cần, (2) kéo cần, (3) gồng ngả người ra sau. Tay cầm cần ở khoảng (12, 16) trong khung, chân đứng ở mép dưới khung (khung đặt từ x=22 của ảnh thuyền, đáy khung ở y=6 = mặt boong); cần câu do code vẽ |

## Chỉ số

| File | Size | Mô tả |
|---|---|---|
| sprites/fishing/reel.png | 32x32 | cuộn dây câu nhìn chính diện: vành kim loại tối, lòng tối ở giữa (code tô màu cá vào lòng theo tiến độ, vẽ tay quay và vòng độ căng bên ngoài) |
| sprites/fishing/wheel.png | 72x72 | đĩa gỗ khắc tròn có viền mực, vân gỗ; vành trong bán kính ~28 px để code tô lát xanh/vàng/đỏ đè lên |

Bảng gỗ dưới trái dùng khung `ui/frames/wood.png` có sẵn (theme "WoodPanel").

## Kiểm tra

- Đúng kích thước.
- Chỉ dùng màu trong palette.
- Không dùng alpha bán trong suốt (trừ khi cần sương mờ ở `fog`).
- Chạy `tools/run_tests.sh`.
- Xem trong game: F9 (debug) → một đêm bất kỳ → câu ở bọt khí. Đổi vùng câu để xem từng bộ nền.
