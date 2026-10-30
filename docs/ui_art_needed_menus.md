# Art cần vẽ cho menu (thay placeholder)

Phong cách chung (tham khảo Dave the Diver + DREDGE): pixel art sắc nét, chỉ
dùng bảng màu "Xóm Đèn" (`assets/palette/xom_den.*`, xem `ART_PLAN.md`), đồ vật
thật của quán vỉa hè ban đêm (bảng phấn, giấy, thùng các-tông, bảng hiệu đỏ +
đèn tuýp). Góc vuông (hoặc bậc 1 px), viền mực 2 px `#090a14`, bevel sáng 1 px
trên/trái, bóng đổ cứng (2,2) không mờ, ít hạt (giấy / phấn / vân gỗ).
Icon: sticker pixel — hình đặc **có màu** + viền mực 1 px (game không tô màu
PNG; chỉ placeholder SVG trắng mới được nướng thành sticker). Nền trong suốt.

Cách thay: thả file PNG đúng tên vào đường dẫn dưới đây, **không cần sửa code**.
`UiIcons.texture(id)` đọc `assets/sprites/ui/icons/<id>.png` nếu có, không thì
dùng placeholder `assets/icons/<id>.svg` (game-icons.net). PNG được vẽ bằng
nearest filter.

## Icon (16x16, hiển thị 1x-2x; nút lớn dùng 16-18 px)

Mỗi icon: 1 file, trạng thái thường. Nút tự làm mờ khi disabled (không cần vẽ
riêng) trừ khi ghi khác.

| File | Size | Dùng ở | Mô tả |
|---|---|---|---|
| assets/sprites/ui/icons/money.png | 16x16 | giá món, tiền Cô Năm, dự thu | 2 đồng xu vàng xếp chồng |
| assets/sprites/ui/icons/clock.png | 16x16 | menu tạm dừng (giờ) | đồng hồ báo thức nhỏ |
| assets/sprites/ui/icons/calendar.png | 16x16 | menu tạm dừng (ngày) | tờ lịch xé, số đỏ |
| assets/sprites/ui/icons/star.png | 16x16 | (dự phòng: đánh giá) | ngôi sao vàng tròn |
| assets/sprites/ui/icons/guest.png | 16x16 | hướng dẫn (nhân viên) | người đứng, áo xanh |
| assets/sprites/ui/icons/people.png | 16x16 | hướng dẫn (nhân viên) | 3 người |
| assets/sprites/ui/icons/fire.png | 16x16 | (dự phòng: nướng) | ngọn lửa cam |
| assets/sprites/ui/icons/beer.png | 16x16 | (dự phòng: bia) | ly bia vàng bọt trắng |
| assets/sprites/ui/icons/fish.png | 16x16 | thực đơn (cá trong kho), hướng dẫn | 2 con cá xanh biển |
| assets/sprites/ui/icons/shrimp.png | 16x16 | hướng dẫn (lưới) | con tôm cam |
| assets/sprites/ui/icons/crab.png | 16x16 | (dự phòng) | con cua đỏ |
| assets/sprites/ui/icons/squid.png | 16x16 | (dự phòng) | con mực |
| assets/sprites/ui/icons/snail.png | 16x16 | (dự phòng) | ốc hương |
| assets/sprites/ui/icons/boat.png | 16x16 | nút "Chơi mới", "Ra khơi", hướng dẫn | thuyền thúng/thuyền nhỏ có đèn |
| assets/sprites/ui/icons/lamp.png | 16x16 | hướng dẫn (dầu đèn) | đèn dầu bão |
| assets/sprites/ui/icons/lantern.png | 16x16 | menu chính (dòng hình) | lồng đèn giấy đỏ-vàng |
| assets/sprites/ui/icons/wrench.png | 16x16 | hướng dẫn (sửa thuyền) | cờ lê |
| assets/sprites/ui/icons/hammer.png | 16x16 | nút "Sửa quán", hướng dẫn | búa + đinh |
| assets/sprites/ui/icons/cart.png | 16x16 | nút "Cô Năm", hướng dẫn | xe đẩy chợ |
| assets/sprites/ui/icons/basket.png | 16x16 | tiêu đề tạp hoá Cô Năm | rổ tre có rau |
| assets/sprites/ui/icons/shop.png | 16x16 | nút "Mở cửa", tab Quán | quán có mái bạt sọc |
| assets/sprites/ui/icons/menu.png | 16x16 | tiêu đề thực đơn, số món | tờ thực đơn có dòng chữ |
| assets/sprites/ui/icons/meal.png | 16x16 | tổng phần, ô trống "chọn món" | đĩa nóng có hơi bốc |
| assets/sprites/ui/icons/settings.png | 16x16 | hướng dẫn (phím chung) | bánh răng |
| assets/sprites/ui/icons/sound_on.png | 16x16 | nút âm thanh (menu chính, tạm dừng) | loa có sóng âm |
| assets/sprites/ui/icons/sound_off.png | 16x16 | nút âm thanh khi tắt | loa gạch chéo đỏ |
| assets/sprites/ui/icons/play.png | 16x16 | nút "Tiếp tục" | tam giác play |
| assets/sprites/ui/icons/pause.png | 16x16 | (dự phòng) | 2 vạch pause |
| assets/sprites/ui/icons/help.png | 16x16 | nút/tiêu đề Hướng dẫn | sổ tay mở |
| assets/sprites/ui/icons/quit.png | 16x16 | nút thoát | cửa mở + mũi tên |
| assets/sprites/ui/icons/house.png | 16x16 | nút về menu chính, hướng dẫn (hết ca) | căn nhà nhỏ |
| assets/sprites/ui/icons/save.png | 16x16 | hướng dẫn (tự lưu) | đĩa mềm |
| assets/sprites/ui/icons/upgrade.png | 16x16 | hướng dẫn (nâng cấp) | mũi tên lên xanh |
| assets/sprites/ui/icons/hot.png | 16x16 | huy hiệu HOT trên thẻ món, chip HOT, picker | trái ớt đỏ (đặt trên đĩa đỏ vẽ bằng code; nếu vẽ thì vẽ luôn đĩa 20x20, xem dưới) |
| assets/sprites/ui/icons/check.png | 16x16 | picker: món đã có trên menu | dấu tích |
| assets/sprites/ui/icons/lock.png | 16x16 | picker: hết hải sản | ổ khoá |
| assets/sprites/ui/icons/trophy.png | 16x16 | (dự phòng: bảng điểm) | cúp vàng |
| assets/sprites/ui/icons/chart.png | 16x16 | hướng dẫn (sổ sách) | biểu đồ cột |
| assets/sprites/ui/icons/phone.png | 16x16 | tab Điện thoại, hướng dẫn | điện thoại có app Rin's Catch |
| assets/sprites/ui/icons/grill.png | 16x16 | hướng dẫn (nướng) | bếp than có vỉ |
| assets/sprites/ui/icons/pot.png | 16x16 | (dự phòng) | nồi |
| assets/sprites/ui/icons/leaf.png | 16x16 | hướng dẫn (rau) | bó rau muống |
| assets/sprites/ui/icons/back.png | 16x16 | picker: quay lại | mũi tên vòng ngược |
| assets/sprites/ui/icons/close.png | 16x16 | nút đóng (thực đơn, Cô Năm, hướng dẫn) | dấu X trong vòng tròn |
| assets/sprites/ui/icons/trash.png | 16x16 | nút "Xóa hết" thực đơn, hướng dẫn | thùng rác xanh |
| assets/sprites/ui/icons/moon.png | 16x16 | menu chính, hướng dẫn | trăng khuyết |
| assets/sprites/ui/icons/keyboard.png | 16x16 | (dự phòng) | bàn phím |
| assets/sprites/ui/icons/mouse.png | 16x16 | (dự phòng) | chuột máy tính |
| assets/sprites/ui/icons/sparkles.png | 16x16 | hệ số giá theo số món, tab Mẹo | 3 ngôi sao lấp lánh |
| assets/sprites/ui/icons/wave.png | 16x16 | tab Nhịp Sóng | ngọn sóng xanh phát sáng |
| assets/sprites/ui/icons/anchor.png | 16x16 | hướng dẫn (bến) | mỏ neo |
| assets/sprites/ui/icons/rod.png | 16x16 | menu chính, hướng dẫn (câu cá) | cần câu cong |
| assets/sprites/ui/icons/sleep.png | 16x16 | (dự phòng) | trăng + "z" |
| assets/sprites/ui/icons/info.png | 16x16 | (dự phòng) | chữ i trong vòng tròn |
| assets/sprites/ui/icons/auto.png | 16x16 | nút "Tự xếp" | xúc xắc / đũa phép |
| assets/sprites/ui/icons/growth.png | 16x16 | (dự phòng: tăng trưởng) | mầm cây / mũi tên lên |

## Khung nine-patch (assets/sprites/ui/frames/)

Placeholder do `tools/ui/ui_frame_painter.gd` vẽ; builder theme
(`tools/ui/build_game_theme.gd`) dùng chúng làm `StyleBoxTexture`. Thay file
cùng tên, **cùng kích thước và margin**, rồi chạy lại builder (xem đầu file
builder). Bóng đổ (2,2) nằm trong ảnh ở mép phải/dưới.

| File | Size | Margin (9-slice) | Material / dùng ở | Mô tả |
|---|---|---|---|---|
| frames/board.png | 48x48 | 8 | Panel mặc định (HUD, tạm dừng) | bảng gỗ sơn tối xám-xanh `#151d28`, bevel `#394a50` |
| frames/paper.png | 48x48 | 8 | `PaperPanel`, `RowPanel`, `CardPanel`, tooltip, ghi chú hướng dẫn, hoá đơn tổng kết | giấy kem `#e7d5b3`, hạt giấy, (tuỳ) mép rách / băng dính |
| frames/strip.png | 48x48 | 8 | `StripPanel` (dải lời thoại cuối màn hình) | dải giấy dài, ít hạt |
| frames/chalk.png | 64x64 | 10 | `ChalkPanel` (lên thực đơn, hướng dẫn) | bảng phấn xanh `#25562e` bụi phấn, khung gỗ `#7a4841` |
| frames/wood.png | 48x48 | 8 | `WoodPanel` (quầy Cô Năm) | tấm ván `#ad7757` vân gỗ `#7a4841` |
| frames/sign.png | 32x32 | 8 | `SignPanel` (bảng hiệu menu chính, tạm dừng) | bảng hiệu đỏ `#e0302b` + viền đèn tuýp `#e6f6ff` |
| frames/cardboard.png | 48x48 | 8 | `CardboardPanel` (ô hàng Cô Năm) | thùng các-tông `#c09473`, nếp gấp |
| frames/phone.png | 32x32 | 10 | `PhoneScreen` (dự phòng cho app điện thoại) | viền điện thoại tối, màn hình `#172038` |
| frames/btn_wood[_hover/_pressed/_disabled].png | 32x32 | 6 | nút mặc định | nút ván gỗ; hover sáng viền vàng; pressed lún 2 px không bóng; disabled xám |
| frames/btn_sign[...4 trạng thái].png | 32x32 | 6 | `SignButton` / `AccentButton` (Mở cửa, Tiếp tục) | nút bảng hiệu đỏ, chữ trắng đèn tuýp |
| frames/btn_paper[...4 trạng thái].png | 32x32 | 6 | `PaperButton` (thẻ giá), `CardFace` (thẻ món), tab đang chọn | giấy / thẻ giá viết tay |
| frames/btn_chalk[_hover].png | 32x32 | 6 | `ChalkButton`, `CardEmpty` (ô món trống) | viền phấn nét đứt (hover: phấn vàng) |
| frames/keycap.png | 12x12 | 4 | `KeyLabel` (phím trong hướng dẫn, số ô) | phím bàn phím xám-xanh |
| frames/stamp.png | 12x12 | 4 | `BadgeLabel` (huy hiệu "3D", tem) | tem mực đỏ `#a53030` |

## Huy hiệu, nền (vẽ bằng code)

| File | Size | Dùng ở | Mô tả | Hiện tại |
|---|---|---|---|---|
| assets/sprites/ui/badge_hot.png | 20x20 | góc thẻ món HOT (nhịp, nghiêng 12°) | sticker ớt trên nền đỏ, viền mực | ô vuông đỏ code + icon `hot` |
| assets/sprites/ui/main_menu_bg.png | 640x360 (hoặc các lớp) | nền menu chính | biển đêm, dây đèn, xóm chài xa, thuyền Rin có đèn | vẽ code `MainMenuBackdrop` (giữ hiệu ứng code: đèn nhấp nháy, sóng, đốm sáng) |
| assets/sprites/ui/logo_xom_den.png | ~240x64 | bảng hiệu menu chính | chữ "XÓM ĐÈN" kiểu bảng hiệu đèn, đủ dấu | Label Paytone One trên `SignPanel` |
| (code) PipBar / MiniChart | — | số phần (chấm vuông), dự thu (cột) | pixel vuông + viền mực | `scenes/ui/pip_bar.gd`, `scenes/ui/mini_chart.gd` |

Ghi chú: `badge_hot`, `main_menu_bg`, `logo_xom_den` cần thêm một dòng code
đọc file khi có art (theo mẫu `Art.draw`); khung thì chỉ cần chạy lại builder.
