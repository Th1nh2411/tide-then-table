# Danh sách asset cần vẽ — Rin The Fisher

Hiện mọi thứ trong game là hình vẽ tạm bằng code (`_draw()`). File này liệt kê
những gì cần vẽ để thay dần. Khi có file PNG, game sẽ dùng ảnh; thiếu ảnh nào
thì vẫn vẽ tạm cái đó (code nạp ảnh sẽ làm sau khi bắt đầu có asset).

## Quy ước chung

- **Cỡ chuẩn trong game:** ô 16 px, nhân vật 16x32 (kiểu Stardew), màn hình 640x360, phóng nguyên lần x3.
- **Nếu vẽ ở 32x32 cho dễ chi tiết:** vẽ gấp đôi mọi kích thước bên dưới (ô 32, nhân vật 32x64), game sẽ thu
  nhỏ 0.5. Chọn **một** tỉ lệ cho toàn bộ game, đừng trộn.
- **Định dạng:** PNG nền trong suốt, không khử răng cưa (nearest), sprite sheet theo hàng: mỗi hàng là 1
  hoạt cảnh, mỗi cột là 1 khung hình.
- **Hướng nhìn:** quán là top-down 3/4 (thấy mặt trên + mặt trước); biển là nhìn thẳng từ trên xuống.
- **Thư mục đề xuất:** `assets/sprites/<khu>/<tên>.png` (vd `assets/sprites/restaurant/food_cart.png`).
- **Ban đêm ở biển** màn hình bị phủ màu tối: vật cần thấy rõ (đèn, bọt cá, phao) nên có phần sáng / viền sáng.

Ưu tiên: **P1** = thấy nhiều nhất, làm trước; **P2** = làm sau; **P3** = trang trí, làm cuối.

## 1. Nhân vật (P1)

Kích thước 16x32. Hướng: xuống / lên / trái (phải = lật trái). Đi bộ 4 khung.

| Tên | Hoạt cảnh cần có | Ghi chú |
|---|---|---|
| Rin | đứng, đi bộ (4 hướng), lướt (Shift), cầm đĩa, cầm túi đồ, nướng (đứng sau lò, quay xuống), rót bia | áo xanh dương, phục vụ quán |
| Bảo | đứng sau bếp, đảo chảo (3–4 khung), nói chuyện | áo cam, tạp dề + mũ đầu bếp |
| Vy | đứng, đi bộ (4 hướng), cầm đĩa, dọn bàn | nữ chính, áo hồng, tóc dài; có tạp dề khi làm |
| Cô Năm | đứng sau quầy, vẫy tay | bà bán tạp hoá, áo xanh lá, tóc bạc |
| Khách | đi bộ, ngồi ghế (quay xuống), ăn (gắp đũa 2 khung), tức giận bỏ đi | 3–4 dáng người, đổi màu áo bằng code |
| Khách sang | như khách + cà vạt, áo vàng | |
| Khách quen | như khách, áo xanh rêu | |
| Nhân viên thuê (9 người) | đi bộ, cầm đĩa, dọn bàn | có thể dùng 2–3 dáng người + đổi màu |
| Mèo (Mỡ) | ngồi, đi, nằm ngủ, vẫy đuôi | mèo mập màu cam, ~16x16 |

**Chân dung hộp thoại (P2):** 48x48, mỗi người 2 nét mặt (bình thường / ngạc nhiên): Rin, Bảo, Vy, Cô Năm,
Khách quen, Ông lão (chòi), mèo.

## 2. Quán vỉa hè (P1)

| Tên | Kích thước (px) | Ghi chú |
|---|---|---|
| Ô vỉa hè (gạch) | 16x16 | 2–3 biến thể cho đỡ lặp |
| Mép lề đường (bó vỉa) | 16x16 | |
| Mặt đường + vạch kẻ | 16x16 | đường nhựa, vạch vàng đứt |
| Mặt tiền nhà | 640x80 (5 hàng ô) | cửa cuốn, tường, biển hiệu; vẽ thành vài mảng ghép được |
| Mái hiên sọc | 16x8, lặp ngang | xanh / trắng |
| Xe đẩy + bếp | 64x32 (4 ô) + mặt bàn cao thêm 16 | 3 cấp bếp: lò than / bếp gas / bếp gas đôi; tủ kính, bánh xe |
| Bình bia + vòi | 16x32 | đặt trên đầu phải xe đẩy |
| Lò than nướng | 32x16 | than đỏ, vỉ, xiên nướng; khói 3 khung |
| Bàn kê món (bàn gỗ dài) | 80x16 | 5 ô đặt đĩa |
| Tủ lạnh / thùng đá | 16x32 | 3 cấp: thùng xốp / thùng nhựa xanh / tủ đông |
| Thùng rác | 16x16 | xô nhựa xanh có nắp |
| Bàn ăn inox | 32x32 | có hộp giấy, chai tương ớt, nước mắm |
| Ghế nhựa | 16x16 | xanh dương + đỏ |
| Bàn bẩn | 32x32 lớp phủ | vỏ ốc, đĩa dơ |
| Đĩa món ăn | 16x16 mỗi món | 8 món: ốc hương nướng, mực hấp gừng, cá thu nướng, tôm rang muối, cua rang me, cá mú hấp, rau muống xào, tháp bia |
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
| Bè tôm hùm anh Năm | 36x24 | lồng lưới, cột đèn |
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
