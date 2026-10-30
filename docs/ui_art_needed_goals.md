# Art cần vẽ: thử thách ngày + thành tựu (quán 3D)

Code đã sẵn: thả PNG đúng đường dẫn là game dùng ngay, không sửa code
(`GoalIcons.icon(id)` / `GoalIcons.badge(id, icon)` trong `scenes/ui/goal_icons.gd`
đọc qua `Art.texture`; thiếu file thì vẽ placeholder).

Quy ước chung
- Pixel art, nền trong suốt, viền tối 1 px (màu tối nhất của palette), không khử răng cưa.
- Chỉ dùng màu palette "Xóm Đèn": `assets/palette/xom_den.gpl` (38 màu Apollo + 5).
  Hướng hình ảnh xem `ART_PLAN.md`.
- Vẽ đúng kích thước gốc ghi trong bảng; game hiện ở 1x hoặc thu 2x (nearest),
  nên nét phải đọc được ở 8 px với icon 16x16.
- Trạng thái khóa / chưa xong do code làm (tô xám, ẩn, đổi màu thanh tiến độ):
  chỉ cần MỘT bản màu đầy đủ cho mỗi file.

## Icon chung — 16x16, `res://assets/sprites/ui/icons/<id>.png`

| File | Kích thước | Dùng ở đâu | Mô tả |
| --- | --- | --- | --- |
| `assets/sprites/ui/icons/guest.png` | 16x16 | Thẻ thử thách (Phục vụ N bàn), huy hiệu dự phòng | Bán thân một vị khách đội nón lá nhìn thẳng, màu da ấm |
| `assets/sprites/ui/icons/heart.png` | 16x16 | Thẻ thử thách (không ai bỏ về) | Trái tim đỏ hồng, có điểm sáng nhỏ |
| `assets/sprites/ui/icons/fire.png` | 16x16 | Thẻ thử thách (nướng N món) | Ngọn lửa than cam-vàng trên hai thanh than đỏ |
| `assets/sprites/ui/icons/beer.png` | 16x16 | Thẻ thử thách (rót N tháp bia) | Ly bia vàng có quai, bọt trắng trào miệng |
| `assets/sprites/ui/icons/chili.png` | 16x16 | Thẻ thử thách (bán món HOT) | Quả ớt đỏ chéo, cuống xanh — gợi "món đang hot" |
| `assets/sprites/ui/icons/money.png` | 16x16 | Thẻ thử thách (thu ≥ Xk), số thưởng trên toast | Đồng xu vàng / cọc tiền, có ký hiệu khắc đơn giản |
| `assets/sprites/ui/icons/clock.png` | 16x16 | Thẻ thử thách (phục vụ nhanh) | Đồng hồ tròn xanh nhạt, kim chỉ ~3 giờ, có vệt tốc độ bên cạnh |
| `assets/sprites/ui/icons/tip.png` | 16x16 | Thẻ thử thách (nhận tiền boa) | Đồng xu nhỏ rơi vào lòng bàn tay / cái chén, màu xanh lá-vàng |
| `assets/sprites/ui/icons/fish.png` | 16x16 | Huy hiệu dự phòng (bán 8 món khác nhau) | Con cá xanh nhìn ngang, đuôi chẻ |
| `assets/sprites/ui/icons/star.png` | 16x16 | Huy hiệu dự phòng (5 sao), id lạ | Ngôi sao 5 cánh vàng |
| `assets/sprites/ui/icons/check.png` | 16x16 (hiện 8x8) | Dấu xong trên thẻ thử thách | Dấu tick xanh lá dày, đọc rõ khi thu còn 8 px |
| `assets/sprites/ui/icons/lock.png` | 16x16 (hiện 8x8) | Góc huy hiệu chưa mở trong điện thoại | Ổ khóa xám bạc, thân vuông, quai tròn |
| `assets/sprites/ui/icons/trophy.png` | 16x16 (hiện 16 và 32) | Đầu thẻ thử thách, đầu tab Thành tựu, toast | Cúp vàng hai quai, chân đế tối; ở 32 px phóng 2x |

## Huy hiệu thành tựu — 24x24, `res://assets/sprites/ui/badges/<achievement_id>.png`

Hiện ở tab "Thành tựu" (ô 24x24, vàng = đã mở, code tô xám + ổ khóa khi chưa mở)
và trên toast "thành tựu mới" (24x24). Thiếu file thì dùng icon 16x16 ở trên.
Gợi ý chung: huy hiệu tròn/khiên nhỏ, viền vàng đồng, hình chính ở giữa.

| File | Kích thước | Thành tựu | Mô tả |
| --- | --- | --- | --- |
| `assets/sprites/ui/badges/first_guest.png` | 24x24 | Khách đầu tiên | Một vị khách giơ tay chào trước chiếc bàn nhựa đỏ |
| `assets/sprites/ui/badges/guests_100.png` | 24x24 | Quán quen của xóm (100 bàn) | Ba bóng khách chen nhau dưới dây đèn, số "100" nhỏ |
| `assets/sprites/ui/badges/earned_1000.png` | 24x24 | Nghìn đầu tiên (1000k) | Chồng xu vàng cao, vài tờ tiền |
| `assets/sprites/ui/badges/five_star.png` | 24x24 | Năm sao | Năm ngôi sao vàng xếp vòng cung |
| `assets/sprites/ui/badges/grill_20.png` | 24x24 | Tay nướng (20 món) | Vỉ than với con tôm/mực đang cháy xém |
| `assets/sprites/ui/badges/beer_30.png` | 24x24 | Vua rót bia (30 tháp) | Tháp bia có vòi, bọt trào, vương miện nhỏ trên đỉnh |
| `assets/sprites/ui/badges/hot_10.png` | 24x24 | Bắt trend (10 món HOT) | Đĩa món ăn bốc khói, quả ớt đỏ cài bên |
| `assets/sprites/ui/badges/dish_kinds_8.png` | 24x24 | Thực đơn phong phú (8 món) | Bảng thực đơn LED nhỏ với nhiều ô món |
| `assets/sprites/ui/badges/perfect_3.png` | 24x24 | Không ai phải chờ (3 ca) | Trái tim + đồng hồ cát, hoặc ba ngôi sao trên nền tim |
| `assets/sprites/ui/badges/staff_1.png` | 24x24 | Có người phụ (thuê người) | Hai người đứng cạnh nhau, một người cầm khay |
| `assets/sprites/ui/badges/challenges_10.png` | 24x24 | Chăm chỉ (10 thử thách) | Tờ giấy có ba dấu tick xanh, bút chì |

Thêm thành tựu/thử thách mới: đặt `icon` (id ở bảng trên) trong `.tres`; muốn hình
riêng cho thành tựu thì thêm `ui/badges/<id>.png`.
