# Art cần vẽ: "Xóm Đèn Review" + bảng xếp hạng (quán 3D)

Code đã sẵn: thả PNG đúng đường dẫn là game dùng ngay, không sửa code (đọc qua
`Art.texture`; thiếu file thì vẽ placeholder trong code).

Hướng hình ảnh: một **app mạng xã hội phẳng trên điện thoại của Rin** (như các app
trong điện thoại của Dave the Diver), không phải hộp kính bo tròn.
- Pixel art, nền trong suốt, viền tối 1-2 px (Xám 1 `#090a14`), không khử răng cưa,
  không gradient, không bóng mờ. Bóng cứng lệch (2,2) màu Xám 1 nếu có.
- Chỉ màu palette "Xóm Đèn": `assets/palette/xom_den.gpl`. Màu chính của app:
  Xanh biển 4 `#4f8fba` (thanh tiêu đề), giấy Đất đá 6 `#e7d5b3` (thẻ bài),
  Đỏ biển hiệu `#e0302b` (Rin / sticker hạng), Vàng nón lá `#f2d98a`.
- Hơi lệch, hơi nghiêng, có vết dùng (vài hạt giấy) — vừa phải. Xem `ART_PLAN.md`.
- Trạng thái mờ / xám do code làm: mỗi file chỉ cần MỘT bản màu đầy đủ.

## Khung nine-patch — 16x16, `res://assets/sprites/ui/frames/<id>.png`

Đã có bản placeholder sinh từ code (`SocialStyle.frame_image`) ở đúng đường dẫn;
vẽ đè file là xong. Lề nine-patch: trái/trên 4 px, phải/dưới 4 px (+2 px bóng nếu
có bóng); `social_notif` lề trái 5 px. Phần giữa được **lát (tile)**, nên vân giấy
ở giữa phải lặp liền.

| File | Kích thước | Dùng ở đâu | Mô tả | Trạng thái |
| --- | --- | --- | --- | --- |
| `assets/sprites/ui/frames/social_card.png` | 16x16 | Thẻ bài đăng trong tab Review, khung biểu đồ ngày | Giấy kem, viền đen 2 px, gờ sáng 1 px trên/trái, bóng cứng (2,2), góc bậc 1 px, vài hạt giấy | 1 |
| `assets/sprites/ui/frames/social_notif.png` | 16x16 | Thông báo bài mới lúc hết ca | Như `social_card` + dải màu app (Xanh biển 4) 3 px bên trái | 1 |
| `assets/sprites/ui/frames/social_header.png` | 16x16 | Thanh tiêu đề app (follower, hạng quán, nút tab) | Xanh biển 4 phẳng, viền đen 2 px, gờ Xanh biển 5, không bóng | 1 |
| `assets/sprites/ui/frames/rank_sticker.png` | 16x16 | Sticker "#3" (nghiêng -7°), sticker "+12 follower" lúc hết ca | Sticker đỏ biển hiệu, gờ Đỏ 3, viền đen, bóng cứng; có thể thêm mép bóc nhẹ một góc | 1 |
| `assets/sprites/ui/frames/avatar_frame.png` | 16x16 | Khung đĩa món trong thẻ bài | Ô vuông trắng Xám 8, viền đen 2 px, không bóng | 1 |
| `assets/sprites/ui/frames/social_tab_on.png` | 16x16 | Nút tab đang chọn (Bài đăng / Xếp hạng) | Nút vàng nón lá, viền đen, bóng cứng | đang chọn |
| `assets/sprites/ui/frames/social_tab_off.png` | 16x16 | Nút tab chưa chọn | Nút Xanh biển 5, viền đen, không bóng (như đã nhấn xuống) | thường |

## Icon — 16x16, `res://assets/sprites/ui/icons/<id>.png` (`GoalIcons.icon`)

| File | Kích thước | Dùng ở đâu | Mô tả |
| --- | --- | --- | --- |
| `assets/sprites/ui/icons/follower.png` | 16x16 | Đầu thanh tiêu đề, sticker "+12" | Bóng người nhỏ + trái tim đỏ bên cạnh (người theo dõi) |
| `assets/sprites/ui/icons/feed.png` | 16x16 | Nút tab "Bài đăng", ô trống "Chưa có bài" | Hai thẻ bài xếp chồng, mỗi thẻ có ô ảnh + dòng chữ |
| `assets/sprites/ui/icons/podium.png` | 16x16 (hiện 12) | Nút tab "Xếp hạng", trên sticker hạng | Bục 3 bậc vàng, bậc giữa cao nhất |
| `assets/sprites/ui/icons/heart.png` | 16x16 (hiện 12 và 8) | Lượt thích trên thẻ, tim bay lúc hết ca | (đã có trong danh sách thử thách) — tim đỏ hồng, chấm sáng |
| `assets/sprites/ui/icons/star.png` | 16x16 (hiện 7) | Hàng sao của bài | (đã có) — phải đọc được ở 7 px |
| `assets/sprites/ui/icons/chili.png` | 16x16 (hiện 8) | Bài về món HOT | (đã có) |
| `assets/sprites/ui/icons/money.png` | 16x16 (hiện 14) | Khung biểu đồ tiền theo ngày | (đã có) |

## Huy hiệu hạng quán — 16x16, `res://assets/sprites/ui/icons/tier_<n>.png`

Mặt tiền quán nhìn thẳng, mỗi hạng "lớn" hơn một chút. Hiện ở thanh tiêu đề (16 px)
và toast lên hạng (24 px, phóng nearest).

| File | Kích thước | Hạng | Mô tả |
| --- | --- | --- | --- |
| `assets/sprites/ui/icons/tier_0.png` | 16x16 | Quán vỉa hè | Ghế nhựa + bàn nhỏ, mái bạt nâu (Đất đá 3) |
| `assets/sprites/ui/icons/tier_1.png` | 16x16 | Quán quen | Mái hiên sọc xanh (Xanh biển 5), một bóng đèn |
| `assets/sprites/ui/icons/tier_2.png` | 16x16 | Quán có tiếng | Mái cam (Nâu cam 4), dây đèn, biển tên nhỏ |
| `assets/sprites/ui/icons/tier_3.png` | 16x16 | Quán nổi tiếng | Biển hiệu đỏ sáng (Đỏ biển hiệu), dây đèn vàng, ngôi sao nhỏ |

## Ảnh đại diện khách — 24x24, `res://assets/sprites/ui/avatars/<id>.png`

Chân dung pixel bán thân trong khung vuông (code tự vẽ viền + bóng, file chỉ là
ảnh trong khung, nên phủ kín 24x24, nền một màu palette). Hiện 22 px (feed) và
18 px (thông báo). Id + tên trong `data/social/review_pool.tres` (thêm người = thêm
id + tên + ảnh).

| File | Kích thước | Tên | Mô tả |
| --- | --- | --- | --- |
| `assets/sprites/ui/avatars/be_na.png` | 24x24 | Bé Na | Bé gái tóc mái, kẹp tóc đỏ, cười |
| `assets/sprites/ui/avatars/tu_map.png` | 24x24 | Tư Mập | Chú mập mặt tròn, áo ba lỗ, khăn vắt vai |
| `assets/sprites/ui/avatars/chi_hai.png` | 24x24 | Chị Hai Ốc | Chị bán ốc, nón vải, áo bà ba |
| `assets/sprites/ui/avatars/kenzie.png` | 24x24 | Kenzie Ăn Đêm | Thanh niên đeo tai nghe, hoodie, cầm điện thoại |
| `assets/sprites/ui/avatars/ut_bong.png` | 24x24 | Út Bông | Cô gái tóc dài buộc nơ, áo vàng |
| `assets/sprites/ui/avatars/ba_xe_om.png` | 24x24 | Ba Xe Ôm | Chú xe ôm, mũ bảo hiểm xanh, áo khoác |
| `assets/sprites/ui/avatars/mimi.png` | 24x24 | Mimi Review | Cô reviewer đeo kính tròn, giơ tay chữ V |
| `assets/sprites/ui/avatars/chu_sau.png` | 24x24 | Chú Sáu Lưới | Ngư dân già, nón lá, da sạm |
| `assets/sprites/ui/avatars/thanh_food.png` | 24x24 | Thành Food | Anh food blogger, mũ lưỡi trai ngược |
| `assets/sprites/ui/avatars/nhoc_ca.png` | 24x24 | Nhóc Cá Khô | Cậu bé gầy, tóc dựng, áo thun rộng |

## Logo quán — 12x12, `res://assets/sprites/ui/rivals/<id>.png`

Biểu đồ xếp hạng vẽ logo 12x12 (code thêm bóng 1 px). Màu thanh lấy từ `color`
trong `data/social/rivals/<id>.tres`, logo nên hợp màu đó.

| File | Kích thước | Quán | Mô tả |
| --- | --- | --- | --- |
| `assets/sprites/ui/rivals/player.png` | 12x12 | Quán Rin (người chơi) | Bếp than nhỏ + ngọn lửa, nền Đỏ biển hiệu |
| `assets/sprites/ui/rivals/tham_lam.png` | 12x12 | Ốc Thâm Lam | Vỏ ốc xoắn xanh đen kiểu logo tập đoàn, lạnh lùng, gọn — nên gợi icon app / phao Thâm Lam (manh mối cốt truyện) |
| `assets/sprites/ui/rivals/ben_gio.png` | 12x12 | Lẩu Bến Gió | Nồi lẩu bốc khói, xám xanh |
| `assets/sprites/ui/rivals/chu_hen.png` | 12x12 | Nướng Chú Hên | Xiên nướng + cỏ bốn lá nhỏ, xám nhạt |

Ảnh món ăn trong bài dùng sẵn `assets/sprites/dishes/<dish_id>.png` (không cần vẽ thêm).
