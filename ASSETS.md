# Danh sách asset cần vẽ — Rin The Fisher

> **Portrait framing rule (approved):** Dialogue portraits are framed from the navel/upper abdomen upward to approximately the elbows, matching the existing character portraits. Do not use a chest-up crop; hands and lower torso should not be visible.

> **Cô Năm visual update (approved):** Treat Cô Năm as approximately 40 years old and youthful. Keep the portrait low-detail with a restrained palette close to Rin's style; use a simple tied-back dark/gray hairstyle and green blouse, not the previous elderly/60s interpretation.

Hiện mọi thứ trong game là hình vẽ tạm bằng code (`_draw()`). File này liệt kê
những gì cần vẽ để thay dần. **Code nạp ảnh đã có** (`Art`): bỏ file PNG đúng tên
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
  bộ (animation), ô gạch lặp, và đồ đậm chất Việt (nón lá, thuyền thúng, xe đẩy inox, biển hiệu chữ Việt).
  Lệnh cho AI: "pixel art, <cỡ>, limited palette, transparent background, no anti-aliasing" + ảnh mẫu màu +
  một hình đã vẽ chuẩn làm tham chiếu; tả nhân vật cố định theo ART_PLAN (Rin: tóc đen rối, kính chữ nhật, áo ba lỗ trắng).
- **Chân dung runtime:** dùng ảnh approved 128×128 trong `build/portraits/128/approved/`, hiển thị 1:1 trong khung thoại 128. Rin approved gồm base và vui; Vy approved gồm base; Bảo chờ approved riêng.
- **Chân dung tham khảo:** các frame 512 được thu nearest-neighbour về 128×128, lưu duy nhất ở `build/portraits/ref/rin/`, `bao/`, `vy/`. Không dùng các frame tham khảo này trực tiếp trong game.

## Quy ước chung

- **Cỡ chuẩn trong game:** ô 16 px, nhân vật 16x32 (kiểu Stardew), màn hình 640x360, phóng nguyên lần x3.
- **Vẽ ở cỡ gốc:** sprite người 16x32. Portrait runtime giữ ảnh approved 128×128 và hiển thị trong khung thoại 128×128 bằng filtering riêng.
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

**Chân dung hộp thoại (P2, kiểu Nine Sols):** bán thân 128×128, hiển thị 1:1 trong khung 128×128 của viewport, filtering riêng cho portrait, góc 3/4 như chân dung Rin, **file luôn quay mặt sang phải**; Rin đứng bên trái,
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
| Rin trên thuyền | 16x32 | đội nón lá, đứng / thả câu / kéo lưới |
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
| `characters/guest.png` hoặc `guest_1.png`…`guest_4.png` | khách thường (nhiều dáng thì game chọn ngẫu nhiên) |
| `characters/guest_rich.png`, `guest_regular.png` | khách sang, khách quen |
| `characters/staff.png` | nhân viên thuê (riêng ai thì `characters/<id>.png`: hung, hanh, phat, ngan, co_sau, khoa, ti, lam, quan) |
| `characters/cat.png` | mèo: 8 cột khung 24x24 (chân chạm đáy), hàng 1 = ngồi (vẫy đuôi, chớp mắt), hàng 2 = đi sang phải (cutscene); dựng bằng `tools/make_cat_sheet.py` |
| `characters/crate.png` (20x14), `rin_bed.png` (32x16), `glow.png` (80x80, 4 khung ngang) | đồ trong cutscene |

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

**Món** (`dishes/<id>.png`, 64x64 master; hiển thị bằng nearest-neighbor): tom_luoc, tom_nuong, tom_rang_muoi, muc_luoc, muc_nuong, muc_hap_gung,
oc_huong_luoc_sa, oc_huong_nuong_mo_hanh, cua_luoc, cua_hap_bia, cua_rang_me, canh_chua_ca_thu, ca_thu_nuong,
ca_thu_sot_ca, chao_ca_mu, ca_mu_hap_xi_dau, rau_muong_xao_toi, bia_con_meo.

**Hải sản trên vỉ nướng** (`grill/<fish_id>.png`, khoảng 60x32, vẽ lúc **còn sống**; game tự nhuộm vàng → cháy
và lật): ca_thu, tom, muc, oc_huong.

**Cá trong khoang** (`fish/<id>.png`, mỗi ô 20x20, vẽ nằm ngang, **đầu cá quay sang phải**; game tự xoay khi
xoay trong khoang): oc_huong 20x20, tom 40x20, muc 40x20, ca_thu 60x20, ca_thu_phat_sang 60x20, cua 40x40,
ca_mu 60x40.

**Biển** (`sea/`): `thuyen_thung.png`, `ghe_cheo.png`, `ghe_may.png` = mặt boong nhìn từ trên, **mũi thuyền
quay sang phải** (game xoay theo hướng lái), cỡ như bảng mục 3; `rin_boat.png` 16x32 trên màn hình.

Chưa nạp ảnh (vẫn vẽ bằng code): xe máy, dây đèn, cây xanh, đường phố xa, nước biển, đá, địa điểm ngoài
biển, sương mù, UI, minigame. Cần cái nào trước thì báo để nối thêm.
