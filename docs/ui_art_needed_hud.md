# Art cần vẽ cho HUD (quán 3D, biển 3D, điện thoại, hoá đơn hết ca)

Cùng phong cách với `docs/ui_art_needed_menus.md`: pixel art sắc nét, chỉ bảng
màu "Xóm Đèn" (`assets/palette/xom_den.*`), đồ vật thật (ván gỗ, tờ giấy, phiếu
order, máy tính tiền, con dấu cao su đỏ, điện thoại). Viền mực 2 px `#090a14`,
gờ sáng 1 px trên/trái, bóng đổ cứng (2,2) không mờ, góc vuông hoặc bậc 1 px.
Nền trong suốt. Hiển thị bằng nearest filter.

Cách thay: thả PNG đúng tên/đường dẫn, **không sửa code**. Khung nine-patch
trong `assets/sprites/ui/frames/` đang là placeholder vẽ bằng code
(`tools/ui/ui_frame_painter.gd`): xoá file cũ, thả file mới cùng kích thước +
lề, chạy lại `tools/ui/build_game_theme.gd`. Những thứ vẽ bằng `_draw()` (phiếu
order, máy tính tiền, con dấu...) đọc art qua `Art` nếu có file.

## Khung / chất liệu (nine-patch, theme)

| File | Size (lề) | Dùng ở | Mô tả | Trạng thái |
|---|---|---|---|---|
| assets/sprites/ui/frames/wood.png | 48x48 (8) | Ván gỗ HUD trên-trái (quán: ngày/giờ/tiền; biển: thuyền/giờ/tiền + đồng hồ đo) | Ván gỗ sơn Đất đá 3, vân gỗ ngang Đất đá 2, đinh ở 2 đầu nếu muốn | đã vẽ |
| assets/sprites/ui/frames/tag.png | 24x24 (6) | Thẻ giấy vàng "kết quả ca" dưới ván gỗ (khách, bỏ về, thu, chợ, sao) | Giấy Nâu cam 5, gờ Vàng nón lá, vài hạt Nâu cam 4, có thể thêm mẩu băng keo 1 góc | đã vẽ |
| assets/sprites/ui/frames/receipt.png | 48x48 (8) | Hoá đơn hết ca (`ReceiptPanel`) | Giấy in nhiệt trắng Xám 8, viền mực 1 px hai bên, mép trên + dưới răng cưa (răng 4 px, cao 2 px, ô giữa phải lặp liền), vài hạt Xám 7 | đã vẽ |
| assets/sprites/ui/frames/phone.png | 40x40 (14) | Khung điện thoại (`PhoneScreen`) | Viền máy dày 10 px Xám 2, gờ Xám 5, đường Xám 3 cách mép 3 px; màn hình Xanh biển 1 bắt đầu từ 10 px, viền mực 1 px quanh màn | đã vẽ |
| assets/sprites/ui/frames/paper.png | 48x48 (8) | Ghi chú nhiệm vụ, thẻ thử thách, toast thành tựu, thẻ phím đêm đầu | Giấy kem (đã có) | đã vẽ |
| assets/sprites/ui/frames/strip.png | 48x48 (8) | Dải lời thoại dưới màn hình (quán + biển) | Dải giấy kem (đã có) | đã vẽ |
| assets/sprites/ui/frames/social_card.png | 16x16 | (tuỳ chọn) thẻ bài Review | Chưa có thì dùng `paper.png` | đã vẽ |
| assets/sprites/ui/frames/rank_sticker.png | 16x16 | (tuỳ chọn) sticker hạng / follower | Chưa có thì dùng `stamp.png` | đã vẽ |

## Vẽ bằng code, thay bằng PNG (qua `Art`, kéo giãn vào khung)

| File | Size | Dùng ở | Mô tả | Trạng thái |
|---|---|---|---|---|
| assets/sprites/ui/frames/ticket.png | 28x42 | Phiếu order trên dây (`OrderTicket3D`, vẽ phần giấy; số bàn, hình món, thanh kiên nhẫn, sticker vẽ đè lên) | Phiếu giấy kem Đất đá 6, mép dưới xé răng cưa, bóng cứng, kẹp sắt ở trên do code vẽ | đã vẽ |
| assets/sprites/ui/frames/receipt_register.png | 196x22 | Thân máy tính tiền dưới hoá đơn (`ShiftReceipt3D`) | Hộp sắt Xám 4 viền mực, khe giấy đen dài ngang, 3 phím nhỏ bên trái; chừa chỗ nút ✓ đỏ bên phải (x 158-186) | đã vẽ |
| assets/sprites/ui/stamp_rating.png | 86x40 | Con dấu sao trên hoá đơn (`RatingStamp`); 5 ngôi sao vẫn do code vẽ ở hàng y 22-34 | Khung con dấu cao su đỏ Đỏ 2 (2 viền), chữ "SOLD" Paytone ở trên (chữ trong art dùng tiếng Anh), mực loang lổ vài chấm; để trống hàng sao | đã vẽ |
| assets/sprites/ui/frames/phone_status.png | 26x8 | Thanh trạng thái điện thoại (sóng + pin) | 3 vạch sóng trắng tăng dần + pin trắng, mức pin Xanh ngọc | đã vẽ |
| assets/sprites/ui/frames/meter_<style>.png | 28x6 | (tuỳ chọn) nền đồng hồ đo `MeterBar` (dầu, thân thuyền, khoang, thử thách) — khi đặt `art` | Khe tối viền mực 1 px; phần đổ màu vẫn vẽ bằng code | đã vẽ |
| assets/sprites/ui/neo.png | 16x16 / 22x22 | Hình NEO trong dải lời thoại (đặt trên ô màn tối) | (đã có trong danh sách cũ) | đã vẽ |

Ghim đỏ trên ghi chú nhiệm vụ / thẻ thử thách, dây treo phiếu (dây thép + 2 đinh)
và sticker cúp chéo góc vẫn vẽ bằng code (nhỏ, không cần art).

## Icon mới (16x16, sticker có màu + viền mực 1 px)

`assets/sprites/ui/icons/<id>.png` thay placeholder `assets/icons/<id>.svg`
(game-icons.net, xem `assets/icons/CREDITS.md`). Placeholder trắng được nướng
thành sticker theo màu ở chỗ dùng; PNG thật được vẽ đúng như file.

| File | Dùng ở | Mô tả | Trạng thái |
|---|---|---|---|
| assets/sprites/ui/icons/net.png | Biển: 2 lưới trên ván gỗ (mờ khi lưới đang thả), thẻ phím (Q) | Tấm lưới cá có phao | đã vẽ |
| assets/sprites/ui/icons/oil.png | (dự phòng) dầu đèn | Giọt dầu vàng | đã vẽ |
| assets/sprites/ui/icons/map.png | Tab "Bản đồ" điện thoại, thẻ phím (M) | Bản đồ gấp | đã vẽ |
| assets/sprites/ui/icons/ledger.png | Tab "Sổ sách" | Cuốn sổ có gáy lò xo | đã vẽ |
| assets/sprites/ui/icons/dex.png | Tab "Dex" | Sách bìa có hình cá | đã vẽ |
| assets/sprites/ui/icons/staff.png | Tab "Nhân viên" | Đầu bếp đội mũ | đã vẽ |
| assets/sprites/ui/icons/review.png | Tab "Review" | Bong bóng chat | đã vẽ |
| assets/sprites/ui/icons/podium.png | Hoá đơn: hạng tuần, tab Review | Bục 3 bậc | đã vẽ |
| assets/sprites/ui/icons/leave.png | Thẻ kết quả ca + hoá đơn: khách bỏ về | Người bước đi (đỏ) | đã vẽ |
| assets/sprites/ui/icons/crate.png | Tab "Kho", phím E ở bến (dỡ cá), thẻ phím (Tab) | Thùng gỗ | đã vẽ |
| assets/sprites/ui/icons/hook.png | Phím E ngoài biển (câu), thẻ phím (E) | Lưỡi câu | đã vẽ |
| assets/sprites/ui/icons/wallet.png | Hoá đơn: lương nhân viên | Ví da | đã vẽ |
| assets/sprites/ui/icons/follower.png | Hoá đơn + Review: người theo dõi (thay icon ASCII cũ) | Ngón cái giơ lên | đã vẽ |

Icon có sẵn được dùng thêm ở chỗ mới (không cần vẽ lại, chỉ để biết): calendar,
clock, money, menu / shop / clock / moon (sticker trạng thái ca: lên thực đơn /
đang bán / sắp đóng / đã đóng — đặt trên đĩa màu Vàng nón lá / Đỏ biển hiệu /
Nâu cam 4 / Xanh biển 2), guest, cart, star (sao trên thẻ kết quả), boat, lamp,
wrench, fish, house, sparkles, phone, pause, trophy, upgrade, check, hammer, beer,
fire, meal. Icon thử thách / thành tựu (`GoalIcons`) giờ dùng chung bộ này khi
có cùng id (chili → hot); file `ui/icons/<id>.png` vẫn ưu tiên.
