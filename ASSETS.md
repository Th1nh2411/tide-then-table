# Danh sách asset cần vẽ — Rin The Fisher

> **Portrait framing rule (approved):** Dialogue portraits are framed from the navel/upper abdomen upward to approximately the elbows, matching the existing character portraits. Do not use a chest-up crop; hands and lower torso should not be visible.

> **Cô Năm visual update (approved):** Treat Cô Năm as approximately 40 years old and youthful. Keep the portrait low-detail with a restrained palette close to Rin's style; use a simple tied-back dark/gray hairstyle and green blouse, not the previous elderly/60s interpretation.

> **Restaurant prop perspective:** Use a top-down orthographic farming-sim view, with horizontal/vertical primary edges and no isometric convergence. Static props may use a hard 1–2 px dark-navy contact shadow immediately under their feet/base; do not use soft or long cast shadows.

Game hiện dùng PNG cho nhân vật chính, quán, hải sản, món ăn và thuyền; các nhóm
chưa có ảnh vẫn dùng hình vẽ bằng code (`_draw()`). File này liệt kê cả asset đã
có và backlog. **Code nạp ảnh đã có** (`Art`): bỏ file PNG đúng tên
vào `assets/sprites/` là game dùng ngay, thiếu ảnh nào thì vẫn vẽ tạm cái đó. Xem
mục "Tên file" ở cuối.

## Bảng màu và cách làm (vẽ tay + AI)

- **Bảng màu "Xóm Đèn" — 38 màu**, rút từ Apollo (AdamCYounis, Lospec) + 5 màu riêng. Mỗi hàng là một dải
  sáng → tối: xanh biển 6 · đất/da 6 · nâu cam 5 · đỏ 3 · xanh lá 3 · tím 2 (sương, cá biến dị) · xám xanh 8
  · riêng 5 (đỏ biển hiệu, vàng nón lá, xanh ngọc phát sáng, trắng đèn tuýp, ánh tóc xanh đen `#2c4058`). File: `assets/palette/
  xom_den.gpl` (Aseprite: Palette → Load), `xom_den.hex`, `xom_den.png` (ảnh mẫu màu, đưa cho AI làm tham
  chiếu). Các asset dùng màu trong bảng Xóm Đèn; chân dung 128 đã duyệt giữ nguyên màu riêng.
- **Số màu tối đa mỗi hình:** nhân vật 16x32 → 10, portrait approved 128×128 giữ nguyên màu/alpha của approved, hải sản / món ăn master lớn → 6, cả màn
  biển đêm khoảng 12–16 (học DREDGE: ít màu, chỉ thứ quan trọng mới sáng).
- **Quán** dùng nửa ấm (màu đất, cam, đỏ/xanh ghế nhựa, vàng nón lá); **biển đêm** dùng nửa lạnh, 3–4 màu xanh
  đen làm nền, chỉ đèn (cam) và thứ phát sáng (xanh ngọc) là sáng — giống DREDGE: cái gì quan trọng mới sáng.
- **Xem trước:** chạy game bản debug, bấm **F7** → cả màn hình vẽ lại chỉ bằng bảng màu này (bấm lại để tắt).
- **AI làm nháp, tay làm xong:** AI hợp với chân dung, hải sản, món ăn, đồ đứng yên, nền xa; tự vẽ tay sprite đi
  bộ (animation), ô gạch lặp, và đồ đậm chất Việt (thuyền thúng, xe đẩy inox, biển hiệu chữ Việt).
  Lệnh cho AI: "pixel art, <cỡ>, limited palette, transparent background, no anti-aliasing" + ảnh mẫu màu +
  một hình đã vẽ chuẩn làm tham chiếu; tả nhân vật cố định theo ART_PLAN (Rin: tóc đen rối, kính chữ nhật, áo ba lỗ trắng).
- **Chân dung runtime:** dùng ảnh approved 128×128, hiển thị nearest 2× trong khung thoại 256 theo quy ước mới ở `ART_PLAN.md`. Rin có base/vui, Vy có base; Bảo đã có base, base_open và vui trong runtime.
- **Chân dung tham khảo:** các frame 512 được thu nearest-neighbour về 128×128, lưu duy nhất ở `build/portraits/ref/rin/`, `bao/`, `vy/`. Không dùng các frame tham khảo này trực tiếp trong game.

## Quy ước chung

- **Cỡ chuẩn trong game:** ô 16 px, nhân vật 16x32 (kiểu Stardew), màn hình 640x360, phóng nguyên lần x3.
- **Vẽ ở cỡ gốc:** sprite người 16x32. Portrait runtime giữ ảnh approved 128×128 và hiển thị nearest 2× trong khung thoại 256×256.
- **Định dạng:** PNG nền trong suốt, không khử răng cưa (nearest), sprite sheet theo hàng: mỗi hàng là 1
  hoạt cảnh, mỗi cột là 1 khung hình.
- **Hướng nhìn:** quán là top-down 3/4 (thấy mặt trên + mặt trước); biển là nhìn thẳng từ trên xuống.
- **Thư mục:** `assets/sprites/<khu>/<tên>.png` (vd `assets/sprites/restaurant/food_cart_0.png`), tên đúng
  như bảng "Tên file" ở cuối. Renderer có thể kéo ảnh, nhưng asset mới phải vẽ đúng cỡ gốc để tránh mất nét.
- **Ban đêm ở biển** màn hình bị phủ màu tối: vật cần thấy rõ (đèn, bọt cá, phao) nên có phần sáng / viền sáng.

Ưu tiên: **P1** = thấy nhiều nhất, làm trước; **P2** = làm sau; **P3** = trang trí, làm cuối.

## 1. Nhân vật (P1)

Kích thước 16x32. Hướng: xuống / lên / trái (phải = lật trái). Đi bộ 4 khung.

| Tên | Hoạt cảnh cần có | Ghi chú |
|---|---|---|
| Rin | đứng, đi bộ (4 hướng), lướt (Shift), cầm đĩa, cầm túi đồ, nướng (đứng sau lò, quay xuống), rót bia | tóc đen rối, kính gọng đen, da ngăm, áo ba lỗ trắng, dây chuyền đen (mặt lưỡi câu bạc), khuyên tai, quần short đen |
| Bảo | đứng sau bếp, đảo chảo (3–4 khung), nói chuyện | áo cam, tạp dề kem, tóc đen ngắn có mái, không đội mũ |
| Vy | đứng, đi bộ (4 hướng), cầm đĩa, dọn bàn | nữ chính, tiểu thư: áo hồng pastel, tóc dài uốn + kẹp, giày trắng, găng tay hồng khi dọn; bản "sau": tóc buộc cao, xắn tay áo, dép (xem ART_PLAN.md) |
| Cô Năm | đứng sau quầy, vẫy tay | cô bán tạp hoá khoảng 40 tuổi, vẻ trẻ, áo xanh lá, tóc đen/xám buộc gọn |
| Khách | đi bộ, ngồi ghế (quay xuống), ăn (gắp đũa 2 khung), tức giận bỏ đi | 3–4 dáng người, đổi màu áo bằng code |
| Khách sang | như khách + cà vạt, áo vàng | |
| Khách quen | như khách, áo xanh rêu | |
| Nhân viên thuê (9 người) | đi bộ, cầm đĩa, dọn bàn | có thể dùng 2–3 dáng người + đổi màu |
| Mèo (Mỡ) | ngồi, đi, nằm ngủ, vẫy đuôi | mèo mập màu cam, ~16x16 |

**Chân dung hộp thoại (P2, kiểu Nine Sols):** bán thân 128×128, hiển thị nearest 2× trong khung 256×256 của viewport, góc 3/4 như chân dung Rin, **file luôn quay mặt sang phải**; Rin đứng bên trái,
mọi nhân vật khác đứng bên phải và được game lật tự động → trên màn hình quay sang trái, nhìn về phía Rin. Vai chạm
mép dưới. File `portraits/<id>/base.png`, nét mặt thêm `portraits/<id>/<nét>.png` (trong thoại ghi `Rin (vui): ...`;
thiếu file nét mặt thì dùng ảnh thường). id = tên không dấu: `rin`, `bao`, `vy`, `co_nam`, `ong_tam`,
`khach_quen`, `cat` (mèo). Nét gợi ý: `vui`, `lo`, `ngac_nhien`, `buon`.

## 2. Quán vỉa hè (P1)

| Tên | Kích thước (px) | Ghi chú |
|---|---|---|
| Ô vỉa hè (gạch) | 16x16 | 2–3 biến thể cho đỡ lặp |
| Mép lề đường (bó vỉa) | 16x16 | |
| Mặt đường + vạch kẻ | 16x16 | đường nhựa, vạch vàng đứt |
| Mặt tiền nhà | 640x80 (5 hàng ô) | cửa cuốn, tường, biển hiệu; vẽ thành vài mảng ghép được |
| Mái hiên sọc | 16x8, lặp ngang | xanh / trắng |
| Xe đẩy + bếp | 64x32 (4 ô, gồm mặt bàn cao 1 ô) | 3 cấp bếp: lò than / bếp gas / bếp gas đôi; tủ kính, bánh xe |
| Bình bia + vòi | 16x32 | đặt trên đầu phải xe đẩy |
| Lò than nướng | 32x16 | than đỏ, vỉ, xiên nướng; khói 3 khung |
| Bàn kê món (bàn gỗ dài) | 80x16 | 5 ô đặt đĩa |
| Tủ lạnh / thùng đá | 16x32 | 3 cấp: thùng xốp / thùng nhựa xanh / tủ đông |
| Thùng rác | 16x16 | xô nhựa xanh có nắp |
| Bàn ăn inox | 32x32 | có hộp giấy, chai tương ớt, nước mắm |
| Ghế nhựa | 16x16 | xanh dương + đỏ |
| Bàn bẩn | 32x32 lớp phủ | vỏ ốc, đĩa dơ |
| Đĩa món ăn | 64x64 mỗi món | 18 món (tên ở mục "Tên file"): mỗi hải sản có món luộc, nướng, hấp hoặc xào |
| Tháp bia (cầm tay) | 8x16 | |
| Bảng LED menu | 64x40 | khung + chân; chữ chạy vẽ bằng code |
| Tạp hoá Cô Năm | quầy 96x16, két hàng 16x16 | rau, cà chua, bình bia, bảng "TẠP HOÁ" |
| Túi nilon đồ chợ | 8x8 | Rin xách |
| Dây đèn trang trí | 16x8, lặp | trang trí cấp 1 (sáng ban tối) |
| Chậu cây | 16x16 | trang trí cấp 2 |
| Cây xanh vỉa hè | 32x32 | |
| Xe máy chạy (nhìn ngang) | 32x24 | 5 màu xe; người lái + người ngồi sau vẽ riêng để ghép |
| Xe máy đỗ (nhìn trên) | 16x32 | đầu xe hướng ra đường |

## 3. Biển ban đêm (P2)

Biển hiển thị zoom x2 cho cùng tỉ lệ với quán. Vẽ asset biển theo **cỡ trên màn hình**: 3 thuyền và Rin
đã ghi sẵn cỡ màn hình; các dòng còn lại ghi cỡ trong thế giới game, **vẽ gấp đôi** (vd đám bọt 16x16 → vẽ
32x32). Game đặt tỉ lệ 0.5 nên độ nét pixel khớp với quán.

| Tên | Kích thước (px) | Ghi chú |
|---|---|---|
| Thuyền thúng | 32x32 trên màn hình | góc 3/4 như quán: vẽ 8 hướng (hoặc 1 hướng + code xoay mặt boong); thành thuyền thấy ở phía dưới |
| Ghe chèo | 48x20 trên màn hình | như trên |
| Ghe máy | 60x24 trên màn hình | có vệt nước sau đuôi |
| Rin trên thuyền | 16x32 | đầu trần (không nón lá), đứng / thả câu / kéo lưới |
| Nước biển | ô 16x16 lặp | 3 độ sâu: gần bờ / rạn đá / khơi xa |
| Bờ, bến, nhà Xóm Đèn | theo bản đồ 1920x1280 | cầu tàu, đèn bến |
| Đám bọt cá | 16x16, 3 khung | màu nhạt theo loài cá |
| Bóng cá lớn | 32x16 | dưới nước, mờ |
| Phao lưới | 8x8, 2 khung | có đèn nhỏ |
| Đá ngầm | 16–48 px | chỉ hiện trong vùng đèn |
| Hải đăng Đá Canh Đêm | 32x48 | |
| Miếu Cá Ông | 32x32 | |
| Chòi ông lão (Gò Vỏ Ốc) | 32x32 | |
| Bè tôm hùm anh Út | 36x24 | lồng lưới, cột đèn |
| Xoáy nước phát sáng | 64x64, 4–6 khung | trong sương đông bắc |
| Sương mù | lớp phủ lặp | |
| Sự kiện đêm | 16–32 px | ghe mắc cạn, chai thư, đàn sứa (phát sáng), đàn cá heo |

**Cá (hình trong khoang, P1 cho phần khoang):** mỗi ô khoang 20x20, vẽ hình cá phủ đúng số ô:

| Cá | Số ô khoang |
|---|---|
| Ốc hương | 1x1 |
| Tôm | 2x1 |
| Mực | 2x1 |
| Cá thu | 3x1 |
| Cá thu phát sáng | 3x1 (bản phát sáng của cá thu) |
| Cua | 2x2 |
| Cá mú | 3x2 |

Master hải sản dùng kích thước lớn theo số ô khoang: 1 ô = 80x80; sprite ngang/dọc giữ nền trong suốt và hiển thị bằng nearest-neighbor.

Thêm 1 icon 16x16 mỗi loài cho Dex / thông báo (P2).

## 4. Minigame và giao diện (P2–P3)

| Tên | Ghi chú |
|---|---|
| Phao câu | 8x16, nổi / nhấp / chìm |
| Kim đồng hồ + vùng xanh | thanh minigame câu, nướng |
| Ly tháp bia (minigame rót) | 22x54: thân ly, ống đá giữa, lớp bọt, vòi |
| Khung điện thoại "Rin's Catch" | ~360x300, kiểu app của dân IT |
| Icon HUD | tiền, dầu đèn, lưới, thân thuyền (16x16) |
| Khung bảng nhiệm vụ | 9-slice, viền vàng |
| Mũi tên hướng dẫn + vòng sáng | 16x16, 2–3 khung nhún |
| Bong bóng cảm xúc | 12x10: ! ? ... tim, nốt nhạc |
| Phiếu order | 30x18 |
| Nút bấm | 9-slice cho nút thường / nút xanh (mua sỉ) |

## 5. Cảnh riêng (P3)

| Tên | Kích thước | Ghi chú |
|---|---|---|
| Phòng trọ của Rin (intro) | 640x360 | giường, bàn laptop, gói mì, cửa sổ thành phố đêm, poster "Rin's Catch" |
| Rin nằm trên giường | 32x16 | cầm điện thoại sáng |
| Màn nghỉ (bình minh) | 640x360 | bến lúc rạng sáng |
| Cảnh kết | 640x360 | xoáy nước, ánh sáng trắng |
| Quầng sáng "thở" trong sương | 80x80, 4 khung | cutscene điềm báo |

## Gợi ý thứ tự làm

1. Rin, Bảo, khách (dáng chung) và đĩa 8 món → nhìn quán đã khác hẳn.
2. Xe đẩy, lò than, bàn ghế, ô vỉa hè, mặt tiền.
3. Cá trong khoang + 3 thuyền.
4. Vy, Cô Năm, mèo, xe máy.
5. Phần còn lại của biển, UI, cảnh riêng.

## Tên file (code tự nạp)

Đặt trong `assets/sprites/`. Có file là game dùng, không có thì vẽ tạm. Mở editor 1 lần để Godot import
(chưa import thì game vẫn đọc được khi chạy thử). Kích thước ghi theo 1x; vẽ 2x thì nhân đôi.

**Nhân vật** (`characters/`), sprite sheet **4 cột**, mỗi khung 16x32, người kín cả khung: đầu 11 dòng, thân 8,
chân 13 (xem ART_PLAN "Tỉ lệ người"), các hàng:
1. đi xuống (cột 1 = đứng yên; đi = cột 2→3→4→3 kiểu ping-pong Stardew: 2 và 4 = bước, tay đánh ngược chân, 3 = đứng,
2 và 4 hạ người 1 px; `tools/walk_frames.py` dựng hàng xuống / lên từ khung đứng yên), 2. đi lên,
3. đi sang trái (cột 2 / 4 = sải chân, 3 = đứng; sang phải = game tự lật),
4. (tuỳ chọn) "đang bận": khách ngồi ăn, Bảo đảo chảo — 4 khung lặp.
→ 1 sheet đủ 4 hàng = 64x128.
Tuỳ chọn `characters/<tên>_idle.png` (64x96, cùng 3 hàng xuống / lên / trái): đứng yên thở + chớp mắt, cột 1 = đứng,
2 = hít vào (thân trên hạ 1 px), 3 / 4 = cột 1 / 2 nhắm mắt; dựng bằng `tools/make_idle.py` từ cột 1 của sheet
(chạy lại sau khi sửa sheet). Không có thì đứng yên dùng cột 1.

| File | Ai |
|---|---|
| `characters/rin.png`, `bao.png`, `vy.png`, `co_nam.png` | nhân vật chính (cũng dùng trong cutscene) |
| `characters/rin_carry.png` | Rin bưng món: 64x96, cùng layout 4 cột × 3 hướng như `rin.png`; món thật vẽ đè bằng code |
| `characters/guest.png` hoặc `guest_1.png`…`guest_4.png` | khách thường (nhiều dáng thì game chọn ngẫu nhiên) |
| `characters/guest_wait.png`, `guest_eat.png` | khách thường ngồi chờ / ngồi ăn; mỗi file 64x32, 4 frame ngang |
| `characters/guest_rich.png`, `guest_regular.png` | khách sang (áo vàng, cà vạt đỏ), khách quen (tóc muối tiêu, áo xanh rêu); mỗi sheet 64x128 |
| `characters/guest_rich_wait.png`, `guest_rich_eat.png`, `guest_regular_wait.png`, `guest_regular_eat.png` | chờ / ăn cho mỗi biến thể, mỗi sheet 64x32, 4 frame |
| `characters/staff.png` | nhân viên thuê (riêng ai thì `characters/<id>.png`: hung, hanh, phat, ngan, co_sau, khoa, ti, lam, quan) |
| `characters/cat.png` | mèo: 8 cột khung 24x24 (chân chạm đáy), hàng 1 = ngồi (vẫy đuôi, chớp mắt), hàng 2 = đi sang phải (cutscene); dựng bằng `tools/make_cat_sheet.py` |
| `characters/crate.png` (20x14), `rin_bed.png` (32x16), `rin_faint.png` (32x10), `glow.png` (320x80 = 4 khung 80x80 ngang) | đồ trong cutscene; glow được phép alpha theo bậc và runtime tint sáng để thấy ban đêm |

**Quán** (`restaurant/`):

| File | Cỡ (1x) | Ghi chú |
|---|---|---|
| `food_cart_0.png`, `_1`, `_2` (hoặc 1 file `food_cart.png`) | 64x32 | xe đẩy theo cấp bếp, gồm cả mặt bàn; bình bia vẽ riêng |
| `beer_tap.png` | 16x32 | bình bia + vòi |
| `grill.png` | 32x16 | lò than; nhiều khung xếp **dọc** = than chập chờn |
| `fridge_0.png`, `_1`, `_2` | 16x32 | thùng xốp / thùng nhựa / tủ đông |
| `bin.png` | 16x16 | |
| `table.png`, `table_dirty.png` | 32x32 | bàn; lớp bàn bẩn vẽ đè lên |
| `stool_0.png`, `stool_1.png` | 16x16 | ghế xanh, đỏ |
| `plate_bench.png` (hoặc `plate_bench_left/mid/right.png`) | 16x16 mỗi ô | bàn kê món |
| `pavement.png` (+ `pavement_2.png`, `_3`) | 16x16 | gạch vỉa hè, biến thể rải ngẫu nhiên |
| `curb.png`, `road.png`, `road_line.png` | 16x16 | lề, đường, đường có vạch |
| `shop_front.png` | 640x80 | cả mặt tiền (gồm tiệm Cô Năm) |
| `menu_board.png` | 64x40 | khung + chân bảng LED; chữ và món vẽ bằng code đè lên |
| `grocery_counter.png`, `grocery_crate.png` | 96x16, 16x16 | quầy và két Cô Năm |
| `plant.png` | 16x16 | chậu cây |
| `string_lights.png` | 16x8 | tile dây đèn nối ngang, lặp theo khu bàn |

**Món** (`dishes/<id>.png`, 64x64 master; hiển thị bằng nearest-neighbor): tom_luoc, tom_nuong, tom_rang_muoi, muc_luoc, muc_nuong, muc_hap_gung,
oc_huong_luoc_sa, oc_huong_nuong_mo_hanh, cua_luoc, cua_hap_bia, cua_rang_me, canh_chua_ca_thu, ca_thu_nuong,
ca_thu_sot_ca, chao_ca_mu, ca_mu_hap_xi_dau, rau_muong_xao_toi, bia_con_meo.

**Hải sản trên vỉ nướng** (`grill/<fish_id>.png`, master 60x32, vẽ lúc **còn sống**; game tự nhuộm vàng → cháy
và lật): ca_thu, tom, muc, oc_huong.

**Cá trong khoang** (`fish/<id>.png`, master mỗi ô 80x80; ô hiển thị 20x20 bằng nearest, vẽ nằm ngang,
**đầu cá quay sang phải**; game tự xoay khi xoay trong khoang): oc_huong 80x80, tom 160x80, muc 160x80,
ca_thu 240x80, ca_thu_phat_sang 240x80, cua 160x160, ca_mu 240x160.

**Biển** (`sea/`): `thuyen_thung.png`, `ghe_cheo.png`, `ghe_may.png` = mặt boong nhìn từ trên, **mũi thuyền
quay sang phải** (game xoay theo hướng lái), cỡ như bảng mục 3; `rin_boat.png` 16x32 trên màn hình.

Chưa nạp ảnh (vẫn vẽ bằng code): xe máy, dây đèn, cây xanh, đường phố xa, nước biển, đá, địa điểm ngoài
biển, sương mù, UI, minigame. Cần cái nào trước thì báo để nối thêm.

## Art 3D — catalog hiện hành, 2026-10-29

Flow đã chọn và checklist: `docs/ART_PIPELINE.md`; hướng hình ảnh: `ART_PLAN.md`.

### Texture biển đêm — 2026-11-02

Asset mới tạo bằng built-in `image_gen`, chưa tích hợp runtime. Prompt, ảnh nguồn
và ghi chú kiểm tra nằm cùng thư mục `assets/textures/sea3d/`.

| Asset | Kích thước / palette | Trạng thái |
|---|---|---|
| `assets/textures/sea3d/night_sky_panorama_v1.png` | 4096×2048 RGB, equirectangular; navy-indigo `#090a14` → `#172038`, trăng pale-teal | Upscale từ ảnh gen; hai mép gần liền mạch, còn sai khác màu nhỏ; chưa review trong sphere Godot |
| `assets/textures/sea3d/distant_islands_night_v1.png` | 4096×512 RGBA, nền trong suốt; silhouette `#1b2233`–`#26324a`, cửa sổ vàng ấm | Dải đảo xa, crop nền trong suốt và upscale giữ tỷ lệ; chưa tích hợp |

Màu hex là mục tiêu prompt; màu ảnh gen có sai lệch. Không thay thế asset active.

### Model hiện hành

| Asset | Nguồn/định dạng | Trạng thái |
|---|---|---|
| `assets/concepts/rin/lowpoly_turnaround_v1.png` | 1672×941, ảnh gen 3 góc; prompt/provenance cùng thư mục | Mẫu Rin được giữ cho flow Hunyuan |
| `assets/models/characters/rin_hunyuan_shape/input_front.png` | 505×941, crop input | Nguồn lần inference đầu |
| `assets/models/characters/rin_hunyuan_shape/rin_hunyuan_shape.glb` | 78,972 tam giác; GLB gốc từ Space Tencent | Source phục vụ pilot Rin |
| `assets/models/characters/rin_hunyuan_shape/rin_hunyuan_3k_lit.glb` | 3,000 tam giác, đã thêm normals; chưa material/rig | Shape baseline (scene study đã xoá) |
| `assets/models/ready/rin/rin_pilot.glb` | Base `rin_pilot2.glb`; 5,349 tam giác; 62 xương; giữ 24 clip gốc; màu/tóc từ Rin trước | Active quán/biển/cutscene |
| Bàn và ghế đẩu pilot | Hunyuan local; bàn 1,200 tam giác, ghế 600; từng vật rời | Active quán |
| Thuyền thúng pilot | Hunyuan shape; 2,400 tam giác, material phẳng | Active biển |
| 45 asset batch (11 nhân vật, 24 đồ lớn/thuyền/công trình, 10 đồ nhỏ) | Nguồn `assets/models/batch/`; thành phẩm `assets/models/ready/<id>/<id>.glb`; tổng 75,622 tam giác | Đã chuẩn hóa/tô màu và tích hợp game |

Những Rin study Blender/base humanoid/mesh tự dựng bằng script đã được chuyển
khỏi catalog và filesystem Godot. Bản lưu có manifest SHA-256 dưới `.art_backups/`,
chi tiết đường dẫn ở `docs/ART_PIPELINE.md`. Không thay sprite/portrait approved.

Các ID thành phẩm (giữ tên chính xác):

| Nhóm tích hợp | ID trong `assets/models/ready/` |
|---|---|
| Nhân vật/cutscene/khách/nhân viên | `bao`, `vy`, `vy_sau`, `co_nam`, `ong_tam`, `guest_1`, `guest_2`, `guest_3`, `guest_rich`, `guest_regular`, `staff`, `cat` |
| Quán/nâng cấp/tạp hóa/giao thông | `food_cart_0`, `food_cart_1`, `food_cart_2`, `charcoal_grill`, `beer_keg`, `plate_bench`, `fridge_0`, `fridge_1`, `fridge_2`, `menu_board`, `grocery_counter`, `motorbike`, `sidewalk_tree`, `bin`, `plant_pot`, `beer_tower`, `grocery_crate`, `plastic_bag`, `crate`, `bottle` |
| Biển/POI/sự kiện/phụ kiện Rin | `ghe_cheo`, `ghe_may`, `lighthouse`, `whale_shrine`, `old_man_hut`, `lobster_raft`, `dock`, `rock_1`, `rock_2`, `dolphin`, `net_buoy`, `jellyfish` |

Mỗi người batch giữ 3,000 tam giác và có skin 20 xương; mèo là mesh ngồi tĩnh
có bob/sway. Các GLB giữ geometry inference, palette phẳng theo concept và có
provenance/checksum. Nguồn batch không bị ghi đè; bản active trước sửa
được lưu recoverable trong `build/batch_integration/backups/`.

Rin cập nhật từ Blender ngày 2026-10-29: giữ màu chỉnh tay, Skin.001 về `#D79C6B`,
Walk sửa trọng số dép và nhịp bước. Nguồn chỉnh tiếp local:
`build/rin_export/rin_walk_fixed.blend`; GLB runtime vẫn ở đường dẫn pilot trên.

Rin có thêm clip `Cast` 1,5 giây; preview phím 5 và cinematic dùng clip này.
Các nhân vật batch khác giữ Idle/Walk/Carry. Nguồn có Cast: `rin.blend` ở đường
dẫn Blender nêu trên; snapshot local `build/rin_cast/source_with_cast.blend`.

Rin hiện dùng **thân, mặt, rig và Walk gốc của `rin_pilot2.glb`** theo lựa chọn
người dùng; GLB nguồn giữ nguyên. Chỉ thay material và ghép 275 tam giác tóc từ
bản Rin trước. Có thêm Carry/Cast tương thích gameplay, không thay Walk gốc.
Nguồn chỉnh tiếp: `build/rin2_finish/rin_pilot2_finished.blend`.

Base 2 hiện được sửa GLB trực tiếp: giữ binary/normals/rig/24 clip gốc và thông số
material, chỉ đổi Base Color, thay tóc và thêm kính. Tổng 5.349 tam giác/6 mesh.
Scene đối chiếu: `scenes/art_pilots/rin_pilot2_compare.tscn`.

### Palette/mắt model ngoài Rin — 2026-10-29

11 người batch và mèo đã được sửa màu và mắt. Profile nguồn chính xác nằm ở
`tools/art/refine_character_faces.py`: Bảo cam/kem, Vy hồng theo portrait, Cô Năm
xanh olive/tóc tối, Ông Tám áo nâu đỏ/tóc bạc xanh, khách quen xanh/tóc muối tiêu;
những khách còn lại theo concept. Mèo Mỡ giữ cam/kem theo art plan.

Các GLB runtime vẫn ở `assets/models/ready/<id>/<id>.glb`. Giữ 3.000 tam giác
thân và skin 20 xương cho người; mắt đen theo Rin + chân mày thêm 40 tam giác,
kính thêm 36 cho `guest_3`, `guest_rich`, `staff`; mèo thêm 64 tam giác mắt.
Tổng 45 model batch hiện là 76.218 tam giác. Raw/reduced nguồn và toàn bộ Rin không đổi.
Scene review: `scenes/art_pilots/character_faces_review.tscn`.

Walk 11 người batch đã thu hẹp đường cổ chân (rig chuẩn: 0,386 → 0,240 m),
giữ mesh/màu/mắt và các clip khác. Rin/mèo không đổi. Xem phím 4/5 trong scene
`character_faces_review.tscn`; tool `tools/art/narrow_character_walk.py`.

Cả 11 người dùng mắt đen từ primitive Eye của Rin, fit từng bên lên mặt thật;
FaceDetails 40 tam giác, hoặc 76 khi có kính. `bao`/`vy` giữ nguyên bản tóc và
mảng màu thân người dùng tô thủ công. Chín người còn lại sửa ranh giới material
tóc theo hai mẫu đó, giữ silhouette và màu tóc riêng. Không sửa Rin/mèo.
Tool: `tools/art/match_character_eyes_to_rin.py`, `tools/art/follow_manual_hair.py`.
Backup trước đợt này: `build/character_style_follow/source_before/`.


Cô Năm sau export thủ công được thêm lại riêng 24 tam giác mắt Rin (không thêm
lại chân mày đã xóa): `assets/models/ready/co_nam/co_nam.glb`, tổng 3.024.
Body/tóc/palette/rig/clip người dùng giữ nguyên. Bản Blender có mắt và backup ở
`build/co_nam_eye_restore/`; mắt cũng đã được thêm vào scene Blender đang mở.


## Horror art — 2026-11-02

Theo `docs/HORROR_ART_BRIEF.md`: đã tạo 22 PNG và sidecar prompt/provenance bằng
built-in `image_gen`, chưa tích hợp và chưa approved. Danh sách chi tiết, ảnh review
và giới hạn đường nối: `docs/HORROR_ART_DELIVERY.md`.

| Thư mục | Asset ID | Kích thước |
|---|---|---|
| `assets/textures/horror/` | `wall_plaster_old`, `floor_wood_planks`, `ground_village`, `roof_tin_rusty` | 512×512 RGB; tile-intended, cần review mép |
| `assets/textures/horror/` | `door_wood_old` | 512×1024 RGB |
| `assets/textures/horror/` | `calendar_sheet` | 512×640 RGB, vùng chữ trống |
| `assets/textures/horror/` | `newspaper_front`, `notebook_page` | 1024×1400 RGB |
| `assets/textures/horror/` | `paper_letter_old` | 1024×1024 RGBA |
| `assets/textures/horror/` | `paper_diary_page` | 1024×1400 RGBA |
| `assets/textures/sea3d/` | `sky_dawn_overcast`, `sky_dark_night` | 4096×2048 RGB, upscale, cần review sphere |
| `assets/concepts/horror/` | `offering_tray_normal`, `offering_tray_eaten`, `joss_paper_bucket`, `hoa_dang_lantern`, `pier_lamp_post`, `drowned_figure`, `drowned_hand`, `bottle_letter`, `rin_house`, `wooden_bed` | 1024×1024 RGB, nền xám nhạt, input concept cho Hunyuan |

Palette theo horror brief: vôi vàng/xanh bạc màu, rỉ sét, gỗ ướt tối,
biển xám xanh, điểm sáng hổ phách. Không ép palette sprite cũ.

Ghế `ready/stool/stool.glb` giữ nguyên nguồn; runtime quán scale 0,85 cả mesh và
collider (cao 0,442; footprint 0,4675 × 0,4675). Đây là điều chỉnh tương quan
người/ghế, không đổi scale nhân vật/bàn/người trên thuyền. Shadow caster được
bật lúc load qua `WorldPresentation3D`; đèn quán/SSAO không thay màu material gốc.

## Horror art — brief 2, 2026-11-02

Theo `docs/HORROR_CODEX_BRIEF_2.md`: 17 PNG mới, mỗi ảnh có sidecar `.md`
ghi prompt thực tế, built-in `image_gen`, ngày, nguồn, hậu kỳ và SHA-256.
Chưa approved, chưa tích hợp runtime. Danh sách và ảnh review:
`docs/HORROR_CODEX_DELIVERY_2.md`. Bản nháp chữ: `docs/HORROR_TEXTS_DRAFT.md`.

| Thư mục | Asset ID | Kích thước / nền |
|---|---|---|
| `assets/concepts/horror/` | `fish_ca_thu`, `fish_ca_mu`, `fish_muc`, `fish_cua`, `fish_tom`, `fish_oc_huong`, `fish_glowing` | 1024×1024 RGB, xám nhạt opaque; tôm 2 con, ốc 3 con |
| `assets/concepts/horror/` | `fish_basket`, `fishing_rod`, `fishing_bobber` | 1024×1024 RGB, xám nhạt opaque |
| `assets/concepts/horror/` | `anh_ut`, `ghost_ong_tu`, `villager_chu_hai` | 1024×1024 RGB, toàn thân, xám nhạt opaque |
| `assets/textures/horror/` | `title_keyart`, `ending_true`, `ending_drowned` | 1920×1080 RGB, opaque |
| `assets/textures/horror/` | `notebook_cover` | 1024×1400 RGB, opaque, nhãn trống |

Giữ phong cách PS1 horror/palette theo brief, không ép palette sprite cũ.
Concept là ảnh đầu vào cho image-to-3D; chưa tạo hay thay model GLB.

## Horror art — brief 3, 2026-11-02

Theo `docs/HORROR_CODEX_BRIEF_3.md`: 13 concept PNG và 4 texture PNG,
mỗi ảnh có sidecar `.md` ghi prompt, built-in `image_gen`, ngày, nguồn,
hậu kỳ và SHA-256. Chờ review, chưa tích hợp game.
Danh sách, ảnh review và kiểm tra texture lặp: `docs/HORROR_CODEX_DELIVERY_3.md`.

| Thư mục | Asset ID | Kích thước / nền |
|---|---|---|
| `assets/concepts/horror/` | `bamboo_fence`, `power_pole`, `banana_clump`, `roadside_shrine`, `water_jar`, `fishing_nets_drying`, `neighbour_house_a`, `neighbour_house_b`, `stone_steps` | 1024×1024 RGB, vật thể trọn khung, nền xám nhạt opaque |
| `assets/concepts/horror/` | `altar_ong_tu`, `hat_hook`, `wooden_wardrobe`, `low_table_tea` | 1024×1024 RGB, nền xám nhạt opaque |
| `assets/textures/horror/` | `lane_dirt`, `brick_wall_old`, `tiles_cement_floor`, `blue_lime_wall` | 512×512 RGB, texture lặp, xem ảnh review 2×2 |

Palette và phong cách theo horror brief; không thay asset approved/active.
Chưa tạo model Hunyuan hay sửa scene, script, material hoặc resource runtime.


## Horror models — tích hợp 2026-11-03

25 concept trong `docs/LOCAL_HUNYUAN_TONIGHT.md` đã có raw/reduced GLB,
provenance và license trong `assets/models/ready/<id>/`. Game dùng
`<id>_reduced.glb`, tổng **68.998 tam giác**; ngân sách nhỏ 2.000, vừa 3.000,
nhà 5.000 (bậc đá thực tế 2.998). Không dựng ba NPC concept vì đã dùng PSX rig.

| Nhóm | ID model runtime |
|---|---|
| Cá / đồ câu | `fish_ca_thu`, `fish_ca_mu`, `fish_muc`, `fish_cua`, `fish_tom`, `fish_oc_huong`, `fish_glowing`, `fish_basket`, `fishing_rod`, `fishing_bobber` |
| Phòng / cửa nhà | `hat_hook`, `water_jar`, `low_table_tea`, `altar_ong_tu`, `wooden_bed`, `wooden_wardrobe` |
| Hẻm / bến / cảnh kết | `bamboo_fence`, `banana_clump`, `power_pole`, `roadside_shrine`, `fishing_nets_drying`, `stone_steps`, `rin_house`, `neighbour_house_a`, `neighbour_house_b` |

Bản reduced được thêm normals (không đổi vertices/index); source/derivative SHA-256
ghi trong provenance. Tô màu runtime bằng concept projection có nhận ánh sáng; mặt bên/mái nhà và tủ
dùng texture lặp. Chưa phải UV/PBR bake riêng. Metadata: `horror_models.json` +
`horror_models.gd` (preload trong bản export). Props tĩnh không cần rig.

Ảnh render 3 góc, ảnh gameplay, kiểm thử và giới hạn: `docs/HORROR_MODEL_INTEGRATION.md`.
Backup trước thay: `.art_backups/horror_integration_20261103/manifest.json`.
Ảnh concept/sprite/portrait approved không đổi; GLB inference gốc giữ nguyên.
